#!/usr/bin/env bash
# Removes everything install.sh created.
set -euo pipefail
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DATA_DIR="$DATA/openrmh-ircam"

if [ -x "$DATA_DIR/wine/bin/wineserver" ]; then
    WINEPREFIX="$DATA_DIR/prefix" "$DATA_DIR/wine/bin/wineserver" -k 2>/dev/null || true
fi
rm -rf "$DATA_DIR"
rm -f "$HOME/.local/bin/openrmh-ircam" \
      "$DATA/applications/openrmh-ircam.desktop" \
      "$DATA/icons/hicolor/256x256/apps/openrmh-ircam.png"
echo "IRCAM Thermal Viewer (OpenRMH-IRCAM) has been removed."
