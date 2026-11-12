extends Node

const MOD_DIR := "Namds-Miner"
const LOG_NAME := "Namds-Miner:Main"
const MinerIds := preload("res://mods-unpacked/Namds-Miner/miner_ids.gd")
const Translations := preload("res://mods-unpacked/Namds-Miner/translations.gd")

const ICON_SOURCES := {
	"keeper9mines1": "blastminingtriple",
	"keeper9mines2": "blastminingtriple",
	"keeper9mines3": "blastminingtriple",
	"keeper9range1": "blastminingblast1",
	"keeper9range2": "blastminingblast2",
	"keeper9range3": "blastminingblast3",
	"keeper9power1": "blastminingblast1",
	"keeper9power2": "blastminingblast2",
	"keeper9power3": "blastminingblast3",
	"keeper9fuse1": "blastminingproductiontime1",
	"keeper9fuse2": "blastminingproductiontime1",
	"keeper9detonator": "blastminingimpactdetonation",
	"keeper9vaulter": "condenserautocollect",
	"keeper9domer": "domesupplementelectrifiedsurface2",
	"keeper9cluster1": "blastminingstickycharge",
	"keeper9cluster2": "blastminingstickycharge",
	"keeper9cluster3": "blastminingstickycharge",
	"keeper9clusterex": "blastminingtriple",
}

var mod_dir_path := ""
# take_over_path only lasts while something references the resource.
var _aliased_resources: Array[Resource] = []


func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_dir := mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_extension(ext_dir.path_join("systems/options/Options.gd"))
	ModLoaderMod.install_script_extension(ext_dir.path_join("systems/options/KeyBindingsPanel.gd"))
	ModLoaderMod.install_script_extension(ext_dir.path_join("systems/audio/Audio.gd"))
	ModLoaderMod.install_script_extension(ext_dir.path_join("content/map/Map.gd"))
	ModLoaderMod.install_script_extension(ext_dir.path_join("content/dome/Dome.gd"))

	_register_input_action()
	_add_translations()
	_alias_keeper_resources()
	_alias_upgrade_icons()
	ModLoaderLog.info("Init done", LOG_NAME)


func _ready() -> void:
	add_to_group("mod_init")


func modInit() -> void:
	Data.parseUpgradesYaml(mod_dir_path.path_join("yaml/upgrades.yaml"))
	if Keepers.has_method("register_keeper"):
		Keepers.register_keeper(
			MinerIds.ID,
			load(MinerIds.spriteframes_path(0)),
			load(MinerIds.loadout_icon_path()),
			load(mod_dir_path.path_join("keeper/MinerInputProcessor.gd")),
		)
	else:
		Data.registerKeeper(MinerIds.ID)
		GameWorld.unlockElement(MinerIds.ID)
		Options.includeInputGroup(MinerIds.ID)
	ModLoaderLog.info("Miner keeper registered", LOG_NAME)


func _register_input_action() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	var trigger := InputEventJoypadMotion.new()
	trigger.device = -1
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	var events := [key, trigger]

	# Lives in ProjectSettings too, so "reset key bindings" (load_from_project_settings) keeps it.
	ProjectSettings.set_setting("input/" + MinerIds.ACTION_MINE, {"deadzone": 0.5, "events": events})
	if not InputMap.has_action(MinerIds.ACTION_MINE):
		InputMap.add_action(MinerIds.ACTION_MINE, 0.5)
		for e in events:
			InputMap.action_add_event(MinerIds.ACTION_MINE, e)


func _add_translations() -> void:
	for locale in Translations.TEXTS:
		var t := Translation.new()
		t.locale = locale
		var texts: Dictionary = Translations.TEXTS[locale]
		for key in texts:
			t.add_message(key, texts[key])
		TranslationServer.add_translation(t)


func _alias_keeper_resources() -> void:
	for color in 4:
		var frames: SpriteFrames = load("res://content/keeper/keeper1/spriteframes-skin0-color%d.tres" % color).duplicate()
		_alias(frames, MinerIds.spriteframes_path(color))

		var icon := _tinted_texture("res://content/icons/loadout_keeper1-skin0-color%d.png" % color)
		_alias(icon, MinerIds.loadout_icon_path(color))
		if color == 0:
			_alias(_tinted_texture("res://content/icons/loadout_keeper1-skin0-color0.png"), MinerIds.loadout_icon_path())

	_alias(_tinted_texture("res://content/icons/keeper1.png"), "res://content/icons/%s.png" % MinerIds.ID)

	var processor: Script = load(mod_dir_path.path_join("keeper/MinerInputProcessor.gd"))
	_alias(processor, MinerIds.input_processor_path())


func _alias_upgrade_icons() -> void:
	for id in ICON_SOURCES:
		var source := "res://content/icons/%s.png" % ICON_SOURCES[id]
		if not ResourceLoader.exists(source):
			ModLoaderLog.warning("Missing icon source " + source, LOG_NAME)
			continue
		_alias(load(source).duplicate(), "res://content/icons/%s.png" % id)


func _alias(resource: Resource, path: String) -> void:
	resource.take_over_path(path)
	_aliased_resources.append(resource)


func _tinted_texture(path: String) -> Texture2D:
	var image: Image = load(path).get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.0:
				image.set_pixel(x, y, c * MinerIds.TINT)
	return ImageTexture.create_from_image(image)
