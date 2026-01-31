extends Control

var max_health: int = 0
var current_health: int = 0

@onready var fill: ColorRect = $Fill

func _ready():
	# Wait for layout to compute size
	await get_tree().process_frame

func set_max_health(value: int):
	max_health = value
	if max_health > 0:
		set_health(current_health)

func set_health(value: int):
	current_health = clamp(value, 0, max_health)
	_update_bar()

func damage(amount: int):
	set_health(current_health - amount)

func heal(amount: int):
	set_health(current_health + amount)

func _update_bar():
	if max_health == 0 or size.x <= 0:
		print("Health bar not ready (max_health=" + str(max_health) + ", size=" + str(size) + ")")
		return
	
	var ratio: float = float(current_health) / float(max_health)
	var full_width: float = size.x  # Use size.x — the correct property!
	fill.size.x = full_width * ratio
	print("ratio: " + str(ratio) + ", full_width: " + str(full_width) + ", fill.size.x: " + str(fill.size.x))
