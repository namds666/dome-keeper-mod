extends Node2D

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const MinerBlast := preload("res://mods-unpacked/Namds-Miner/keeper/MinerBlast.gd")
const MINE_FRAMES := "res://content/gadgets/blastMining/Mine_spriteframes.tres"
const EXPLOSION := "res://content/gadgets/blastMining/Explosion.tscn"
# Bomber Cluster: tier 1 is the placed mine, tier 2 its clusters, tier 3 (Cluster - Ex) theirs.
const LAST_TIER := 3
const TIER_SCALE: Array[float] = [1.0, 1.0, 0.75, 0.55]
const CLUSTER_RADIUS := 2
const THROW_TIME := 0.3
const THROW_ARC := 14.0

var coord: Vector2
var ownerPlayerId: String
var teamId: String
var fuse := 2.5
var blastRange := 2
var blastDamage := 6.0
var vaulter := false
var clusters := 0
var clusterEx := false
var tier := 1
var exploded := false

var _remaining := 0.0
var _sprite: AnimatedSprite2D


func isCluster() -> bool:
	return tier > 1


func _ready() -> void:
	add_to_group(MinerIds.MINE_GROUP)
	z_index = 23
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(MINE_FRAMES)
	_sprite.self_modulate = MinerIds.TINT
	_sprite.scale = Vector2.ONE * TIER_SCALE[tier]
	add_child(_sprite)
	_sprite.play("activated_0")
	_remaining = fuse
	Style.init(self)


func _process(delta: float) -> void:
	if exploded or GameWorld.paused:
		return
	_remaining -= delta
	_sprite.speed_scale = 0.3 + 1.7 * clamp(1.0 - _remaining / max(fuse, 0.01), 0.0, 1.0)
	if _remaining <= 0.0:
		_explode()


func detonate(delay: float = 0.0) -> void:
	if exploded:
		return
	_remaining = min(_remaining, delay)


func throwFrom(from: Vector2) -> void:
	var target := position
	position = from
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", target, THROW_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(t: float): _sprite.offset.y = -sin(PI * t) * THROW_ARC / _sprite.scale.y, 0.0, 1.0, THROW_TIME)


func _explode() -> void:
	exploded = true
	remove_from_group(MinerIds.MINE_GROUP)
	var map := get_parent()

	var bang = load(EXPLOSION).instantiate()
	bang.position = position
	bang.shake_strength = 120 if tier == 1 else 50
	map.add_child(bang)

	var blast := MinerBlast.new()
	blast.center = Vector2i(coord)
	blast.blastRange = blastRange
	blast.blastDamage = blastDamage
	blast.teamId = teamId
	blast.vaulter = vaulter
	map.add_child(blast)

	_spawn_clusters(map)
	queue_free()


func _spawn_clusters(map) -> void:
	var count := 0
	if tier == 1:
		count = clusters
	elif tier == 2 and clusterEx:
		count = clusters / 2
	if count <= 0 or tier >= LAST_TIER:
		return

	for cell in _cluster_cells(map, count):
		var child = get_script().new()
		child.coord = Vector2(cell)
		child.ownerPlayerId = ownerPlayerId
		child.teamId = teamId
		child.fuse = fuse
		child.blastRange = max(1, blastRange - 1)
		child.blastDamage = blastDamage
		child.vaulter = vaulter
		child.clusters = clusters
		child.clusterEx = clusterEx
		child.tier = tier + 1
		child.position = map.getTilePos(Vector2(cell))
		map.add_child(child)
		child.throwFrom(position)


# Open cells near the blast, off its cross first so the clusters outlive the blast that threw
# them. Seeded by the cell so every peer picks the same cells.
func _cluster_cells(map, count: int) -> Array:
	var center := Vector2i(coord)
	var offCross: Array[Vector2i] = []
	var onCross: Array[Vector2i] = []
	var taken := {}
	for mine in get_tree().get_nodes_in_group(MinerIds.MINE_GROUP):
		taken[Vector2i(mine.coord)] = true
	for dy in range(-CLUSTER_RADIUS, CLUSTER_RADIUS + 1):
		for dx in range(-CLUSTER_RADIUS, CLUSTER_RADIUS + 1):
			var cell := center + Vector2i(dx, dy)
			if cell == center or taken.has(cell) or not _is_open(map, cell):
				continue
			if dx != 0 and dy != 0:
				offCross.append(cell)
			else:
				onCross.append(cell)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(center.x, center.y, tier))
	_shuffle(offCross, rng)
	_shuffle(onCross, rng)
	var cells: Array = []
	cells.append_array(offCross)
	cells.append_array(onCross)
	return cells.slice(0, count)


func _is_open(map, cell: Vector2i) -> bool:
	var key := Vector2(cell)
	return not map.tiles.has(key) and map.tileData.get_resourcev(key) == Data.TILE_EMPTY


func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap
