extends Node2D

@onready var chest: AnimatedSprite2D = $Chest
@onready var mask_piece: Sprite2D = $MaskPiece

var mask_should_rise: bool = false
var mask_is_rising: bool = false

signal player_gain_hearts(amount: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mask_piece.visible = false
	mask_should_rise = false
	mask_is_rising = false
	open()


func player_gain_piece():
	player_gain_hearts.emit(randi_range(1, 19))
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if mask_should_rise:
		rise_and_fade(mask_piece, player_gain_piece)


func rise_and_fade(node: Node2D, callback: Callable):
	if mask_is_rising:
		return
		
	mask_is_rising = true
	var tween = create_tween()
	
	# Rise up 100px + fade over 1.5 seconds
	tween.parallel().tween_property(node, "position:y", node.position.y - 64, 1.5)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 1.5)
	
	# Smooth easing
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Call your function when fully faded
	tween.tween_callback(callback)


func open():
	chest.play("open")


func _on_chest_animation_finished() -> void:
	mask_piece.visible = true
	mask_should_rise = true
