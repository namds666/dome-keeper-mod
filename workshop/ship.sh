#!/bin/bash
# Ships the mod: bump the patch version, package, upload to the Workshop, install the zip
# into the local Workshop folder (the game reads only that folder; Steam can take a day to sync it).
# Usage: workshop/ship.sh [new version]   (default: patch + 1)
set -euo pipefail
cd "$(dirname "$0")/.."

MANIFEST=mods-unpacked/Namds-Miner/manifest.json
GODOT=.tools/godot/macos_tools.app/Contents/MacOS/Godot
WORKSHOP="${STEAM_LIBRARY:-/Users/Shared/Steam Library/steamapps}/workshop/content/1637320"

pgrep -x steam_osx >/dev/null || { echo "FAILED: Steam is not running" >&2; exit 1; }

version=$(python3 - "$MANIFEST" "${1:-}" <<'EOF'
import json, re, sys
path, wanted = sys.argv[1], sys.argv[2]
text = open(path).read()
old = json.loads(text)["version_number"]
major, minor, patch = map(int, old.split("."))
new = wanted or f"{major}.{minor}.{patch + 1}"
open(path, "w").write(text.replace(f'"version_number": "{old}"', f'"version_number": "{new}"', 1))
print(new)
EOF
)
echo "Version $version"

zip=$(python3 workshop/package.py)

log=$(mktemp)
"$GODOT" --headless --path . --script workshop/upload.gd >"$log" 2>&1 || true
grep -E "^(Uploading|UPLOADED|FAILED|NOTE)" "$log" || true
grep -q "^UPLOADED" "$log" || { echo "FAILED: upload did not finish, full log: $log" >&2; exit 1; }
rm -f "$log"

dest="$WORKSHOP/$(cat workshop/item_id.txt)"
mkdir -p "$dest"
rm -f "$dest"/Namds-Miner-*.zip
cp "$zip" "$dest/"
echo "Installed $dest/$(basename "$zip")"
