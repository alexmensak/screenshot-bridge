import AppKit
import BridgeCore
import ServiceManagement
import os

@main
struct ScreenshotBridgeApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let logger = Logger(subsystem: "local.screenshotbridge.app", category: "bridge")
    private let preferences = UserDefaults.standard
    private let bridge = ClipboardBridge(pasteboard: .general,
        saveDirectory: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures/Screenshot Bridge"))
    private lazy var watcher = ScreenshotWatcher(bridge: bridge)
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var paused = false
    private var status = "Ready for screenshots"
    private var lastFolderRefresh = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: "local.screenshotbridge.app").count <= 1 else {
            NSApp.terminate(nil)
            return
        }
        preferences.register(defaults: ["quoteForTerminal": true, "handleClipboardImages": true])
        bridge.quoteForTerminal = preferences.bool(forKey: "quoteForTerminal")
        watcher.onCopied = { [weak self] _ in self?.copied() }
        watcher.onError = { [weak self] message in self?.report(message) }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        item.button?.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot Bridge")
        item.button?.toolTip = "Screenshot Bridge — image and path on your clipboard"
        rebuildMenu()
        refreshFolder()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer?.tolerance = 0.04
        if !preferences.bool(forKey: "didShowWelcome") {
            preferences.set(true, forKey: "didShowWelcome")
            showHelp()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        watcher.pause()
    }

    func menuWillOpen(_ menu: NSMenu) { rebuildMenu(menu) }

    private func tick() {
        guard !paused else { return }
        if preferences.bool(forKey: "handleClipboardImages") {
            if #available(macOS 15.4, *), bridge.pasteboard.accessBehavior == .alwaysDeny {
                status = "Clipboard access blocked — see Help"
                bridge.skipCurrentClipboard()
            } else {
                do { if try bridge.processClipboardIfChanged() != nil { copied() } }
                catch { report(error.localizedDescription) }
            }
        } else { bridge.skipCurrentClipboard() }
        watcher.tick()
        if Date().timeIntervalSince(lastFolderRefresh) > 5 { refreshFolder() }
    }

    private func refreshFolder() {
        lastFolderRefresh = Date()
        let configured: String?
        if let override = preferences.string(forKey: "screenshotFolder") { configured = override }
        else {
            CFPreferencesAppSynchronize("com.apple.screencapture" as CFString)
            configured = CFPreferencesCopyAppValue("location" as CFString, "com.apple.screencapture" as CFString) as? String
        }
        let path = (configured ?? "~/Desktop") as NSString
        watcher.watch(URL(fileURLWithPath: path.expandingTildeInPath, isDirectory: true))
    }

    private func copied() {
        status = "Screenshot ready — image + path"
        statusItem?.button?.toolTip = "Screenshot ready: \(bridge.lastFile?.lastPathComponent ?? "")"
    }

    private func report(_ message: String) {
        if status != message { logger.error("\(message, privacy: .private)") }
        status = message
    }

    private func rebuildMenu(_ existing: NSMenu? = nil) {
        let menu = existing ?? NSMenu()
        menu.removeAllItems()
        menu.autoenablesItems = false
        menu.delegate = self
        let title = NSMenuItem(title: "Screenshot Bridge", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        let state = NSMenuItem(title: paused ? "Paused" : status, action: nil, keyEquivalent: "")
        state.isEnabled = false
        menu.addItem(state)
        menu.addItem(.separator())
        add("Pause", #selector(togglePause), to: menu, checked: paused)
        add("Launch at Login", #selector(toggleLogin), to: menu, checked: SMAppService.mainApp.status == .enabled)
        if SMAppService.mainApp.status == .requiresApproval {
            add("Allow in Login Items…", #selector(openLoginSettings), to: menu)
        }
        add("Handle Clipboard Images", #selector(toggleClipboardImages), to: menu,
            checked: preferences.bool(forKey: "handleClipboardImages"))
        add("Quote Paths for Terminals", #selector(toggleQuoting), to: menu,
            checked: bridge.quoteForTerminal)
        menu.addItem(.separator())
        add("Copy Last Path Only", #selector(copyPath), to: menu, enabled: bridge.lastFile != nil)
        add("Reveal Last Screenshot", #selector(revealLast), to: menu, enabled: bridge.lastFile != nil)
        add("Open Clipboard Screenshot Folder", #selector(openSaveFolder), to: menu)
        if let folder = watcher.directory {
            let label = NSMenuItem(title: "Watching: \(folder.path)", action: nil, keyEquivalent: "")
            label.isEnabled = false
            menu.addItem(label)
        }
        add("Choose Screenshot Folder…", #selector(chooseFolder), to: menu)
        add("Use macOS Screenshot Folder", #selector(useSystemFolder), to: menu)
        menu.addItem(.separator())
        add("Help…", #selector(showHelp), to: menu)
        add("Quit Screenshot Bridge", #selector(quit), to: menu)
        statusItem?.menu = menu
    }

    private func add(_ title: String, _ action: Selector, to menu: NSMenu,
                     checked: Bool? = nil, enabled: Bool = true) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        if let checked { item.state = checked ? .on : .off }
        menu.addItem(item)
    }

    @objc private func togglePause() {
        paused.toggle()
        bridge.skipCurrentClipboard()
        if paused { watcher.pause() } else { status = "Ready for screenshots"; refreshFolder() }
    }

    private func enableLogin() {
        do {
            try SMAppService.mainApp.register()
            if SMAppService.mainApp.status == .requiresApproval { status = "Allow launch in Login Items" }
        } catch { report("Launch at Login could not be enabled. Toggle it again from the menu.") }
    }

    @objc private func toggleLogin() {
        if SMAppService.mainApp.status == .enabled {
            do { try SMAppService.mainApp.unregister() }
            catch { report(error.localizedDescription) }
        } else { enableLogin() }
    }

    @objc private func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    @objc private func toggleClipboardImages() {
        preferences.set(!preferences.bool(forKey: "handleClipboardImages"), forKey: "handleClipboardImages")
        bridge.skipCurrentClipboard()
    }

    @objc private func toggleQuoting() {
        bridge.quoteForTerminal.toggle()
        preferences.set(bridge.quoteForTerminal, forKey: "quoteForTerminal")
    }

    @objc private func copyPath() {
        do { try bridge.copyLastPathOnly() }
        catch { report(error.localizedDescription) }
    }

    @objc private func revealLast() {
        if let file = bridge.lastFile { NSWorkspace.shared.activateFileViewerSelecting([file]) }
    }

    @objc private func openSaveFolder() {
        do {
            try PrivateImageStore.prepareDirectory(bridge.saveDirectory)
            NSWorkspace.shared.open(bridge.saveDirectory)
        } catch { report(error.localizedDescription) }
    }

    @objc private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose the folder where macOS saves screenshots"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let folder = panel.url {
            preferences.set(folder.path, forKey: "screenshotFolder")
            if !paused { refreshFolder() }
        }
    }

    @objc private func useSystemFolder() {
        preferences.removeObject(forKey: "screenshotFolder")
        if !paused { refreshFolder() }
    }

    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "Screenshots that paste anywhere"
        alert.informativeText = "Take screenshots using your usual shortcuts. After the image is saved or copied, Screenshot Bridge puts the image, a file reference, and its path on the clipboard. Image fields can paste the picture; text fields can paste the path.\n\nIn PyCharm’s terminal, use ⌘V for the path. Claude Code also has its own ⌃V image-paste shortcut. The receiving app decides which format to use.\n\nAllow clipboard access when macOS asks. For continuous use, set System Settings → Privacy & Security → Paste from Other Apps → Screenshot Bridge to Always Allow. Allow Downloads/Desktop access if prompted. No Accessibility or Screen Recording permission is needed.\n\nClipboard-only images are saved in ~/Pictures/Screenshot Bridge and kept until you delete them. The clipboard does not identify screenshot-only images, so other copied images are also handled. Turn off Handle Clipboard Images to watch saved screenshots only.\n\nIf a field chooses the wrong format, use Copy Last Path Only in the menu. If saved screenshots feel slow, turn off Show Floating Thumbnail in ⌘⇧5 → Options."
        alert.addButton(withTitle: "Got it")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
