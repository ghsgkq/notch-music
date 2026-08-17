#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_PATH="$PROJECT_DIR/dist/Notch Music.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"
LEGAL_PATH="$RESOURCES_PATH/Legal"
ICON_SOURCE_PATH="$PROJECT_DIR/.build/AppIcon-1024.png"
ICONSET_PATH="$PROJECT_DIR/.build/AppIcon.iconset"
ICON_TIFF_DIR="$PROJECT_DIR/.build/AppIcon.tiffset"
ICON_TIFF_PATH="$PROJECT_DIR/.build/AppIcon.tiff"

export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-/tmp/notch-clang-cache}
export SWIFTPM_CACHE_PATH=${SWIFTPM_CACHE_PATH:-/tmp/notch-swift-cache}

cd "$PROJECT_DIR"
swift build -c release --disable-sandbox
BIN_PATH=$(swift build -c release --show-bin-path)

rm -rf "$APP_PATH"
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH" "$LEGAL_PATH"

cp "$BIN_PATH/NotchMusic" "$MACOS_PATH/NotchMusic"
cp "$BIN_PATH/libMediaRemoteAdapter.dylib" "$MACOS_PATH/libMediaRemoteAdapter.dylib"
cp -R "$BIN_PATH/MediaRemoteAdapter_MediaRemoteAdapter.bundle" "$RESOURCES_PATH/MediaRemoteAdapter_MediaRemoteAdapter.bundle"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_PATH/Info.plist"
cp "$PROJECT_DIR/LICENSE" "$LEGAL_PATH/Notch-Music-LICENSE.txt"
cp "$PROJECT_DIR/THIRD_PARTY_NOTICES.md" "$LEGAL_PATH/THIRD_PARTY_NOTICES.md"

xcrun swift "$PROJECT_DIR/Scripts/GenerateIcon.swift" "$ICON_SOURCE_PATH"
rm -rf "$ICONSET_PATH"
mkdir -p "$ICONSET_PATH"

sips -z 16 16 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE_PATH" --out "$ICONSET_PATH/icon_512x512.png" >/dev/null
cp "$ICON_SOURCE_PATH" "$ICONSET_PATH/icon_512x512@2x.png"

# iconutil on recent macOS releases can reject otherwise valid generated
# iconsets. Build a multi-representation TIFF and convert that to ICNS instead.
rm -rf "$ICON_TIFF_DIR"
mkdir -p "$ICON_TIFF_DIR"
sips -s format tiff "$ICONSET_PATH/icon_16x16.png" --out "$ICON_TIFF_DIR/16.tiff" >/dev/null
sips -s format tiff "$ICONSET_PATH/icon_32x32.png" --out "$ICON_TIFF_DIR/32.tiff" >/dev/null
sips -s format tiff "$ICONSET_PATH/icon_128x128.png" --out "$ICON_TIFF_DIR/128.tiff" >/dev/null
sips -s format tiff "$ICONSET_PATH/icon_256x256.png" --out "$ICON_TIFF_DIR/256.tiff" >/dev/null
sips -s format tiff "$ICONSET_PATH/icon_512x512.png" --out "$ICON_TIFF_DIR/512.tiff" >/dev/null
sips -s format tiff "$ICONSET_PATH/icon_512x512@2x.png" --out "$ICON_TIFF_DIR/1024.tiff" >/dev/null
tiffutil -catnosizecheck \
    "$ICON_TIFF_DIR/16.tiff" \
    "$ICON_TIFF_DIR/32.tiff" \
    "$ICON_TIFF_DIR/128.tiff" \
    "$ICON_TIFF_DIR/256.tiff" \
    "$ICON_TIFF_DIR/512.tiff" \
    "$ICON_TIFF_DIR/1024.tiff" \
    -out "$ICON_TIFF_PATH" >/dev/null
tiff2icns "$ICON_TIFF_PATH" "$RESOURCES_PATH/AppIcon.icns"

chmod +x "$MACOS_PATH/NotchMusic"
touch "$APP_PATH"

# Produce a structurally valid signature even for local builds. Set
# CODESIGN_IDENTITY to a Developer ID Application identity for distribution.
CODESIGN_IDENTITY=${CODESIGN_IDENTITY:--}
SIGNING_ARGS=(--force --sign "$CODESIGN_IDENTITY")
if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
    SIGNING_ARGS+=(--options runtime --timestamp)
fi

codesign "${SIGNING_ARGS[@]}" "$MACOS_PATH/libMediaRemoteAdapter.dylib"
codesign "${SIGNING_ARGS[@]}" "$MACOS_PATH/NotchMusic"
codesign "${SIGNING_ARGS[@]}" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "$APP_PATH"
