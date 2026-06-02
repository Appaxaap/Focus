#!/usr/bin/env bash
set -euo pipefail

APP_NAME="focus"
BINARY_NAME="focus"
APP_ID="com.appaxaap.focus"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
OUT_DIR="$PROJECT_ROOT/dist"
RPMROOT="$OUT_DIR/rpmbuild"
VERSION_RAW="$(sed -n 's/^version:[[:space:]]*//p' "$PROJECT_ROOT/pubspec.yaml" | head -n1 | tr -d '[:space:]')"
VERSION="${VERSION_RAW%%+*}"
RELEASE="1"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd rpmbuild
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

rm -rf "$RPMROOT"
mkdir -p "$RPMROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS,tmp}

SRC_DIR="$RPMROOT/SOURCES/${APP_NAME}-${VERSION}"
mkdir -p "$SRC_DIR/usr/lib/$APP_NAME" "$SRC_DIR/usr/bin" "$SRC_DIR/usr/share/applications" "$SRC_DIR/usr/share/icons/hicolor/256x256/apps"

cp -a "$BUNDLE_DIR/." "$SRC_DIR/usr/lib/$APP_NAME/"
clean_rpaths "$SRC_DIR/usr/lib/$APP_NAME"
ln -s "../lib/$APP_NAME/$BINARY_NAME" "$SRC_DIR/usr/bin/$BINARY_NAME"
cp "$PROJECT_ROOT/assets/images/512x512_logo.png" "$SRC_DIR/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"

cat > "$SRC_DIR/usr/share/applications/${APP_ID}.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Focus
Exec=${BINARY_NAME}
Icon=${APP_ID}
Categories=Utility;Office;
StartupNotify=true
Terminal=false
DESKTOP

(
  cd "$RPMROOT/SOURCES"
  tar czf "${APP_NAME}-${VERSION}.tar.gz" "${APP_NAME}-${VERSION}"
)

cat > "$RPMROOT/SPECS/${APP_NAME}.spec" <<SPEC
Name:           ${APP_NAME}
Version:        ${VERSION}
Release:        ${RELEASE}%{?dist}
Summary:        Focus offline Eisenhower Matrix task manager
License:        GPL-3.0
URL:            https://github.com/Appaxaap/Focus
Source0:        %{name}-%{version}.tar.gz
BuildArch:      x86_64
Requires:       gtk3

%global debug_package %{nil}
%global __brp_add_determinism /bin/true

%description
Offline-first task manager built with Flutter.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}
cp -a usr %{buildroot}/

%files
/usr/bin/${BINARY_NAME}
/usr/lib/${APP_NAME}
/usr/share/applications/${APP_ID}.desktop
/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png

%changelog
* Tue May 26 2026 Focus Maintainers <security@appaxaap.com> - ${VERSION}-${RELEASE}
- Automated Linux RPM package
SPEC

TMPDIR="$RPMROOT/tmp" rpmbuild \
  --define "_topdir $RPMROOT" \
  --define "_tmppath $RPMROOT/tmp" \
  -bb "$RPMROOT/SPECS/${APP_NAME}.spec"

mkdir -p "$OUT_DIR"
cp "$RPMROOT/RPMS/x86_64/${APP_NAME}-${VERSION}-${RELEASE}"*.rpm "$OUT_DIR/"

echo "Created RPM in: $OUT_DIR"
