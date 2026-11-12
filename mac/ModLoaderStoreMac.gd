extends "res://addons/mod_loader/mod_loader_store.gd"

# The macOS Steam build is exported with the "disable_mods" feature tag, which forces a
# mod loader profile with mods off. This replaces that profile with one that loads the
# subscribed Workshop items. Installed as the ModLoaderStore autoload by override.cfg.
# The stock game version check stays on: a mod made for 4.x that extends a changed game
# script crashes 5.x (raziel444-NoMoreKnockback did).

const APP_ID := "1637320"


func _update_ml_options_from_cli_args() -> void:
	ml_options = ml_options.duplicate() as ModLoaderOptionsProfile
	ml_options.enable_mods = true
	ml_options.load_from_steam_workshop = true
	ml_options.load_from_local = true
	ml_options.override_path_to_workshop = _workshop_dir()
	super._update_ml_options_from_cli_args()


# <steamapps>/common/Dome Keeper/Contents/MacOS/Dome Keeper -> <steamapps>/workshop/content/<app id>
func _workshop_dir() -> String:
	var steamapps := OS.get_executable_path().get_base_dir().get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return steamapps.path_join("workshop/content").path_join(APP_ID)
