extends ColorRect

const CELL_NUM := 30

enum CellSpriteId {
	FORWARD_TO_FORWARD,     # 0
	FORWARD_TO_LEFT_A,      # 1
	FORWARD_TO_RIGHT_A,     # 2
	LEFT_TO_FORWARD,        # 3
	RIGHT_TO_FORWARD,       # 4
	FORWARD_TO_LEFT_B,      # 5
	FORWARD_TO_RIGHT_B,     # 6
	FORWARD_TO_EXIT         # 7
}

const SPRITE_ANIMS := [
	"pov_forward_to_forward",   # 0
	"pov_forward_to_left_A",    # 1
	"pov_forward_to_right_A",   # 2
	"pov_left_to_forward",      # 3
	"pov_right_to_forward",     # 4
	"pov_forward_to_left_B",    # 5
	"pov_forward_to_right_B",   # 6
	"pov_forward_to_exit"       # 7
]

const ENEMIES: Array[PackedScene] = [
	preload("res://scenes/enemies/eye.tscn"),
	preload("res://scenes/enemies/rat.tscn"),
	preload("res://scenes/enemies/slime.tscn"),
]

var game_won: bool = false
var current_cell: int = 0
var current_enemy: Enemy = null
var cell_array: Array[int] = []

var is_moving: bool = false
var current_action: String = ""  # "forward", "turn_left", "turn_right"

@onready var pov_sprite: AnimatedSprite2D = $PovSprite
# Optional background:
# @onready var background_sprite: Sprite2D = $Background

func _ready() -> void:
	randomize()
	_build_cell_array()
	current_cell = 0
	_stop_at_next_cell()


func _stop_at_next_cell() -> void:
	var sprite_id: int = cell_array[current_cell]
	var anim_name: String = SPRITE_ANIMS[sprite_id]

	pov_sprite.animation = anim_name
	pov_sprite.frame = 0
	pov_sprite.stop()
	is_moving = false


####################
# BEGIN MOVEMENT SECTION #
####################
func _try_step_forward() -> void:
	if game_won or is_moving:
		return

	current_action = "forward"
	is_moving = true
	# Use the precomputed path for forward:
	_advance()


func _do_turn_left() -> void:
	print("Try turn left")
	if game_won or is_moving:
		return

	print ("Turning Left")
	current_action = "turn_left"
	is_moving = true

	# Just play the left-turn A animation directly.
	pov_sprite.animation = SPRITE_ANIMS[CellSpriteId.FORWARD_TO_LEFT_A]
	pov_sprite.frame = 0
	_advance()

	
func _do_turn_right() -> void:
	print("Try turn right")
	if game_won or is_moving:
		return

	print ("Turning Right")
	current_action = "turn_right"
	is_moving = true

	# Just play the right-turn A animation directly.
	pov_sprite.animation = SPRITE_ANIMS[CellSpriteId.FORWARD_TO_RIGHT_A]
	pov_sprite.frame = 0
	_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if event.is_action_pressed("move_forward"):
		_try_step_forward()
	elif event.is_action_pressed("turn_left"):
		_do_turn_left()
	elif event.is_action_pressed("turn_right"):
		_do_turn_right()
####################
# END MOVEMENT SECTION #
####################


func _advance():
	pov_sprite.play()
	_choose_enemy()


func _choose_enemy() -> void:
	# Remove current. TODO Already dead before we get here?
	if current_enemy != null:
		remove_child(current_enemy)
		current_enemy.queue_free()
		current_enemy = null
	# Spawn enemies only when non-congested.
	match pov_sprite.animation:
		"pov_forward_to_forward", \
		"pov_forward_to_left_A", \
		"pov_forward_to_right_A":
			pass
		_:
			return
	# Spawn enemy.
	var enemy_scene := ENEMIES.pick_random() as PackedScene
	current_enemy = enemy_scene.instantiate() as Enemy
	current_enemy.scale = Vector2.ONE * enemy_frame_scale
	var pov_size := _animated_sprite_size(pov_sprite)
	current_enemy.position = pov_size * current_enemy.start_pos
	add_child(current_enemy)


