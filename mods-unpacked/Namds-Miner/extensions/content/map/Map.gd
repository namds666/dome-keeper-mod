extends "res://content/map/Map.gd"

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const VAULTED_RISE := 22.0
const VAULTED_TIME := 0.7


# Bomber Vaulter: a resource tile broken by a Miner blast pays straight into the vault
# instead of spawning drops to carry home.
func spawnDrop(tile: Tile, teamId: String) -> void:
	if not tile.has_meta(MinerIds.VAULT_META) or teamId == "":
		super(tile, teamId)
		return
	Data.changeByInt(teamId + ".inventory." + tile.type, 1)
	Data.changeByInt("inventory.total" + tile.type, 1)
	GameWorld.incrementRunStat("resources_mined", teamId)
	_show_vaulted(tile.type, to_local(tile.global_position))


func _show_vaulted(type: String, at: Vector2) -> void:
	var path := "res://content/icons/icon_%s.png" % type
	if not ResourceLoader.exists(path):
		return
	var icon := Sprite2D.new()
	icon.texture = load(path)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.z_index = 25
	icon.position = at + Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
	add_child(icon)
	var tween := icon.create_tween().set_parallel()
	tween.tween_property(icon, "position:y", icon.position.y - VAULTED_RISE, VAULTED_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "modulate:a", 0.0, VAULTED_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(icon.queue_free)
