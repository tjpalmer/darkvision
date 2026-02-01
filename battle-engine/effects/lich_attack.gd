extends Node2D

var velocity: Vector2 = Vector2.ZERO
@export var speed: float = 300.0
@export var down_weight: float = 1.5
@export var center_weight: float = 1.0

func _ready() -> void:
	$AnimatedSprite2D.play("attack")

	var center := get_viewport_rect().size / 2.0
	var to_center := (center - global_position).normalized()
	var down := Vector2(0, 1)

	var dir := (to_center * center_weight + down * down_weight).normalized()
	velocity = dir * speed

func _process(delta: float) -> void:
	global_position += velocity * delta
