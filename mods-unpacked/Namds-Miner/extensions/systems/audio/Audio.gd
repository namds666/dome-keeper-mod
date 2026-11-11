extends "res://systems/audio/Audio.gd"

# The Miner has no music of its own; it plays the Engineer's.


func addTracksForTechId(techId: String) -> void:
	super.addTracksForTechId(_musicId(techId))


func get_closest_keeperId_or_music_override(position) -> String:
	return _musicId(super.get_closest_keeperId_or_music_override(position))


func _musicId(techId: String) -> String:
	return "keeper1" if techId == "keeper9" else techId
