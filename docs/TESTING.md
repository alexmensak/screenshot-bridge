# Testing

Run `./scripts/test.sh` on a Mac with Xcode 26+ selected. Tests use uniquely named private pasteboards and disposable temporary directories. They never read or replace `NSPasteboard.general`. A logged-in macOS session with pasteboard-service access is necessary; a restricted shell sandbox or headless environment may block integration tests.

The suite covers image/file/text representations, decoder failure, startup behavior, marker replay, private/transient/mixed/multi-item skip rules, terminal quoting, newer clipboard preservation, screenshot metadata, folder-only processing, newest-file ordering, dimension limits, private file permissions, exclusive writes, and symlink rejection.

## Manual release checklist

Use a harmless test image; never upload a real private screenshot to an issue.

- Install the correct architecture bundle; verify menu icon and welcome text.
- Test Control-Shift-Command-4 and Shift-Command-4, with thumbnail on and off.
- Test Shift-Command-3 multi-monitor captures and Shift-Command-5 image capture. Verify recordings are ignored.
- Paste into a native image field, browser upload field, PyCharm terminal, and another terminal. Record actual receiver behavior rather than assuming image-first selection.
- Exercise Copy Last Path Only, path quoting, Reveal, Pause/resume, and clipboard-image disable/enable.
- Deny and re-enable folder/clipboard permissions; verify recovery without changing unrelated settings.
- Change the macOS screenshot folder; test the manual override and return to Automatic.
- Verify private PNG file permissions, original screenshot preservation, and disk retention.
- Test HEIF/HDR conversion and make no unverified color-preservation claim.
- Move the app to Applications; toggle Launch at Login; verify one startup after an actual logout/login.
- Quit/uninstall; verify no background daemon is installed and screenshot files remain.

Automated success does not imply every receiving app or supported macOS version has passed this checklist. Share compatibility reports with exact macOS/app versions and synthetic examples only.
