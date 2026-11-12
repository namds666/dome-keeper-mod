extends Node2D

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const MinerBlast := preload("res://mods-unpacked/Namds-Miner/keeper/MinerBlast.gd")
const MINE_FRAMES := "res://content/gadgets/blastMining/Mine_spriteframes.tres"
const EXPLOSION := "res://content/gadgets/blastMining/Explosion.tscn"

var coord: Vector2
var ownerPlayerId: String
var teamId: String
var fuse := 2.5
var blastRange := 2
var blastDamage := 6.0
var vaulter := false
var exploded := false

var _remaining := 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group(MinerIds.MINE_GROUP)
	z_index = 23
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(MINE_FRAMES)
	_sprite.self_modulate = MinerIds.TINT
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


func _explode() -> void:
	exploded = true
	remove_from_group(MinerIds.MINE_GROUP)
	var map := get_parent()

	var bang = load(EXPLOSION).instantiate()
	bang.position = position
	bang.shake_strength = 120
	map.add_child(bang)

	var blast := MinerBlast.new()
	blast.center = Vector2i(coord)
	blast.blastRange = blastRange
	blast.blastDamage = blastDamage
	blast.teamId = teamId
	blast.vaulter = vaulter
	map.add_child(blast)

	queue_free()

