extends SceneTree

# Headless Workshop uploader. Run from the repo root with Steam running:
#   .tools/godot/macos_tools.app/Contents/MacOS/Godot --headless --path . --script workshop/upload.gd

const APP_ID := 1637320
const VISIBILITY_PUBLIC := 0
const ROOT := "res://"
const ITEM_ID_FILE := "res://workshop/item_id.txt"

var steam
var handle := 0
var progress_timer := 0.0


func _initialize() -> void:
	steam = Engine.get_singleton("Steam")
	var init: Dictionary = steam.steamInitEx(APP_ID, false)
	if init["status"] != 0:
		_fail("Steam init failed: %s" % init)
		return
	var item_id := _read_item_id()
	if item_id == 0:
		steam.item_created.connect(_on_item_created, CONNECT_ONE_SHOT)
		steam.createItem(APP_ID, 0)
		print("Creating workshop item...")
	else:
		_update(item_id, false)


func _process(delta: float) -> bool:
	steam.run_callbacks()
	if handle != 0:
		progress_timer += delta
		if progress_timer > 2.0:
			progress_timer = 0.0
			var p: Dictionary = steam.getItemUpdateProgress(handle)
			print("Upload progress: %s / %s" % [p.get("processed", 0), p.get("total", 0)])
	return false


func _on_item_created(result: int, file_id: int, accept_tos: bool) -> void:
	if result != 1:
		_fail("createItem failed, result %d" % result)
		return
	var f := FileAccess.open(ITEM_ID_FILE, FileAccess.WRITE)
	f.store_line(str(file_id))
	f.close()
	print("Created workshop item %d" % file_id)
	if accept_tos:
		print("NOTE: the Steam account must accept the Workshop legal agreement.")
	_update(file_id, true)


func _update(file_id: int, first: bool) -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "mods-unpacked/Namds-Miner/manifest.json"))
	var version: String = manifest["version_number"]
	var content_dir := ProjectSettings.globalize_path(ROOT + ".tools/dist/Namds-Miner-%s" % version)
	if not DirAccess.dir_exists_absolute(content_dir):
		_fail("Missing %s, run workshop/package.py first" % content_dir)
		return

	handle = steam.startItemUpdate(APP_ID, file_id)
	steam.setItemTitle(handle, "Miner - Bomberman-style mining keeper")
	steam.setItemDescription(handle, FileAccess.get_file_as_string(ROOT + "workshop/description.txt"))
	steam.setItemContent(handle, content_dir)
	steam.setItemPreview(handle, ProjectSettings.globalize_path(ROOT + "workshop/preview.png"))
	steam.setItemTags(handle, ["Keeper"])
	steam.setItemVisibility(handle, VISIBILITY_PUBLIC)
	steam.item_updated.connect(_on_item_updated, CONNECT_ONE_SHOT)
	steam.submitItemUpdate(handle, "v%s" % version)
	print("Uploading v%s from %s" % [version, content_dir])


func _on_item_updated(result: int, needs_to_accept_agreement: bool, file_id: int) -> void:
	handle = 0
	if file_id == 0:
		file_id = _read_item_id()
	if needs_to_accept_agreement:
		print("NOTE: accept the Workshop legal agreement: https://steamcommunity.com/sharedfiles/workshoplegalagreement")
	if result != 1:
		_fail("submitItemUpdate failed, result %d" % result)
		return
	print("UPLOADED https://steamcommunity.com/sharedfiles/filedetails/?id=%d" % file_id)
	quit(0)


func _read_item_id() -> int:
	if not FileAccess.file_exists(ITEM_ID_FILE):
		return 0
	return int(FileAccess.get_file_as_string(ITEM_ID_FILE).strip_edges())


func _fail(message: String) -> void:
	push_error(message)
	print("FAILED: " + message)
	quit(1)
