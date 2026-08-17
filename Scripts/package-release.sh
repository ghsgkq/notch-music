#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
VERSION=${1:-}
APP_PATH="$PROJECT_DIR/dist/Notch Music.app"

if [[ -z "$VERSION" ]]; then
    echo "Usage: CODESIGN_IDENTITY='Developer ID Application: …' NOTARY_PROFILE=notch-music $0 <version>" >&2
    exit 64
fi

if [[ -z "${CODESIGN_IDENTITY:-}" || "$CODESIGN_IDENTITY" == "-" ]]; then
    echo "CODESIGN_IDENTITY must name a Developer ID Application certificate." >&2
    exit 64
fi

if [[ -z "${NOTARY_PROFILE:-}" ]]; then
    echo "NOTARY_PROFILE must name a notarytool keychain profile." >&2
    exit 64
fi

export CODESIGN_IDENTITY
"$SCRIPT_DIR/build-app.sh"

ARCHIVE_PATH="$PROJECT_DIR/dist/Notch-Music-$VERSION.zip"
rm -f "$ARCHIVE_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ARCHIVE_PATH"

xcrun notarytool submit "$ARCHIVE_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=2 "$APP_PATH"

# Include the stapled notarization ticket in the downloadable archive.
rm -f "$ARCHIVE_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ARCHIVE_PATH"
shasum -a 256 "$ARCHIVE_PATH"

echo "$ARCHIVE_PATH"
