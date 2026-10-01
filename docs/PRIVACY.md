# Privacy and data handling

Screenshot Bridge works locally and does not contact a server. It has no telemetry, analytics, accounts, crash uploader, external image decoder, automatic updater, or third-party runtime dependencies. The project’s GitHub page, badge images, downloads, and CI are external services used outside the running app.

## Clipboard

While clipboard-image handling is enabled, the app checks the general pasteboard change counter approximately every 0.2 seconds. It examines advertised types, skips text/URL/file/multi-item/private/transient copies, and reads a single image-only item. It validates and decodes that image, saves a PNG, then publishes PNG, TIFF, file-URL, plain-text path, and a processing marker together.

Clipboard screenshots are indistinguishable from other image-only copies. This setting therefore also saves pictures copied from other apps. Turn off **Handle Clipboard Images** for folder-only operation. Existing clipboard content is ignored on startup or when monitoring is re-enabled.

The app does not read clipboard text as a command or execute it. Normal text-only clipboard copies are not materialized. It stores no clipboard-history database and remembers only the last handled path in memory for menu commands.

## Local files

App-created images are stored in `~/Pictures/Screenshot Bridge/`. That directory is created/hardened to `0700`; new files are exclusively created with `0600`. A symlink save directory is rejected. Existing files cannot be overwritten by the image-store operation. macOS-created original screenshots are read and referenced without changing their contents or permissions.

Files are retained until you remove them. They can contain private information and consume disk space. They may be backed up or synced by other software. Owner-only permissions do not block other processes running under your account, administrators, or authorized backup services. This is not encrypted storage.

Input is limited to 100 MiB encoded and 40 million pixels before decoding. ImageIO runs inside the app process; resource checks are not a hardened parser sandbox. Only the first frame of an animated clipboard image is materialized. PNG/TIFF output may retain image color information; no complete metadata-stripping guarantee is made.

## Screenshot folder and settings

The app reads macOS’s configured screenshot directory, watches its top level, and checks new image files for Apple’s screenshot metadata. It does not recursively inspect other folders, rename original screenshots, record the screen, or change screenshot preferences. A manually selected folder is stored in macOS UserDefaults alongside clipboard-handling, path-quoting, and welcome-screen preferences.

Launch at Login is opt-in and uses `SMAppService.mainApp`. macOS owns its registration and approval state. Quit stops the current session; disable the setting before uninstalling if you do not want future startup.

Errors may go to the macOS unified log with private string interpolation. The app does not log image bytes or clipboard text. System logging, backups, OS clipboard services, Universal Clipboard, and receiving apps have their own privacy behavior. A path pasted into another service can reveal your account name or directory structure; check it before sending.

## Permission boundary

The app is not App Sandbox confined. It relies on normal user privileges and macOS privacy permissions for protected folders and pasteboard access. It requires neither administrator access nor Accessibility, Screen Recording, microphone, camera, Full Disk Access, or network credentials. Denying permissions may disable the corresponding functionality; permissions are never bypassed.

To stop processing, Pause or Quit. To remove saved data, inspect and delete the image folder yourself. Uninstalling the app does not delete screenshots or reset unrelated macOS settings.
