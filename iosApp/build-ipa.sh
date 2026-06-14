#!/usr/bin/env bash
#
# Build a sideloadable, UNSIGNED .ipa of Pillion (app + broadcast extension) for distribution
# *without* the App Store. Users install it with AltStore / SideStore / Sideloadly / TrollStore,
# which re-sign it with their own (free) Apple ID on device — so we ship it unsigned on purpose.
#
# Usage:  ./build-ipa.sh [Debug|Release]   (default Release)
#
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

CONFIG="${1:-Release}"
DD="build/ipa"

xcodegen generate >/dev/null
rm -rf "$DD" Payload Pillion.ipa

xcodebuild -project iosApp.xcodeproj -scheme iosApp -configuration "$CONFIG" \
  -destination 'generic/platform=iOS' -derivedDataPath "$DD" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build

APP=$(find "$DD/Build/Products" -maxdepth 2 -name 'iosApp.app' | head -1)
[ -n "$APP" ] || { echo "error: build produced no .app" >&2; exit 1; }

mkdir -p Payload
cp -R "$APP" Payload/
zip -qry Pillion.ipa Payload
rm -rf Payload

echo "built: $(pwd)/Pillion.ipa  ($(du -h Pillion.ipa | cut -f1))"
echo "embedded extension: $(unzip -l Pillion.ipa | grep -c '\.appex/') files"