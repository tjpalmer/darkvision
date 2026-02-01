@tool
extends HBoxContainer

@export var frames: SpriteFrames
@onready var sprite: AnimatedSprite2D = $Icon/Sprite
@onready var label: Label = $Margins/Label

func _ready():
	if frames:
		sprite.sprite_frames = frames

func update_label(value: int):
	#print("Updating label " + str(value))
	label.text = str(value)
