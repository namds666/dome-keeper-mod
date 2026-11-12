#!/bin/bash
# Turns on mods (Steam Workshop subscriptions) for the macOS Steam build of Dome Keeper.
# Adds three files and changes nothing in the game: undo with disable-mods.command.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STEAM_LIBRARY="${STEAM_LIBRARY:-/Users/Shared/Steam Library}"
GAME_MACOS="$STEAM_LIBRARY/steamapps/common/Dome Keeper/Contents/MacOS"
USER_DIR="$HOME/Library/Application Support/Godot/app_userdata/Dome Keeper"

if [ ! -x "$GAME_MACOS/Dome Keeper" ]; then
	echo "Dome Keeper not found at: $GAME_MACOS"
	echo "Run again with STEAM_LIBRARY=\"/path/to/your Steam Library\""
	exit 1
fi

mkdir -p "$USER_DIR"
cp "$HERE/ModLoaderStoreMac.gd" "$HERE/BuildCustomizationMac.gd" "$USER_DIR/"
cat > "$GAME_MACOS/override.cfg" <<'EOF'
[autoload]

ModLoaderStore="*user://ModLoaderStoreMac.gd"
BuildCustomization="*user://BuildCustomizationMac.gd"
EOF

echo "Mods enabled. Start Dome Keeper from Steam as usual."