const enemy_frame_scale := 0.625


func _animated_sprite_size(sprite: AnimatedSprite2D) -> Vector2:
	return sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame,
	).get_size() * sprite.scale


func _on_pov_sprite_frame_changed() -> void:
	if current_enemy == null:
		return
	# Scale enemy.
	var frame := pov_sprite.frame
	if frame == 0:
		frame = 8
	var enemy_scale := enemy_frame_scale * frame
	current_enemy.scale = Vector2.ONE * enemy_scale


func _on_pov_sprite_animation_finished() -> void:
	if not is_moving:
		return

	match current_action:
		"forward":
			if current_cell < cell_array.size() - 1:
				current_cell += 1
				_stop_at_next_cell()
			else:
				var exit_anim := SPRITE_ANIMS[CellSpriteId.FORWARD_TO_EXIT]
				pov_sprite.animation = exit_anim
				_advance()
				#pov_sprite.stop()
				game_won = true
				is_moving = false
		"turn_left", "turn_right":
			# After a turn-in-place, just reset to whatever the current cell should be.
			_stop_at_next_cell()

	is_moving = false
	current_action = ""


func _build_cell_array() -> void:
	cell_array.clear()
	cell_array.append(CellSpriteId.FORWARD_TO_FORWARD)

	for i in CELL_NUM:
		var last_cell: int = cell_array.back()
		var options: Array[int] = []

		match last_cell:
			CellSpriteId.FORWARD_TO_FORWARD:
				options = [CellSpriteId.FORWARD_TO_FORWARD,
						   CellSpriteId.FORWARD_TO_LEFT_A,
						   CellSpriteId.FORWARD_TO_RIGHT_A]
			CellSpriteId.FORWARD_TO_LEFT_A:
				options = [CellSpriteId.FORWARD_TO_LEFT_B]
			CellSpriteId.FORWARD_TO_RIGHT_A:
				options = [CellSpriteId.FORWARD_TO_RIGHT_B]
			CellSpriteId.LEFT_TO_FORWARD:
				options = [CellSpriteId.FORWARD_TO_FORWARD,
						   CellSpriteId.FORWARD_TO_LEFT_A,
						   CellSpriteId.FORWARD_TO_RIGHT_A]
			CellSpriteId.RIGHT_TO_FORWARD:
				options = [CellSpriteId.FORWARD_TO_FORWARD,
						   CellSpriteId.FORWARD_TO_LEFT_A,
						   CellSpriteId.FORWARD_TO_RIGHT_A]
			CellSpriteId.FORWARD_TO_LEFT_B:
				options = [CellSpriteId.LEFT_TO_FORWARD]
			CellSpriteId.FORWARD_TO_RIGHT_B:
				options = [CellSpriteId.RIGHT_TO_FORWARD]

		options.shuffle()
		var next_cell: int = options[0]
		cell_array.append(next_cell)

	var cells_to_add: Array[int] = []
	var last: int = cell_array.back()

	match last:
		CellSpriteId.FORWARD_TO_FORWARD:
			cells_to_add = [CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]
		CellSpriteId.FORWARD_TO_LEFT_A:
			cells_to_add = [CellSpriteId.FORWARD_TO_LEFT_B,
							CellSpriteId.LEFT_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]
		CellSpriteId.FORWARD_TO_RIGHT_A:
			cells_to_add = [CellSpriteId.FORWARD_TO_RIGHT_B,
							CellSpriteId.RIGHT_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]
		CellSpriteId.LEFT_TO_FORWARD:
			cells_to_add = [CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]
		CellSpriteId.RIGHT_TO_FORWARD:
			cells_to_add = [CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]
		CellSpriteId.FORWARD_TO_LEFT_B:
			cells_to_add = [CellSpriteId.LEFT_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]
		CellSpriteId.FORWARD_TO_RIGHT_B:
			cells_to_add = [CellSpriteId.RIGHT_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD,
							CellSpriteId.FORWARD_TO_FORWARD]

	for c in cells_to_add:
		cell_array.append(c)

	cell_array.append(CellSpriteId.FORWARD_TO_EXIT)
