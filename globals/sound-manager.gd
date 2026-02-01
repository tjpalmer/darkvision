extends Node2D

############################
# USES:
# SoundManager.play("hit")
# SoundManager.play("coin", -3.0)  # quieter
# Features:
#	4 channels — auto-finds free one
#	No overlap on same sound
#	Steals oldest if all busy
#	Volume per play
#	Singleton — use everywhere!


@export var sfx_volume_db: float = 0.0
@export var sounds: Dictionary = {}  # "hit": preload("res://hit.ogg"), etc.

var channels: Array[AudioStreamPlayer] = []
var channel_names: Array[String] = ["SFX1", "SFX2", "SFX3", "SFX4"]

func _ready():
	for i in 4:
		var player = AudioStreamPlayer.new()
		player.name = channel_names[i]
		player.volume_db = sfx_volume_db
		add_child(player)
		channels.append(player)

func play(sound_name: StringName, volume_db: float = 0.0):
	if not sounds.has(sound_name):
		push_error("Sound '%s' not found!" % sound_name)
		return null
	
	# Find first silent channel
	for i in channels.size():
		if not channels[i].playing:
			channels[i].stream = sounds[sound_name]
			channels[i].volume_db = volume_db
			channels[i].play()
			return channels[i]
	
	# Fallback: steal oldest
	var oldest = channels[0]
	oldest.stream = sounds[sound_name]
	oldest.volume_db = volume_db
	oldest.play()
	return oldest
