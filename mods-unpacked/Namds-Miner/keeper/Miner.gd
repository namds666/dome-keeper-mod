extends "res://content/keeper/keeper1/Keeper1.gd"

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const MinerMine := preload("res://mods-unpacked/Namds-Miner/keeper/MinerMine.gd")


# The device selection and loadout stages only seed keeper data for vanilla keepers.
const DEFAULT_VALUES := {
	"keeper.speedbuff": 0.0,
	"keeper.drillbuff": 0.0,
	"keeper.zoominmine": 0.0,
	"keeper.additionalupwardsspeed": 0.0,
	"keeper1.drillstrength": 2,
	"keeper1.maxspeed": 52,
	"keeper1.slowdownrecovery": 4,
	"keeper1.acceleration": 5,
	"keeper1.deceleration": 4,
	"keeper1.speedlosspercarry": 5.7,
	"keeper1.jetpackstage": 0,
	"keeper1.tileknockback": 7,
	"keeper1.tilehitcooldown": 0.35,
	"keeper1.hardtilesmodifier": 1.0,
	"keeper1.destroyindestructibletiles": false,
	"keeper9.maxmines": 2,
	"keeper9.blastrange": 2,
	"keeper9.blastdamage": 6,
	"keeper9.fuse": 2.5,
	"keeper9.detonator": false,
}
const MENU_MAX_SPEED := 180

var _seeded := false


func init():
	_seedMissingValues()
	keeper_sprite.self_modulate = MinerIds.TINT
	super.init()


func _physics_process(delta):
	if not _seeded and playerId != "":
		_seedMissingValues()
	super._physics_process(delta)


func _seedMissingValues() -> void:
	_seeded = true
	for key in DEFAULT_VALUES:
		var fullKey: String = playerId + "." + key
		if not Data.values.has(fullKey):
			Data.values[fullKey] = DEFAULT_VALUES[key]
	if not StageManager.isInLevel():
		Data.values[playerId + ".keeper1.maxspeed"] = MENU_MAX_SPEED


# The Miner only digs with mines.
func drill_check() -> void:
	pass


func mineHit() -> void:
	if disabled or killed or isInsideDome or isInsideStation or not is_instance_valid(Level.map):
		return
	if not is_multiplayer_authority():
		return

	var coord := Vector2(Level.map.getTileCoord(global_position))
	var placed := _placedMines()
	var standingOnMine := placed.any(func(m): return m.coord == coord)
	var outOfMines := placed.size() >= int(Data.of(playerId + ".keeper9.maxmines"))

	if standingOnMine or outOfMines:
		if Data.ofOr(playerId + ".keeper9.detonator", false) and placed.size() > 0:
			synchronizer.network_rpc(detonateAll, true)
		return

	synchronizer.network_rpc(placeMine.bind(coord), true)


@rpc("reliable")
func placeMine(coord: Vector2) -> void:
	if not is_instance_valid(Level.map):
		return
	var mine := MinerMine.new()
	mine.coord = coord
	mine.ownerPlayerId = playerId
	mine.teamId = teamId
	mine.fuse = Data.of(playerId + ".keeper9.fuse")
	mine.blastRange = int(Data.of(playerId + ".keeper9.blastrange"))
	mine.blastDamage = Data.of(playerId + ".keeper9.blastdamage")
	Level.map.add_child(mine)
	mine.position = Level.map.getTilePos(coord)


@rpc("reliable")
func detonateAll() -> void:
	for mine in _placedMines():
		mine.detonate()


func _placedMines() -> Array:
	return get_tree().get_nodes_in_group(MinerIds.MINE_GROUP).filter(
		func(m): return m.ownerPlayerId == playerId and not m.exploded
	)
