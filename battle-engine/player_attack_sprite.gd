extends AnimatedSprite2D

var fade_time := 1.0  # seconds
var _elapsed := 0.0
var _start_scale := Vector2.ONE

func _ready():
	_start_scale = scale
	modulate.a = 0
	_elapsed = 0.0


func reset_all():
	modulate.a = 1.0
	scale = _start_scale
	_elapsed = 0.0

func play_anim(animation_name: String) -> bool:
	print(str(is_playing()))
	if is_playing():
		return false

	reset_all()
	play(animation_name)
	return true

func _process(delta: float) -> void:
	var should_fade: bool = animation == "defend"
	
	if is_playing() and should_fade:
		_elapsed += delta
		var t: float = clamp(_elapsed / fade_time, 0.0, 1.0)

		# Fade out
		modulate.a = 1.0 - t

		# Scale down to zero
		scale = _start_scale.lerp(Vector2.ZERO, t)


func _on_animation_finished() -> void:
	modulate.a = 0
	stop()
