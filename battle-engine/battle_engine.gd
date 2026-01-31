extends Node2D

@onready var attack_button = $AttackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_button.init()
	_init_battle()

func _init_battle():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
