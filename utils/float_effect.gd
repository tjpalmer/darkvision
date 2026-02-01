extends Node2D
# or: extends Control

var _base_position: Vector2
var _time: float = 1.0
var _initial_amplitude = 6.0
var _initial_speed = 4.0

@export var amplitude: float = _initial_amplitude	# how far it moves up/down in pixels
@export var speed: float = _initial_speed		# how fast it bobs

func _ready() -> void:
	_base_position = position

func _process(delta: float) -> void:
	_time += delta * speed
	var offset_y := sin(_time) * amplitude
	position = _base_position + Vector2(0, offset_y)

func set_amplitude(value: float):
	amplitude = value
	
func set_speed(value: float):
	speed = value

	
func reset_amplitude():
	amplitude = _initial_amplitude
	
func reset_speed():
	speed = _initial_speed
