extends "res://content/techtree/techtrack/TechTrack.gd"

const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const EMPTY_TECH := preload("res://content/techtree/EmptyTech.tscn")
const ROW_SEPARATION := 4

var _rowOf := {}
var _rowCount := 0


# The Miner tree is a grid: an upgrade sits in its predecessor's row and a second successor
# opens the next free row, so every chain is one straight horizontal line.
func build(techsByTier: Array, focusListener: TechTree):
	super(techsByTier, focusListener)
	if rootTechId == MinerIds.ID or rootTechId.ends_with("." + MinerIds.ID):
		_layout_rows()


func _layout_rows() -> void:
	_rowOf = {rootTechId: -1}
	_rowCount = 0
	for child in techs[rootTechId].children:
		_place(child, _new_row())

	var boxes := find_child("Tiers").get_children().filter(func(b): return not b.is_queued_for_deletion())
	for column in range(1, boxes.size()):
		var box: VBoxContainer = boxes[column]
		var byRow := {}
		for child in box.get_children():
			box.remove_child(child)
			if child is TechPanel:
				if not _rowOf.has(child.techId):
					_rowOf[child.techId] = _new_row()
				byRow[_rowOf[child.techId]] = child
			else:
				child.queue_free()
		if byRow.is_empty():
			continue

		box.alignment = BoxContainer.ALIGNMENT_BEGIN
		box.add_theme_constant_override("separation", ROW_SEPARATION)
		var panels := []
		for row in byRow.keys().max() + 1:
			if byRow.has(row):
				box.add_child(byRow[row])
				panels.append(byRow[row])
			else:
				box.add_child(EMPTY_TECH.instantiate())
		panelsByTier[column] = panels
		topTechPanelsByTier[column] = panels.front()
		bottomTechPanelsByTier[column] = panels.back()
		if column == boxes.size() - 1:
			rightTechPanels = panels
	dirty = true


func _place(techId: String, row: int) -> void:
	_rowOf[techId] = row
	var continuesRow := true
	for child in techs[techId].children:
		if _rowOf.has(child):
			continue
		_place(child, row if continuesRow else _new_row())
		continuesRow = false


func _new_row() -> int:
	_rowCount += 1
	return _rowCount - 1
