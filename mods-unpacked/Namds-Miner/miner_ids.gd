extends RefCounted

# Dome Keeper 5.0.8 sends a keeper over the network as int(id.lstrip("keeper")), and
# SaveGame only recognises 7-character keeper ids, so the id is "keeper" + one unused digit.
const ID := "keeper9"
const ACTION_MINE := "keeper9_mine"
const MINE_GROUP := "namds_miner_mines"
const TINT := Color(1.0, 0.78, 0.5)
# Set on a tile the blast is about to hit when Bomber Vaulter is on: its drops go straight to the vault.
const VAULT_META := &"namds_miner_vault"
const DOMER_SOURCE := "keeper9domer"


static func spriteframes_path(color: int) -> String:
	return "res://content/keeper/%s/spriteframes-skin0-color%d.tres" % [ID, color]


static func loadout_icon_path(color: int = -1) -> String:
	if color < 0:
		return "res://content/icons/loadout_%s-skin0.png" % ID
	return "res://content/icons/loadout_%s-skin0-color%d.png" % [ID, color]


static func input_processor_path() -> String:
	return "res://content/keeper/%sInputProcessor.gd" % ID.capitalize().replace(" ", "")
