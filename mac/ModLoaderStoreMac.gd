extends "res://addons/mod_loader/mod_loader_store.gd"

# The macOS Steam build is exported with the "disable_mods" feature tag, which forces a
# mod loader profile with mods off. This replaces that profile with one that loads the
# subscribed Workshop items. Installed as the ModLoaderStore autoload by override.cfg.

const APP_ID := "1637320"
# Game 4.0 moved to Godot 4. Mods made for 3.x and older cannot compile.
const FIRST_GODOT4_GAME_MAJOR := 4


func _update_ml_options_from_cli_args() -> void:
	ml_options = ml_options.duplicate() as ModLoaderOptionsProfile
	ml_options.enable_mods = true
	ml_options.load_from_steam_workshop = true
	ml_options.load_from_local = true
	ml_options.override_path_to_workshop = _workshop_dir()
	ml_options.game_version_validation = ModLoaderOptionsProfile.VERSION_VALIDATION.CUSTOM
	ml_options.custom_game_version_validation_callable = _validate_game_version
	super._update_ml_options_from_cli_args()


# <steamapps>/common/Dome Keeper/Contents/MacOS/Dome Keeper -> <steamapps>/workshop/content/<app id>
func _workshop_dir() -> String:
	var steamapps := OS.get_executable_path().get_base_dir().get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return steamapps.path_join("workshop/content").path_join(APP_ID)


# The stock check rejects every mod whose manifest names an older major game version,
# so most Workshop mods for 4.x fail on 5.x. Only reject mods from before Godot 4.
func _validate_game_version(manifest: ModManifest) -> void:
	var game_version: String = ml_options.semantic_version
	var game_major := int(game_version.get_slice(".", 0))
	var newest_major := -1
	for version in manifest.compatible_game_version:
		newest_major = max(newest_major, int(String(version).get_slice(".", 0)))

	if newest_major >= game_major:
		return
	var message := "The mod \"%s\" was made for game versions %s (current game version: %s)." % [
		manifest.get_mod_id(), manifest.compatible_game_version, game_version]
	if newest_major >= FIRST_GODOT4_GAME_MAJOR:
		manifest.validation_messages_warning.push_back(message + " Enable at your own risk.")
	else:
		manifest.validation_messages_error.push_back(message + " It cannot run on this version.")
