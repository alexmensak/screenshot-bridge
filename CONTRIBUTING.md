# Contributing

Focused pull requests, bug reports, compatibility notes, and documentation fixes are welcome. Use Xcode 26+ / Swift 6.2+, run `./scripts/test.sh`, then build with `./scripts/build.sh` to a new output destination. Keep changes small enough to review and explain the observed trigger, resulting behavior, and verification.

Follow the project’s MainActor-first Swift structure. Add meaningful regression tests for clipboard, file privacy, or watcher behavior. Use synthetic images and private named pasteboards; do not access the general clipboard from automated tests. No third-party runtime dependencies, telemetry, uploads, privilege escalation, or automatic commands without a separately discussed design.

Never commit screenshots, personal paths, logs, signing certificates, secrets, generated app bundles, or build caches. Use GitHub’s private security reporting for vulnerabilities. Public issue forms are appropriate for ordinary bugs only.

Before a release, follow [Testing](docs/TESTING.md). Maintainers should publish checksums and architecture-specific bundles, clearly state their signing/notarization status, and tag the exact tested source. Contributions are licensed under the project’s MIT license.
