#!/usr/bin/env bash
# Installs IRCAM Thermal Viewer (OpenRMH-IRCAM) on Linux, running under its own
# camera-patched Wine. Everything goes into ~/.local; nothing needs root.
set -euo pipefail

REPO="bigtimer-dev/openrmh-ircam-linux"
RELEASE_TAG="v1.0.0"
WINE_VERSION="11.17"

APP_VERSION="v3.0.0-community.5"
APP_ZIP="OpenRMH-IRCAM-${APP_VERSION}-win-x64.zip"
APP_URL="https://github.com/Cyclotronic/OpenRMH-IRCAM/releases/download/${APP_VERSION}/${APP_ZIP}"
APP_SHA256="0b926e481b3a81757e8d90ec8e6524342b6b3886a49f17de39c0a7b6da6f3794"

WINE_TARBALL="openrmh-wine-${WINE_VERSION}.tar.xz"
WINE_URL="https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${WINE_TARBALL}"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/openrmh-ircam"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- checks
[ "$(uname -m)" = "x86_64" ] || die "Only x86_64 Linux is supported."

missing=()
for cmd in curl tar xz unzip sha256sum winetricks cabextract; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
    die "Missing required programs: ${missing[*]}
Install them first, for example:
  Arch:          sudo pacman -S --needed curl tar xz unzip winetricks cabextract
  Debian/Ubuntu: sudo apt install curl tar xz-utils unzip winetricks cabextract
  Fedora:        sudo dnf install curl tar xz unzip winetricks cabextract"
fi

if ! id -nG | tr ' ' '\n' | grep -qx video; then
    warn "Your user is not in the 'video' group, so the camera may not be accessible.
         Fix with: sudo usermod -aG video \"\$USER\"   (then log out and back in)"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

download() { # url dest
    curl -fL --progress-bar -o "$2" "$1" || die "Download failed: $1"
}

# ---------------------------------------------------------------- patched Wine
WINE_DIR="$DATA_DIR/wine"
info "Installing patched Wine ${WINE_VERSION} into $WINE_DIR"
if [ -n "${OPENRMH_WINE_TARBALL:-}" ]; then
    # Use a locally built tarball (for testing).
    cp "$OPENRMH_WINE_TARBALL" "$TMP_DIR/$WINE_TARBALL"
else
    download "$WINE_URL" "$TMP_DIR/$WINE_TARBALL"
    download "$WINE_URL.sha256" "$TMP_DIR/$WINE_TARBALL.sha256"
    (cd "$TMP_DIR" && sha256sum -c --quiet "$WINE_TARBALL.sha256") || die "Wine tarball checksum mismatch."
fi
mkdir -p "$DATA_DIR"
rm -rf "$WINE_DIR" "$TMP_DIR/wine-extract"
mkdir -p "$TMP_DIR/wine-extract"
tar xf "$TMP_DIR/$WINE_TARBALL" -C "$TMP_DIR/wine-extract"
mv "$TMP_DIR/wine-extract/"* "$WINE_DIR"

export WINEPREFIX="$DATA_DIR/prefix"
export WINEARCH=win64
export WINEDEBUG=-all
export WINE="$WINE_DIR/bin/wine"
export WINESERVER="$WINE_DIR/bin/wineserver"
export PATH="$WINE_DIR/bin:$PATH"

# ---------------------------------------------------------------- Wine prefix
if [ -f "$WINEPREFIX/.openrmh-ready" ]; then
    info "Reusing existing Wine prefix $WINEPREFIX"
else
    rm -rf "$WINEPREFIX"
    info "Creating Wine prefix $WINEPREFIX"
    "$WINE" wineboot -i >/dev/null 2>&1
    "$WINESERVER" -w
    info "Installing .NET Framework 4.8, VC++ runtime and core fonts (takes 10-20 minutes)"
    winetricks -q --unattended dotnet48 vcrun2022 corefonts
    "$WINESERVER" -w
    touch "$WINEPREFIX/.openrmh-ready"
fi
# The prefix keeps its own copy of opengl32.dll; make sure it is the patched one.
cp "$WINE_DIR/lib/wine/x86_64-windows/opengl32.dll" "$WINEPREFIX/drive_c/windows/system32/opengl32.dll"

# ---------------------------------------------------------------- application
info "Installing IRCAM Thermal Viewer ${APP_VERSION}"
download "$APP_URL" "$TMP_DIR/$APP_ZIP"
echo "${APP_SHA256}  $TMP_DIR/$APP_ZIP" | sha256sum -c --quiet || die "Application zip checksum mismatch."
rm -rf "$DATA_DIR/app"
mkdir -p "$DATA_DIR/app"
unzip -q "$TMP_DIR/$APP_ZIP" -d "$DATA_DIR/app"

# ---------------------------------------------------------------- launcher & menu entry
mkdir -p "$BIN_DIR" "$APPS_DIR" "$ICONS_DIR"
install -m755 "$SCRIPT_DIR/openrmh-ircam" "$BIN_DIR/openrmh-ircam"
install -m644 "$SCRIPT_DIR/assets/openrmh-ircam.png" "$ICONS_DIR/openrmh-ircam.png"
sed "s|@BIN@|$BIN_DIR/openrmh-ircam|" "$SCRIPT_DIR/assets/openrmh-ircam.desktop" > "$APPS_DIR/openrmh-ircam.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true

info "Done. Start it from your app menu (\"IRCAM Thermal Viewer\") or run: openrmh-ircam"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "$BIN_DIR is not in your PATH; run $BIN_DIR/openrmh-ircam instead.";; esac
