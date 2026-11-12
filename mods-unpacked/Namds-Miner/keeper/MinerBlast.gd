extends Node2D

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const CHAIN_DELAY := 0.06
const STEP_TIME := 0.05
const FLAME_LIFE := 0.45
const FLAME_OUTER := Color(1.0, 0.45, 0.1)
const FLAME_INNER := Color(1.0, 0.9, 0.45)
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
# Beam half width in tiles at the centre; it narrows along the arm to TIP_RATIO at the tip.
const BEAM_HALF_WIDTH := 0.42
const TIP_RATIO := 0.2
const CORE_RATIO := 0.45

var center: Vector2i
var blastRange := 2
var blastDamage := 6.0
var teamId: String
var vaulter := false

var _arms: Array[Dictionary] = []
var _centerAge := 0.0
var _stepTimer := 0.0


func _ready() -> void:
	z_index = 24
	_detonate_mines_at(center)
	for dir in DIRECTIONS:
		_arms.append({"dir": dir, "step": 1, "done": false, "waited": false, "cells": []})


func _process(delta: float) -> void:
	if GameWorld.paused:
		return
	_stepTimer += delta
	while _stepTimer >= STEP_TIME:
		_stepTimer -= STEP_TIME
		for arm in _arms:
			if not arm.done:
				_advance(arm)

	_centerAge += delta
	var burning := _centerAge < FLAME_LIFE
	for arm in _arms:
		for cell in arm.cells:
			cell.age += delta
			burning = burning or cell.age < FLAME_LIFE
	queue_redraw()
	if not burning and _arms.all(func(a): return a.done):
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
		_burn(arm, cell)
		var damage := blastDamage
		if tile.maxDamagePerHit >= 0:
			damage = min(damage, tile.maxDamagePerHit)
		var survives: bool = tile.health > damage
		if multiplayer.is_server():
			tile.exploded = true
			if vaulter:
				tile.set_meta(MinerIds.VAULT_META, true)
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
	_burn(arm, cell)
	arm.step += 1


func _burn(arm: Dictionary, cell: Vector2i) -> void:
	arm.cells.append({"dist": float(arm.step), "age": 0.0})
	_detonate_mines_at(cell)


func _detonate_mines_at(cell: Vector2i) -> void:
	for mine in get_tree().get_nodes_in_group(MinerIds.MINE_GROUP):
		if mine.coord == Vector2(cell):
			mine.detonate(CHAIN_DELAY)


func _draw() -> void:
	if not is_instance_valid(Level.map):
		return
	var tileSize := float(GameWorld.TILE_SIZE)
	var origin: Vector2 = Level.map.getTilePos(Vector2(center))
	for arm in _arms:
		_draw_arm(arm, origin, tileSize, FLAME_OUTER, 0.85, 1.0)
	for arm in _arms:
		_draw_arm(arm, origin, tileSize, FLAME_INNER, 1.0, CORE_RATIO)

	var centerRadius := BEAM_HALF_WIDTH * tileSize * _shrink(_centerAge)
	if centerRadius > 0.5:
		draw_circle(origin, centerRadius, Color(FLAME_OUTER, 0.85 * _fade(_centerAge)))
		draw_circle(origin, centerRadius * CORE_RATIO, Color(FLAME_INNER, _fade(_centerAge)))


# One continuous beam per arm: the width tapers from the centre to the tip and every
# point shrinks only across the axis as it ages, so the arm never splits into blocks.
func _draw_arm(arm: Dictionary, origin: Vector2, tileSize: float, color: Color, alpha: float, widthRatio: float) -> void:
	var cells: Array = arm.cells
	if cells.is_empty():
		return
	var reach: float = cells[-1].dist + 0.5
	var samples := [{"dist": 0.0, "age": _centerAge}]
	samples.append_array(cells)
	samples.append({"dist": reach, "age": cells[-1].age})

	var axis := Vector2(arm.dir)
	var across := Vector2(-axis.y, axis.x)
	var points: Array[Vector2] = []
	var halfWidths: Array[float] = []
	var colors: Array[Color] = []
	for s in samples:
		var taper: float = lerp(1.0, TIP_RATIO, s.dist / reach)
		points.append(origin + axis * s.dist * tileSize)
		halfWidths.append(BEAM_HALF_WIDTH * tileSize * widthRatio * taper * _shrink(s.age))
		colors.append(Color(color, alpha * _fade(s.age)))

	for i in points.size() - 1:
		if halfWidths[i] < 0.1 and halfWidths[i + 1] < 0.1:
			continue
		draw_primitive(
			PackedVector2Array([
				points[i] + across * halfWidths[i],
				points[i + 1] + across * halfWidths[i + 1],
				points[i + 1] - across * halfWidths[i + 1],
				points[i] - across * halfWidths[i],
			]),
			PackedColorArray([colors[i], colors[i + 1], colors[i + 1], colors[i]]),
			PackedVector2Array()
		)


func _shrink(age: float) -> float:
	return 1.0 - clampf(age / FLAME_LIFE, 0.0, 1.0)


func _fade(age: float) -> float:
	var t := clampf(age / FLAME_LIFE, 0.0, 1.0)
	return 1.0 - t * t
