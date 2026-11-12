extends "res://content/dome/Dome.gd"

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const DomerBomb := preload("res://mods-unpacked/Namds-Miner/keeper/MinerDomerBomb.gd")
# One bomb per monster per this many seconds, so drillers that hit every frame don't get a stream.
const DOMER_COOLDOWN_MS := 1500
# A projectile only knows where it was fired from; its shooter is the monster closest to that point.
const SHOOTER_SEARCH_RADIUS := 120.0
const THROW_HEIGHT := 40.0

var _domerReadyAt := {}


func requestProjectileDamage(rawDamage: int, pos: Vector2, requester):
	super(rawDamage, pos, requester)
	if "origin" in requester:
		_bomber_domer(_monster_near(requester.origin))


func requestMeleeDamage(rawDamage: int, pos: Vector2, requester):
	super(rawDamage, pos, requester)
	_bomber_domer(requester)


func requestBeamDamage(rawDamage: int, pos: Vector2, requester):
	super(rawDamage, pos, requester)
	_bomber_domer(requester)


func _bomber_domer(monster) -> void:
	if not multiplayer.is_server() or not is_instance_valid(monster) or not monster is Monster:
		return
	if not monster.alive() or not monster.canBeHit():
		return
	var damage := _domer_damage()
	if damage <= 0.0:
		return
	var id: int = monster.get_instance_id()
	var now := Time.get_ticks_msec()
	if now < _domerReadyAt.get(id, 0):
		return
	_domerReadyAt[id] = now + DOMER_COOLDOWN_MS

	var bomb := DomerBomb.new()
	bomb.target = monster
	bomb.damage = damage
	bomb.start = global_position + Vector2(0, -THROW_HEIGHT)
	get_parent().add_child(bomb)


func _domer_damage() -> float:
	var best := 0.0
	for keeper in Keepers.getAll():
		if keeper.techId != MinerIds.ID or keeper.teamId != teamId:
			continue
		if Data.ofOr(keeper.playerId + ".keeper9.domer", false):
			best = max(best, float(Data.ofOr(keeper.playerId + ".keeper9.domerdamage", 0)))
	return best


func _monster_near(pos: Vector2):
	var closest = null
	var closestDistance := SHOOTER_SEARCH_RADIUS
	for monster in get_tree().get_nodes_in_group(teamId + "-monster"):
		if not monster is Monster or not monster.alive():
			continue
		var distance: float = pos.distance_to(monster.getCenter())
		if distance < closestDistance:
			closest = monster
			closestDistance = distance
	return closest
