#!/bin/bash
# Removes what enable-mods.command added.
set -euo pipefail

STEAM_LIBRARY="${STEAM_LIBRARY:-/Users/Shared/Steam Library}"
rm -f "$STEAM_LIBRARY/steamapps/common/Dome Keeper/Contents/MacOS/override.cfg"
rm -f "$HOME/Library/Application Support/Godot/app_userdata/Dome Keeper/ModLoaderStoreMac.gd"
echo "Mods disabled."
