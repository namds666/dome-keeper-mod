extends "res://content/keeper/Keeper1InputProcessor.gd"

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const HOLD_INTERVAL := 0.2

var _mineKeyDown := false
var _holdTime := 0.0


func _process(delta):
	super._process(delta)
	if not _mineKeyDown or GameWorld.paused or not is_instance_valid(keeper):
		return
	_holdTime += delta
	if _holdTime >= HOLD_INTERVAL:
		_holdTime -= HOLD_INTERVAL
		keeper.mineHold()


func clearInput():
	super.clearInput()
	_mineKeyDown = false


func keeperButtonEvent(event, handled: bool):
	super.keeperButtonEvent(event, handled)
	if keeper and not GameWorld.paused and justPressed(event, MinerIds.ACTION_MINE):
		if not _mineKeyDown:
			_holdTime = 0.0
		_mineKeyDown = true
		keeper.mineHit()
	elif released(event, MinerIds.ACTION_MINE):
		_mineKeyDown = false
