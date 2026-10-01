# Security policy

Security fixes target the latest release and `main`. This early project has no independent security audit or guarantee of complete safety. Please keep macOS updated, because image decoding uses Apple’s system frameworks.

Report a suspected vulnerability privately through [GitHub’s vulnerability reporting form](https://github.com/alexmensak/screenshot-bridge/security/advisories/new). Do not publish exploit details, personal screenshots, clipboard contents, identifying paths, or credentials in public issues. Include the affected version, minimal synthetic reproduction, impact, and proposed mitigation if available. No bounty or response-time commitment is offered.

Review [Privacy](docs/PRIVACY.md) and [Architecture](docs/ARCHITECTURE.md) for the trust boundary. Important areas include local file permissions, symlink/overwrite handling, decoder resource use, unintended clipboard replacement, accidental persistence, and unintended network behavior.

The app must not gain uploads, telemetry, automatic command execution, privileged helpers, paste-key interception, or silent persistence through routine fixes. Material privacy/permission changes require explicit design discussion and updated documentation.

Builds are currently ad-hoc signed and not notarized. Checksums provide integrity against accidental corruption, not publisher authentication. Do not weaken system-wide security settings to install the app.
