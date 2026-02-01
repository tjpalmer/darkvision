@tool
extends HBoxContainer

@export var frames: SpriteFrames
@onready var sprite: AnimatedSprite2D = $Icon/Sprite

func _ready():
	if frames:
		sprite.sprite_frames = frames
