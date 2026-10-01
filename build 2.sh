#!/bin/bash
set -euo pipefail
sourceDir="$(cd "$(dirname "$0")" && pwd)"
buildDir="$(mktemp -d "${TMPDIR:-/tmp}/screenshotbridge-build.XXXXXX")"
trap 'rm -rf "$buildDir"' EXIT
export CLANG_MODULE_CACHE_PATH="$buildDir/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$buildDir/swift-cache"
destination="${1:-$sourceDir/../Screenshot Bridge.app}"
options=(--package-path "$sourceDir" --scratch-path "$buildDir/build" --cache-path "$buildDir/cache" --config-path "$buildDir/config" --security-path "$buildDir/security" --disable-sandbox --build-system native -c release -debug-info-format none)
swift build "${options[@]}"
binaryDir="$(swift build "${options[@]}" --show-bin-path)"
mkdir -p "$destination/Contents/MacOS" "$destination/Contents/Resources"
cp "$binaryDir/ScreenshotBridge" "$destination/Contents/MacOS/ScreenshotBridge"
cp "$sourceDir/Info.plist" "$destination/Contents/Info.plist"
swift -module-cache-path "$buildDir/clang-cache" "$sourceDir/make-icon.swift" "$buildDir/icon.png"
mkdir -p "$buildDir/AppIcon.iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$buildDir/icon.png" --out "$buildDir/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$buildDir/icon.png" --out "$buildDir/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$buildDir/AppIcon.iconset" -o "$destination/Contents/Resources/AppIcon.icns"
# Only clean build metadata from this newly assembled app, never user screenshot files.
xattr -cr "$destination"
codesign --force --sign - --identifier local.screenshotbridge.app "$destination"
codesign --verify --strict "$destination"
printf 'Built: %s\n' "$destination"
