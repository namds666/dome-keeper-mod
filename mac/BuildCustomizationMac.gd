extends "res://systems/build-customization/BuildCustomization.gd"

# The "disable_mods" feature tag of the macOS build also hides the Mods button on the
# title screen. Installed as the BuildCustomization autoload by override.cfg.


func _init() -> void:
	features["disable_modding"] = false
