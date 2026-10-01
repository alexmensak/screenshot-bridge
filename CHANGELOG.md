# Changelog

## 1.0.0 — 2026-10-01

First public release.

- Native macOS menu bar utility, optional startup at login, and pause/resume.
- Clipboard-only image materialization and saved screenshot watching.
- PNG/TIFF, file-reference, and quoted path representations in one clipboard item.
- Owner-only image storage, exclusive file creation, symlink rejection, input limits, and processing guards.
- No runtime network access or third-party dependencies.
- Automated tests, macOS CI, source build scripts, privacy/security documentation, and MIT license.

Known limits: receiver-dependent paste selection; unnotarized builds; no complete HDR-color guarantee; image decoding in the app process; no crash-restart service; manual application compatibility testing remains necessary.
