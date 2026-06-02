#!/usr/bin/env bash
set -euo pipefail

APP_NAME="focus"
BINARY_NAME="focus"
APP_ID="com.appaxaap.focus"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
OUT_DIR="$PROJECT_ROOT/dist"
PKG_DIR="$OUT_DIR/${APP_NAME}_pkg"
VERSION_RAW="$(sed -n 's/^version:[[:space:]]*//p' "$PROJECT_ROOT/pubspec.yaml" | head -n1 | tr -d '[:space:]')"
VERSION="${VERSION_RAW%%+*}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd dpkg-deb
need_cmd patchelf

clean_rpaths() {
  local root="$1"
  while IFS= read -r -d '' file; do
    if file "$file" | grep -q 'ELF'; then
      patchelf --remove-rpath "$file" 2>/dev/null || true
    fi
  done < <(find "$root" -type f -print0)
}

if [[ ! -x "$BUNDLE_DIR/$BINARY_NAME" ]]; then
  echo "Linux release bundle not found. Run: flutter build linux --release" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
rm -rf "$PKG_DIR"

mkdir -p \
  "$PKG_DIR/DEBIAN" \
  "$PKG_DIR/usr/lib/$APP_NAME" \
  "$PKG_DIR/usr/bin" \
  "$PKG_DIR/usr/share/applications" \
  "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"

cp -a "$BUNDLE_DIR/." "$PKG_DIR/usr/lib/$APP_NAME/"
clean_rpaths "$PKG_DIR/usr/lib/$APP_NAME"
ln -s "../lib/$APP_NAME/$BINARY_NAME" "$PKG_DIR/usr/bin/$BINARY_NAME"
cp "$PROJECT_ROOT/assets/images/512x512_logo.png" "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"

cat > "$PKG_DIR/usr/share/applications/${APP_ID}.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Focus
Exec=${BINARY_NAME}
Icon=${APP_ID}
Categories=Utility;Office;
StartupNotify=true
Terminal=false
DESKTOP

cat > "$PKG_DIR/DEBIAN/control" <<CONTROL
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Focus Maintainers <security@appaxaap.com>
Depends: libgtk-3-0, libblkid1, liblzma5
Description: Focus offline Eisenhower Matrix task manager
 Offline-first task manager built with Flutter.
CONTROL

dpkg-deb --root-owner-group --build "$PKG_DIR" "$OUT_DIR/${APP_NAME}_${VERSION}_amd64.deb"

echo "Created: $OUT_DIR/${APP_NAME}_${VERSION}_amd64.deb"
