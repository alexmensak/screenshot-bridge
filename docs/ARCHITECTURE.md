# Architecture

Swift Package Manager builds a small executable and a testable `BridgeCore` library. Minimum runtime is macOS 14; Swift 6.2+ is required to build. There are no package dependencies.

```text
image-only clipboard → validate → private PNG file ┐
                                                 ├→ one pasteboard item → receiver chooses
new screenshot file → metadata → validate ────────┘   PNG / TIFF / file URL / quoted path
```

- `App.swift`: MainActor application delegate, native AppKit status menu, 0.2-second timer, preferences, ServiceManagement login registration, and user actions.
- `ClipboardBridge`: change-count checks, skip rules, image materialization, one-item multi-format publication, processing marker, and last-path command.
- `ImagePayload`: encoded-size and dimension validation, ImageIO decode, PNG compatibility output, and AppKit TIFF representation.
- `PrivateImageStore`: private directory preparation and exclusive `O_NOFOLLOW` file creation with owner-only permissions.
- `ScreenshotWatcher`: top-level directory DispatchSource events, three-second scan fallback, startup baseline, creation-date ordering, pending write retries, and clipboard-revision checks.
- `ScreenshotFiles`: reads Apple’s screenshot xattr directly rather than relying on localized filenames or delayed Spotlight indexing.

## Invariants

1. Existing clipboard contents are not processed at startup or resume.
2. Single image-only copies are processed once. Generated items and private/transient copies are skipped.
3. Saving/decoding completes before clipboard replacement. Revision checks reject intervening clipboard changes.
4. Pending files are retried for at most 20 seconds; oversized images are rejected immediately.
5. Original screenshots and ordinary user files are never modified or deleted.
6. The store exclusively creates its own uniquely named files. A failed write or abandoned publication can remove only the newly created file.
7. No clipboard content is executed, uploaded, or sent to a subprocess.
8. Login startup is registered only through the explicit menu action.

## Limits and tradeoffs

AppKit pasteboards have no cross-process compare-and-swap transaction. Revision checks narrow the overwrite window but cannot make publication atomic against every competing clipboard writer. Filesystem events do not reveal the original screenshot keypress, so text copied before a delayed file becomes visible can still be replaced by that screenshot.

Filesystem validation and owner-only permissions protect normal use, not an adversary already controlling the same user account. ImageIO is a system decoder, not a separate sandbox service. Conversion currently occurs synchronously on the main actor; exceptionally large accepted images can briefly delay the menu. Revisit this if measured performance warrants an isolated worker.

Representation selection belongs to the receiver. The app does not request Accessibility access, intercept paste keys, or inspect focused inputs. HDR conversion, animated-image handling, terminal path recognition, and multi-monitor captures should be assessed with the manual checklist.
