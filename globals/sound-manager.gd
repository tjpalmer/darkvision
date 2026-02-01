extends Node2D

############################
# USES:
# SoundManager.play("hit")
# SoundManager.play("coin", -3.0)  # quieter
# SoundManager.is_playing("bgm_1") # returns true if currenly playing or false if not
# Features:
#	4 channels — auto-finds free one
#	No overlap on same sound
#	Steals oldest if all busy
#	Volume per play
#	Singleton — use everywhere!


@export var sfx_volume_db: float = 0.0

var sounds: Dictionary = {  # "hit": preload("res://hit.ogg"), etc.
	"item_pickup": preload("res://audio/sfx/item pickup.wav"),
	"footsteps": preload("res://audio/sfx/footsteps.wav"),
	"heartbeat_single": preload("res://audio/sfx/heartbeat_single.wav"),
	"chest_open": preload("res://audio/sfx/chest-open.mp3"),
	"combat_bgm": preload("res://audio/bgm/combat.ogg"),
	"combat_bgm_alt": preload("res://audio/bgm/combat-alt.ogg"),
	"whoosh_attack": preload("res://audio/sfx/woosh-attack.wav"),
	"block_clang": preload("res://audio/sfx/block-clang.wav"),
	"player_hurt": preload("res://audio/sfx/player-hurt.wav"),
} 

var channels: Array[AudioStreamPlayer] = []


func log():
	pass
	for c in channels:
		print(c, " playing=", c.playing, " vol=", c.volume_db)

	print("-------")
	
	
func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_volume_db
		add_child(p)
		channels.append(p)


func play(sound_name: StringName, volume_db: float = 0.0, loop: bool = false):
	if not sounds.has(sound_name):
		push_error("Sound '%s' not found!" % sound_name)
		return null

	var stream: AudioStream = sounds[sound_name]

	if "loop" in stream:
		stream.loop = loop
		
	for c in channels:
		if not c.playing:
			c.volume_db = 0.0 # reset all channels not currently playing

	for c in channels:
		if not c.playing:
			c.stream = stream
			c.volume_db = volume_db  # <- hard reset
			print("PLAY", sound_name, "on", c, "vol=", c.volume_db)
			c.play()
			return c

	var first := channels[0]
	first.stream = stream
	first.volume_db = volume_db  # <- hard reset
	print("PLAY", sound_name, "on (steal)", first, "vol=", first.volume_db)
	first.play()
	return first




func is_playing(sound_name: StringName) -> bool:
	if not sounds.has(sound_name):
		return false
	var stream: AudioStream = sounds[sound_name]
	for c in channels:
		if c.playing and c.stream == stream:
			return true
	return false


func stop(sound_name: StringName) -> void:
	if not sounds.has(sound_name):
		return
	var stream: AudioStream = sounds[sound_name]
	for c in channels:
		if c.playing and c.stream == stream:
			c.stop()


func fade_out_and_stop(sound_name: StringName, duration: float = 0.5) -> void:
	if not sounds.has(sound_name):
		return

	var stream: AudioStream = sounds[sound_name]

	for c in channels:
		if c.playing and c.stream == stream:
			print("FADE", sound_name, "on", c, "start vol=", c.volume_db)
			var chan := c
			var tween := create_tween()
			tween.tween_property(chan, "volume_db", -80.0, duration)
			tween.tween_callback(func():
				print("FADE DONE on", chan, "vol=", chan.volume_db, "playing=", chan.playing)
				if chan.playing:
					chan.stop())
