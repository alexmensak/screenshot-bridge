# Maintainer release process

1. Run tests and the manual checklist. Verify that the exact source commit has successful CI, or disclose a concrete external CI limitation.
2. Update `CHANGELOG.md` and bundle versions together. Create a version tag on that reviewed commit.
3. Build each architecture to a fresh destination using `ARCH=arm64` and `ARCH=x86_64` with `scripts/build.sh`. Cross-building is not an Intel runtime test; record runtime coverage honestly.
4. Archive with `ditto --norsrc -c -k --keepParent` so extended attributes added by Finder or cloud file providers do not invalidate local signing in the download. Extract into a clean temporary directory and verify `codesign --verify --strict` and `lipo -archs` for each app.
5. Scan tracked files and extracted binary strings for secrets, personal paths, and private email addresses. Never package tests, screenshots, logs, caches, or source-control credentials with the app.
6. Generate `shasum -a 256` checksums for the archives. Create a GitHub release with architecture-labeled downloads, checksums, exact source tag, required macOS version, permission/storage behavior, and explicit ad-hoc signing/notarization status.
7. Keep repo Actions permissions read-only, action versions pinned, and private vulnerability reporting enabled. Never put signing certificates or credentials in the repository.

The app currently has no automatic update mechanism. Release binaries are not reproducibly byte-identical across toolchain versions, and ad-hoc signing does not authenticate the publisher. A future Developer ID/notarized release needs an explicit secure signing workflow.
