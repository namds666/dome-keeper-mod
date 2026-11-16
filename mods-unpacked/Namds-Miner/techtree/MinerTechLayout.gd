extends RefCounted

# The Miner tree is a grid: an upgrade sits in its predecessor's row and a second successor
# opens the next free row, so every chain is one straight horizontal line.
# A script extension of TechTrack.gd does not take: TechTree.gd preloads TechTrack.tscn, so the
# scene holds the vanilla script before any mod loads. The mod lays the track out once it is built.

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const EMPTY_TECH := preload("res://content/techtree/EmptyTech.tscn")
const ROW_SEPARATION := 4


static func isMinerTrack(track) -> bool:
	return track.rootTechId == MinerIds.ID or track.rootTechId.ends_with("." + MinerIds.ID)


static func layout(track) -> void:
	if not track.techs.has(track.rootTechId):
		return
	var rowOf := {track.rootTechId: -1}
	var rowCount := [0]
	for child in track.techs[track.rootTechId].children:
		_place(track, child, _newRow(rowCount), rowOf, rowCount)

	var boxes: Array = track.find_child("Tiers").get_children().filter(func(b): return not b.is_queued_for_deletion())
	for column in range(1, mini(boxes.size(), track.panelsByTier.size())):
		var box: VBoxContainer = boxes[column]
		var byRow := {}
		for child in box.get_children():
			box.remove_child(child)
			if child is TechPanel:
				if not rowOf.has(child.techId):
					rowOf[child.techId] = _newRow(rowCount)
				byRow[rowOf[child.techId]] = child
			else:
				child.queue_free()
		if byRow.is_empty():
			continue

		box.alignment = BoxContainer.ALIGNMENT_BEGIN
		box.add_theme_constant_override("separation", ROW_SEPARATION)
		var panels := []
		for row in int(byRow.keys().max()) + 1:
			if byRow.has(row):
				box.add_child(byRow[row])
				panels.append(byRow[row])
			else:
				box.add_child(EMPTY_TECH.instantiate())
		track.panelsByTier[column] = panels
		track.topTechPanelsByTier[column] = panels.front()
		track.bottomTechPanelsByTier[column] = panels.back()
		if column == boxes.size() - 1:
			track.rightTechPanels = panels
	track.dirty = true


static func _place(track, techId: String, row: int, rowOf: Dictionary, rowCount: Array) -> void:
	rowOf[techId] = row
	var continuesRow := true
	for child in track.techs[techId].children:
		if rowOf.has(child):
			continue
		_place(track, child, row if continuesRow else _newRow(rowCount), rowOf, rowCount)
		continuesRow = false


static func _newRow(rowCount: Array) -> int:
	rowCount[0] += 1
	return rowCount[0] - 1
