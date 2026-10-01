#!/bin/bash
set -euo pipefail
sourceDir="$(cd "$(dirname "$0")/.." && pwd)"
testDir="$(mktemp -d "${TMPDIR:-/tmp}/screenshotbridge-tests.XXXXXX")"
trap 'rm -rf "$testDir"' EXIT
export CLANG_MODULE_CACHE_PATH="$testDir/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$testDir/swift-cache"
swift test --package-path "$sourceDir" --scratch-path "$testDir/build" --cache-path "$testDir/cache" --config-path "$testDir/config" --security-path "$testDir/security" --build-system native -debug-info-format none "$@"
