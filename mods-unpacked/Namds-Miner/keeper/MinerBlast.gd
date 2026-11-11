extends Node2D

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const CHAIN_DELAY := 0.06
const STEP_TIME := 0.05
const FLAME_LIFE := 0.45
const FLAME_OUTER := Color(1.0, 0.45, 0.1)
const FLAME_INNER := Color(1.0, 0.9, 0.45)
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var center: Vector2i
var blastRange := 2
var blastDamage := 6.0
var teamId: String

var _arms: Array[Dictionary] = []
var _flames: Array[Dictionary] = []
var _stepTimer := 0.0


func _ready() -> void:
	z_index = 24
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_burn(center, Vector2i.ZERO)
	for dir in DIRECTIONS:
		_arms.append({"dir": dir, "step": 1, "done": false, "waited": false})


func _process(delta: float) -> void:
	if GameWorld.paused:
		return
	_stepTimer += delta
	while _stepTimer >= STEP_TIME:
		_stepTimer -= STEP_TIME
		for arm in _arms:
			if not arm.done:
				_advance(arm)

	for flame in _flames:
		flame.age += delta
	_flames = _flames.filter(func(f): return f.age < FLAME_LIFE)
	queue_redraw()
	if _flames.is_empty() and _arms.all(func(a): return a.done):
		queue_free()


func _advance(arm: Dictionary) -> void:
	if arm.step > blastRange or not is_instance_valid(Level.map):
		arm.done = true
		return
	var cell: Vector2i = center + arm.dir * arm.step
	var key := Vector2(cell)
	var map = Level.map

	if map.tiles.has(key):
		var tile = map.tiles[key]
		if not Data.isDestructable(tile):
			arm.done = true
			return
		_burn(cell, arm.dir)
		var damage := blastDamage
		if tile.maxDamagePerHit >= 0:
			damage = min(damage, tile.maxDamagePerHit)
		var survives: bool = tile.health > damage
		if multiplayer.is_server():
			tile.exploded = true
			tile.hit(Vector2(arm.dir), blastDamage, teamId, MinerIds.ID)
		if survives:
			arm.done = true
		else:
			arm.step += 1
		return

	# A broken tile's neighbour is revealed a moment after it breaks; give it one step.
	if map.tileData.get_resourcev(key) != Data.TILE_EMPTY:
		if arm.waited:
			arm.done = true
		else:
			arm.waited = true
		return

	arm.waited = false
	_burn(cell, arm.dir)
	arm.step += 1


func _burn(cell: Vector2i, dir: Vector2i) -> void:
	_flames.append({"pos": Level.map.getTilePos(Vector2(cell)), "dir": dir, "age": 0.0})
	for mine in get_tree().get_nodes_in_group(MinerIds.MINE_GROUP):
		if mine.coord == Vector2(cell):
			mine.detonate(CHAIN_DELAY)


func _draw() -> void:
	var size := float(GameWorld.TILE_SIZE)
	for flame in _flames:
		var t: float = flame.age / FLAME_LIFE
		var fade := 1.0 - t * t
		var outer := Vector2(size, size)
		var inner := Vector2(size * 0.5, size * 0.5)
		if flame.dir.x != 0:
			outer.y = size * 0.75
			inner = Vector2(size, size * 0.3)
		elif flame.dir.y != 0:
			outer.x = size * 0.75
			inner = Vector2(size * 0.3, size)
		outer *= lerp(1.0, 0.6, t)
		inner *= lerp(1.0, 0.5, t)
		draw_rect(Rect2(flame.pos - outer * 0.5, outer), Color(FLAME_OUTER, 0.85 * fade))
		draw_rect(Rect2(flame.pos - inner * 0.5, inner), Color(FLAME_INNER, fade))
