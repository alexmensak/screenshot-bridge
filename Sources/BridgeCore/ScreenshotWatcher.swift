import AppKit
import Darwin

@MainActor
public final class ScreenshotWatcher {
    struct Pending {
        let firstSeen: Date
        let created: Date
        let changeCount: Int
    }
    private var source: (any DispatchSourceFileSystemObject)?
    private var known = Set<URL>()
    private var pending: [URL: Pending] = [:]
    private var started = Date()
    private var scanNeeded = false
    private var lastScan = Date.distantPast
    public private(set) var directory: URL?
    private let bridge: ClipboardBridge
    public var onCopied: ((URL) -> Void)?
    public var onError: ((String) -> Void)?

    public init(bridge: ClipboardBridge) { self.bridge = bridge }

    public func watch(_ directory: URL) {
        guard self.directory != directory || source == nil else { return }
        source?.cancel()
        source = nil
        pending.removeAll()
        known.removeAll()
        self.directory = directory
        started = Date()
        do {
            known = Set(try contents())
            let descriptor = open(directory.path, O_EVTONLY)
            guard descriptor >= 0 else { throw CocoaError(.fileReadNoPermission) }
            let watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor,
                eventMask: [.write, .rename, .delete, .attrib, .extend], queue: .main)
            watcher.setEventHandler { [weak self] in
                MainActor.assumeIsolated { self?.scanNeeded = true }
            }
            watcher.setCancelHandler { close(descriptor) }
            source = watcher
            watcher.resume()
        } catch {
            onError?("Cannot watch \(directory.lastPathComponent). Choose an accessible screenshot folder from the menu.")
        }
    }

    public func pause() {
        source?.cancel()
        source = nil
        directory = nil
        pending.removeAll()
    }

    public func tick() {
        guard directory != nil else { return }
        let now = Date()
        guard scanNeeded || !pending.isEmpty || now.timeIntervalSince(lastScan) >= 3 else { return }
        scanNeeded = false
        lastScan = now
        do {
            let current = Set(try contents())
            for file in current.subtracting(known) {
                let values = try? file.resourceValues(forKeys: [.creationDateKey, .isRegularFileKey, .isSymbolicLinkKey])
                guard values?.isRegularFile == true,
                      values?.isSymbolicLink != true,
                      let created = values?.creationDate, created >= started,
                      ["png", "jpg", "jpeg", "heic", "heif", "tiff", "tif"].contains(file.pathExtension.lowercased()) else { continue }
                pending[file] = Pending(firstSeen: now, created: created, changeCount: bridge.pasteboard.changeCount)
            }
            known = current
            // Try recent files first. A successful publication makes older revisions stale.
            let candidates = pending.sorted { $0.value.created > $1.value.created }
            for (file, candidate) in candidates {
                guard current.contains(file), now.timeIntervalSince(candidate.firstSeen) < 20,
                      bridge.pasteboard.changeCount == candidate.changeCount else {
                    pending.removeValue(forKey: file)
                    continue
                }
                guard ScreenshotFiles.isScreenshot(file) else { continue }
                do {
                    if try bridge.processSavedScreenshot(file, expectedChangeCount: candidate.changeCount),
                       let copied = bridge.lastFile { onCopied?(copied) }
                    pending.removeValue(forKey: file)
                } catch {
                    if case BridgeError.imageTooLarge = error {
                        onError?(error.localizedDescription)
                        pending.removeValue(forKey: file)
                        continue
                    }
                    // The screenshot may still be writing. Retry without clearing the clipboard.
                    if now.timeIntervalSince(candidate.firstSeen) > 15 {
                        onError?(error.localizedDescription)
                        pending.removeValue(forKey: file)
                    }
                }
            }
        } catch {
            onError?("Cannot read the screenshot folder. Check Files and Folders access in System Settings.")
        }
    }

    private func contents() throws -> [URL] {
        guard let directory else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory,
            includingPropertiesForKeys: [.creationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
    }
}
