# Dome Keeper mods (namds666)

Mods for Dome Keeper (Steam app 1637320, Godot 4.3, GDScript Mod Loader 7.0.1).
Remote: `git@github.com-namds666:namds666/dome-keeper-mod.git` (public). Commits go out as namds666.

## Owner rules

- Never run or launch the game (windowed or headless play) unless the owner asks for a test in that task (owner: "ê đừng spawn game ra nữa", "tao chưa cho phép mày test game, việc đó để sau nhé"). Static checks and packaging are fine.

## Legal (Modding EULA, docs wiki "Legal" / "Getting Started")

- Never commit or ship game files: no `.pck`, no decompiled scripts, scenes, images or sounds. The mod may reference game resources by `res://` path at runtime. It must not contain copies of them.
- A mod zip holds only `mods-unpacked/<Author-Mod>/` and the `.godot/imported/` files that mod created.
- Mods are free. Donations and sponsorships are allowed, sales are not.
- No obfuscated code, no ads, no DLC unlocks, no cheats for competitive modes. Mods made only for personal use must not be published.
- Uploading to the Workshop accepts the Dome Keeper mod EULA and the Steam Workshop agreement. Mods disable Prestige leaderboards.

## Repo layout

The working tree is the decompiled game project. `.gitignore` whitelists only our files:
`CLAUDE.md`, `README.md`, `workshop/`, `mac/` and `mods-unpacked/Namds-Miner/`. Everything else is local only:
- `.tools/godot/macos_tools.app`: the modding Godot editor, from DomeKeeperMods/Docs release `5.1`. Stock Godot does not work.
- `.tools/gdre/`: GDRETools (decompiler). `.tools/docs-wiki/`: clone of the DomeKeeperMods docs wiki.
- `mods-unpacked/Namds-MinerTest/`: local test driver, never shipped.

Rebuild the project after a game update:
```sh
".tools/gdre/Godot RE Tools.app/Contents/MacOS/Godot RE Tools" --headless \
  --recover="/Users/Shared/Steam Library/steamapps/common/Dome Keeper/Contents/Resources/Dome Keeper.pck" --output=<dir>
```
Then copy the output over the repo root (keep `.git`, our files and `.tools`), remove `disable_mods` from `_custom_features` in `project.godot` (it turns mods off in the editor), and run `.tools/godot/macos_tools.app/Contents/MacOS/Godot --headless --path . --import`.

## Game facts for 5.0.8 (checked in the decompiled code)

- The macOS Steam build is exported with the `disable_mods` feature tag: mods are off and `BuildCustomization` hides the Mods button. `override.cfg` cannot remove a feature tag. `mac/enable-mods.command` puts `override.cfg` in `Contents/MacOS/` that swaps two autoloads for scripts copied to `user://`: `ModLoaderStoreMac.gd` turns mods and Workshop loading on, and `BuildCustomizationMac.gd` shows the Mods button. `mac/disable-mods.command` undoes it. The stock profile also has `load_from_steam_workshop = false`.
- The stock game version check rejects every mod whose manifest names an older major version (a mod for 4.2.0 fails on 5.0.8). `ModLoaderStoreMac.gd` rejects only mods for 3.x and older (before Godot 4) and loads 4.x mods with a warning.

- The docs' `Keepers.register_keeper` (5.1+) does not exist in 5.0.8. `mod_main.gd` uses it when present, else registers by hand: `Data.registerKeeper`, `GameWorld.unlockElement`, `take_over_path` aliases for sprite frames, loadout icons and `res://content/keeper/<Id>InputProcessor.gd`.
- Keeper ids must be `keeper` + one digit: `LoadoutKeeper.to_bytes` sends `int(id.lstrip("keeper"))`, and `SaveGame` treats only 7-character ids as keepers. Vanilla uses 1–5. The Miner is `keeper9`.
- A keeper reusing `Keeper1.gd` reads `keeper1.*` and `keeper.*` per player. Device selection and loadout seed these only for vanilla keepers, so a custom keeper must seed its own (`Miner._seedMissingValues`).
- `Options.keeperInputSettings` needs `<id>.Mouse` and `<id>.Gamepad` entries, and `KeyBindingsPanel.translations` needs a label for every action in `Options.INPUT_ACTIONS`. Both are added by script extensions.
- `take_over_path` aliases last only while referenced: keep the resources in an array on the mod node.
- Tech tree icons load from `res://content/icons/<upgrade id>.png`, titles from `upgrades.<id>.title`. `shadowing` also replaces the title, so alias icons instead.
- Tile damage: `tile.hit(dir, damage, teamId, techId)`, server only. `Level.map.tiles` holds revealed tiles keyed by `Vector2`. Solid unrevealed cells have `tileData.get_resourcev(coord) != Data.TILE_EMPTY`.

## Ship a version

1. Bump `version_number` in `mods-unpacked/Namds-Miner/manifest.json`.
2. `python3 workshop/package.py` → `.tools/dist/Namds-Miner-<version>/Namds-Miner-<version>.zip`.
3. `.tools/godot/macos_tools.app/Contents/MacOS/Godot --headless --path . --script workshop/upload.gd` with Steam running. It updates the item in `workshop/item_id.txt`, or creates one and writes the id there.
4. Local test without the Workshop: put the zip in a new folder under `/Users/Shared/Steam Library/steamapps/workshop/content/1637320/`.
