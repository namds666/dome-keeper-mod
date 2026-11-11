extends "res://systems/options/Options.gd"


func _init() -> void:
	INPUT_ACTIONS["keeper9"] = ["keeper9_mine"]
	keeperInputSettings["keeper9.Mouse"] = KeeperInputSettings.new()
	keeperInputSettings["keeper9.Gamepad"] = KeeperInputSettings.new()
