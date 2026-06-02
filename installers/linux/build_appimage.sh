#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Focus"
APP_ID="com.appaxaap.focus"
BINARY_NAME="focus"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
VERSION_RAW="$(sed -n 's/^version:[[:space:]]*//p' "$PROJECT_ROOT/pubspec.yaml" | head -n1 | tr -d '[:space:]')"
VERSION="${VERSION_RAW%%+*}"
OUT_DIR="$PROJECT_ROOT/dist"
APPDIR="$OUT_DIR/${APP_NAME}.AppDir"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd wget
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
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp "$BUNDLE_DIR/$BINARY_NAME" "$APPDIR/usr/bin/$BINARY_NAME"
cp -a "$BUNDLE_DIR/lib" "$APPDIR/usr/"
cp -a "$BUNDLE_DIR/data" "$APPDIR/usr/"
clean_rpaths "$APPDIR/usr"
cp "$PROJECT_ROOT/assets/images/512x512_logo.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"
cp "$PROJECT_ROOT/assets/images/512x512_logo.png" "$APPDIR/${APP_ID}.png"

cat > "$APPDIR/usr/share/applications/${APP_ID}.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Exec=${BINARY_NAME}
Icon=${APP_ID}
Categories=Utility;Office;
StartupNotify=true
Terminal=false
DESKTOP

cp "$APPDIR/usr/share/applications/${APP_ID}.desktop" "$APPDIR/${APP_ID}.desktop"
ln -sf "usr/share/icons/hicolor/256x256/apps/${APP_ID}.png" "$APPDIR/.DirIcon"

APPIMAGETOOL="$OUT_DIR/appimagetool-x86_64.AppImage"
if [[ ! -x "$APPIMAGETOOL" ]]; then
  wget -O "$APPIMAGETOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x "$APPIMAGETOOL"
fi

APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 \
  "$APPIMAGETOOL" "$APPDIR" "$OUT_DIR/${APP_NAME}-${VERSION}-x86_64.AppImage"

echo "Created: $OUT_DIR/${APP_NAME}-${VERSION}-x86_64.AppImage"
