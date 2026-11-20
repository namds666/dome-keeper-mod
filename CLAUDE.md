# Dome Keeper mods (namds666)

Mods for Dome Keeper (Steam app 1637320, Godot 4.3, GDScript Mod Loader 7.0.1).
Remote: `git@github.com-namds666:namds666/dome-keeper-mod.git` (public). Commits go out as namds666.

## Owner rules

- When a task is done, run § Finish a task without asking. Commit and push alone never reach the game: it loads the mod only from the local Workshop folder (owner 2026-11-20: "có cả 2", "viết luôn vào claude.md repo này là auto làm vậy mỗi lần commit push", "viết hết tất cả mọi bước chi tiết vào làm rule và workflow đi, tao không muốn nhắc lại").
- Never keep backup copies of old zips or files: git and the Workshop history keep old versions (owner 2026-11-20: "git sinh ra để làm con mẹ gì vậy").
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
- Keep the stock game version check. It rejects mods whose manifest names an older major version. Loosening it to load 4.x mods crashed 5.0.8 with a segfault: raziel444-NoMoreKnockback (for 4.2.0) extends `Keeper1.gd`, which changed in 5.x.

- The docs' `Keepers.register_keeper` (5.1+) does not exist in 5.0.8. `mod_main.gd` uses it when present, else registers by hand: `Data.registerKeeper`, `GameWorld.unlockElement`, `take_over_path` aliases for sprite frames, loadout icons and `res://content/keeper/<Id>InputProcessor.gd`.
- Keeper ids must be `keeper` + one digit: `LoadoutKeeper.to_bytes` sends `int(id.lstrip("keeper"))`, and `SaveGame` treats only 7-character ids as keepers. Vanilla uses 1–5. The Miner is `keeper9`.
- A keeper reusing `Keeper1.gd` reads `keeper1.*` and `keeper.*` per player. Device selection and loadout seed these only for vanilla keepers, so a custom keeper must seed its own (`Miner._seedMissingValues`).
- `Options.keeperInputSettings` needs `<id>.Mouse` and `<id>.Gamepad` entries, and `KeyBindingsPanel.translations` needs a label for every action in `Options.INPUT_ACTIONS`. Both are added by script extensions.
- `take_over_path` aliases last only while referenced: keep the resources in an array on the mod node.
- Tech tree icons load from `res://content/icons/<upgrade id>.png`, titles from `upgrades.<id>.title`. `shadowing` also replaces the title, so alias icons instead.
- A script extension of `content/techtree/techtrack/TechTrack.gd` never takes effect: `TechTree.gd` preloads `TechTrack.tscn`, so the scene holds the vanilla script before mods load. `mod_main.gd` re-lays the Miner track from `SceneTree.node_added` (`techtree/MinerTechLayout.gd`).
- A saved run restores `GameWorld.upgrades` from the save (`setUpgradeData`), so upgrades a newer mod version adds stay hidden until `GameWorld.updateAvailableUpgrades(playerId)` runs. `Miner.gd` calls it once per level.
- Tile damage: `tile.hit(dir, damage, teamId, techId)`, server only. `Level.map.tiles` holds revealed tiles keyed by `Vector2`. Solid unrevealed cells have `tileData.get_resourcev(coord) != Data.TILE_EMPTY`.

## Finish a task

1. Task changed `mods-unpacked/Namds-Miner/`: run `workshop/ship.sh` (Steam must be running). It
   - bumps the patch `version_number` in `mods-unpacked/Namds-Miner/manifest.json` (`workshop/ship.sh 1.5.0` sets a version instead, for a bigger feature);
   - runs `python3 workshop/package.py` → `.tools/dist/Namds-Miner-<version>/Namds-Miner-<version>.zip`;
   - runs `workshop/upload.gd` with the modding Godot, which updates the item in `workshop/item_id.txt` (or creates one and writes the id there), and fails unless the log prints `UPLOADED`;
   - replaces the zip in `/Users/Shared/Steam Library/steamapps/workshop/content/1637320/<item id>/` with the new one, so the next game start loads it at once (the Steam client can take a day to download an update).
   A failed step stops the script: fix it and run it again, never skip it.
2. Commit every changed file, the bumped `manifest.json` included, and push `main`.
3. Reply with the version, the Workshop link `https://steamcommunity.com/sharedfiles/filedetails/?id=<item id>` and "restart the game to load it".

Check a version reached the game: `~/Library/Application Support/Godot/app_userdata/Dome Keeper/logs/modloader.log` names the zip it loaded.
