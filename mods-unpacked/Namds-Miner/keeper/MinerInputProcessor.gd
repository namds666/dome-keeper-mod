extends "res://content/keeper/Keeper1InputProcessor.gd"

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")


func keeperButtonEvent(event, handled: bool):
	super.keeperButtonEvent(event, handled)
	if keeper and not GameWorld.paused and justPressed(event, MinerIds.ACTION_MINE):
		keeper.mineHit()
