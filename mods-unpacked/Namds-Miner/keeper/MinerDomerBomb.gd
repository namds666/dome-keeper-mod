extends Node2D

# Bomber Domer: a mine thrown from the dome onto the monster that attacked it.

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const MINE_FRAMES := "res://content/gadgets/blastMining/Mine_spriteframes.tres"
const EXPLOSION := "res://content/gadgets/blastMining/Explosion.tscn"
const FLIGHT_TIME := 0.4
const ARC_HEIGHT := 36.0
const SPIN_SPEED := 14.0
const STUN := 2.0

var target
var damage := 40.0
var start: Vector2

var _end: Vector2
var _progress := 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	z_index = 26
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(MINE_FRAMES)
	_sprite.self_modulate = MinerIds.TINT
	add_child(_sprite)
	_sprite.play("activated_0")
	_sprite.speed_scale = 2.0
	global_position = start
	_end = target.getCenter() if is_instance_valid(target) else start


func _process(delta: float) -> void:
	if GameWorld.paused:
		return
	if is_instance_valid(target):
		_end = target.getCenter()
	_progress = min(_progress + delta / FLIGHT_TIME, 1.0)
	var pos := start.lerp(_end, _progress)
	pos.y -= sin(PI * _progress) * ARC_HEIGHT
	global_position = pos
	_sprite.rotation += delta * SPIN_SPEED
	if _progress >= 1.0:
		_explode()


func _explode() -> void:
	var bang = load(EXPLOSION).instantiate()
	bang.shake_strength = 40
	get_parent().add_child(bang)
	bang.global_position = _end
	if is_instance_valid(target) and target.alive():
		target.hit(MinerIds.DOMER_SOURCE, damage, STUN)
	queue_free()
