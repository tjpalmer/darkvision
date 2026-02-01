extends Node2D

@onready var chest: AnimatedSprite2D = $Chest
@onready var heart_piece_group: Node2D = $HeartPieceGroup
@onready var heart_piece_gain_label: Label = $HeartPieceGroup/HeartPieceGainLabel
@onready var heart_piece_gain_label2: Label = $HeartPieceGroup/HeartPieceGainLabel2

var heart_should_rise: bool = false
var heart_is_rising: bool = false
var heart_pieces_gained: int = randi_range(7, 19)

signal player_gain_hearts(amount: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	heart_piece_group.visible = false
	#heart_piece_gain_label2.visible = false
	heart_should_rise = false
	heart_is_rising = false
	heart_piece_gain_label.text = "+" + str(heart_pieces_gained)
	heart_piece_gain_label2.text = "+" + str(heart_pieces_gained)
	open()


func player_gain_piece():
	player_gain_hearts.emit(heart_pieces_gained)
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if heart_should_rise:
		rise_and_fade(heart_piece_group, player_gain_piece)


func rise_and_fade(node: Node2D, callback: Callable):
	if heart_is_rising:
		return
		
	#heart_piece_gain_label2.visible = true
	heart_is_rising = true
	var tween = create_tween()
	
	# Rise up 100px + fade over 1.5 seconds
	tween.tween_property(node, "position:y", node.position.y - 84, 1.0)
	#tween.tween_callback(func(): heart_piece_gain_label2.visible = true)  # ← Show +X label after heart rises out of chest

	tween.tween_property(node, "modulate:a", 0.0, 1.5)
	
	# Smooth easing
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Call your function when fully faded
	tween.tween_callback(callback)


func open():
	chest.play("open")


func _on_chest_animation_finished() -> void:
	heart_piece_group.visible = true
	heart_should_rise = true
