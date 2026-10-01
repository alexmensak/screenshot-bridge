#!/bin/bash
set -euo pipefail
sourceDir="$(cd "$(dirname "$0")/.." && pwd)"
buildDir="$(mktemp -d "${TMPDIR:-/tmp}/screenshotbridge-build.XXXXXX")"
trap 'rm -rf "$buildDir"' EXIT
export CLANG_MODULE_CACHE_PATH="$buildDir/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$buildDir/swift-cache"
architecture="${ARCH:-$(uname -m)}"
case "$architecture" in arm64|x86_64) ;; *) printf 'Unsupported architecture: %s\n' "$architecture" >&2; exit 1;; esac
destination="${1:-$sourceDir/dist/Screenshot Bridge.app}"
case "$destination" in *.app) ;; *) printf 'Destination must end with .app\n' >&2; exit 1;; esac
if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'Destination already exists. Choose a new output path: %s\n' "$destination" >&2
    exit 1
fi
options=(--package-path "$sourceDir" --scratch-path "$buildDir/build" --cache-path "$buildDir/cache" --config-path "$buildDir/config" --security-path "$buildDir/security" --build-system native --arch "$architecture" -c release -debug-info-format none)
swift build "${options[@]}"
binaryDir="$(swift build "${options[@]}" --show-bin-path)"
stagedApp="$buildDir/Screenshot Bridge.app"
mkdir -p "$stagedApp/Contents/MacOS" "$stagedApp/Contents/Resources"
cp "$binaryDir/ScreenshotBridge" "$stagedApp/Contents/MacOS/ScreenshotBridge"
cp "$sourceDir/Info.plist" "$stagedApp/Contents/Info.plist"
strip -S "$stagedApp/Contents/MacOS/ScreenshotBridge"
swift -module-cache-path "$buildDir/clang-cache" "$sourceDir/scripts/make-icon.swift" "$buildDir/icon.png"
mkdir -p "$buildDir/AppIcon.iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$buildDir/icon.png" --out "$buildDir/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$buildDir/icon.png" --out "$buildDir/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$buildDir/AppIcon.iconset" -o "$stagedApp/Contents/Resources/AppIcon.icns"
# Only our newly generated staging bundle, never an installation or screenshot.
xattr -cr "$stagedApp"
codesign --force --sign - --identifier local.screenshotbridge.app "$stagedApp"
codesign --verify --strict "$stagedApp"
mkdir -p "$(dirname "$destination")"
ditto --norsrc "$stagedApp" "$destination"
printf 'Built (%s): %s\n' "$architecture" "$destination"
