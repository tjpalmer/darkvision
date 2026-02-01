extends AnimatedSprite2D

var fade_time := 2.0  # seconds
var _elapsed := 0.0
var _start_scale := Vector2.ONE
var _starting_position: Vector2 = position

signal damage_enemy


func _ready():
	_start_scale = scale
	modulate.a = 0
	_elapsed = 0.0


func reset_all():
	modulate.a = 1.0
	scale = _start_scale
	_elapsed = 0.0
	position = _starting_position

func play_anim(animation_name: String) -> bool:
	#print(str(is_playing()))
	if is_playing():
		return false

	reset_all()
	play(animation_name)
	
	if animation == "attack":
		damage_enemy.emit()
		SoundManager.play("whoosh_attack")
		#print("play whoosh_attack")

	
	#if animation_name == "defend":
		#position.y += 48 # hacky positiong defend anim closer to player / bottom of view
	return true

func _process(delta: float) -> void:
	var should_fade: bool = animation == "defend"
	
	if is_playing() and should_fade:
		_elapsed += delta
		var t: float = clamp(_elapsed / fade_time, 0.0, 1.0)

		# Fade out
		if modulate.a > 0:
			modulate.a = 1.0 - t
			
		# Scale down to zero
		var smallest_allowed_scale: float = 4.0
		var target_scale := _start_scale.lerp(Vector2.ZERO, t)
		var min_scale := Vector2(smallest_allowed_scale, smallest_allowed_scale)  # smallest allowed scale
		scale = target_scale.clamp(min_scale, _start_scale)



func _on_animation_finished() -> void:
	modulate.a = 0
	stop()
