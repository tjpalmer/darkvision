extends ColorRect

@onready var mat: ShaderMaterial = material

var t := 0.0

func _process(delta: float) -> void:
	t += delta
	# Base radius 0.32, pulse ±0.04 at ~1.5 Hz
	var base_radius = 0.18
	var pulse_amp   = 0.02
	var speed       = 0.15
	var r = base_radius + sin(t * TAU * speed) * pulse_amp
	mat.set_shader_parameter("radius", r)
