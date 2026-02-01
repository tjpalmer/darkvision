extends ColorRect

const CELL_NUM := 30

const pov_frame_count_scale := 8.0
const enemy_scale_max := 5.0
const enemy_scale_frame := enemy_scale_max / pov_frame_count_scale
const enemy_pos_frame := 1.0 / pov_frame_count_scale

var treasure_spawn_chance: float = 1.0
var enemy_spawn_chance: float = 1.0
var should_spawn_chest_on_stop: float = false

@onready var battle_manager: Node2D = $BattleManager
@onready var battle_engine: Node2D = $BattleManager/BattleEngine
@onready var hud: Control = $Box/Margins/Hud
@onready var world_box: VBoxContainer = $Box
@onready var move_button_control: Control = $MoveButtonControl
@onready var move_button: Button = $MoveButtonControl/MoveButton
@onready var pulsing_light_ring: ColorRect = $PulsingLightRing

var is_event_happening: bool = false

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

# TODO: Add more enemies to the battle-engine
const ENEMIES: Array[PackedScene] = [
	preload("res://scenes/enemies/eye.tscn"),
	#preload("res://scenes/enemies/rat.tscn"),
	#preload("res://scenes/enemies/slime.tscn"),
]

const CHEST_SCENE: PackedScene = preload("res://scenes/treasure-chest/treasure-chest.tscn")

var game_won: bool = false
var current_cell: int = 0
var current_enemy: Enemy = null
var current_chest: Node2D = null
var cell_array: Array[int] = []

var is_moving: bool = false
var current_action: String = ""  # "forward", "turn_left", "turn_right"

var enemy_is_present: bool = false

@onready var pov_sprite: AnimatedSprite2D = $Box/Pov/PovSprite
# Optional background:
# @onready var background_sprite: Sprite2D = $Background

func _ready() -> void:
	randomize()
	_build_cell_array()
	current_cell = 0
	_stop_at_next_cell()
	#_update_player_stats()


func _process(_delta: float):
	move_button.visible = !is_moving && !is_event_happening


func _on_player_gain_hearts(hearts: int):
	PlayerStats.heart_pieces += hearts
	_update_player_stats()
	is_event_happening = false
	# Your handler code here
	

func _stop_at_next_cell() -> void:
	if is_event_happening:
		#print("event happening no stop at next cell")
		return
	
	#if move_button.visible == true and !SoundManager.is_playing("heartbeat_single"):
	SoundManager.play("heartbeat_single", 5.0)
		
	if should_spawn_chest_on_stop:
		do_spawn_chest()
		should_spawn_chest_on_stop = false	
		
	_update_player_stats()
	var sprite_id: int = cell_array[current_cell]
	var anim_name: String = SPRITE_ANIMS[sprite_id]

	pov_sprite.animation = anim_name
	pov_sprite.frame = 0
	pov_sprite.stop()
	is_moving = false

	# Go through both rounds of turning all at once.
	match sprite_id:
		CellSpriteId.LEFT_TO_FORWARD, CellSpriteId.RIGHT_TO_FORWARD:
			# But wait until after this frame is done to trigger that.
			await get_tree().process_frame
			_try_step_forward()


func _update_player_stats():
	#print("update level")
	hud.update_level(PlayerStats.level)
	#print("update health")
	hud.update_health(PlayerStats.health)
	#print("update mask pieces")
	hud.update_hearts(PlayerStats.heart_pieces)


####################
# BEGIN MOVEMENT SECTION #
####################
func _try_step_forward() -> void:
	if is_event_happening:
		#print("event happening no _try_step_forward")
		return
		
	if game_won or is_moving:
		return

	current_action = "forward"
	is_moving = true
	# Use the precomputed path for forward:
	_advance()


func _do_turn_left() -> void:
	#print("Try turn left")
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
	#print("Try turn right")
	if game_won or is_moving:
		return

	print ("Turning Right")
	current_action = "turn_right"
	is_moving = true

	# Just play the right-turn A animation directly.
	pov_sprite.animation = SPRITE_ANIMS[CellSpriteId.FORWARD_TO_RIGHT_A]
	pov_sprite.frame = 0
	_advance()


#func _unhandled_input(event: InputEvent) -> void:
	#if is_event_happening:
		#print("event happening no _unhandled_input")
		#return
		#
	#if event.is_echo():
		#return
#
	#if event.is_action_pressed("move_forward"):
		#_try_step_forward()
	#elif event.is_action_pressed("turn_left"):
		#_do_turn_left()
	#elif event.is_action_pressed("turn_right"):
		#_do_turn_right()
		
func _try_press_on() -> void:
	if is_event_happening:
		#print("event happening no _unhandled_input")
		return
		
	_try_step_forward()
	#_do_turn_left()
	#_do_turn_right()
####################
# END MOVEMENT SECTION #
####################


func _advance():
	if is_event_happening:
		#print("event happening no _advance")
		return

	SoundManager.play("footsteps", -2.0)		
	pov_sprite.play()
	_try_choose_enemy()


func _try_choose_enemy() -> void:
	if is_event_happening:
		#print("event happening no _try_choose_enemy")
		return
		
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
			# CHANCE TO SPAWN A CHEST HERE???
			# Won't spawn if we are moving right up to the wall, but will when we are turning left or right 
			if pov_sprite.animation != "pov_forward_to_left_B" and pov_sprite.animation != "pov_forward_to_right_B":
				try_spawn_chest()
			
			return
			
	# Spawn enemy at % chance
	var rando = randf()
	
	if rando > enemy_spawn_chance:
		return
		
	# Spawn enemy.
	var enemy_scene := ENEMIES.pick_random() as PackedScene
	current_enemy = enemy_scene.instantiate() as Enemy
	# Start at almost first frame position.
	# This is complicated by starting at frame 0 of our current animation, but
	# going through frame zero of the next.
	# TODO Track when the anim changes for 9 steps total of enemy animation?
	_update_enemy_transform(0.5)
	add_child(current_enemy)


func try_spawn_chest():
	if is_event_happening:
		#print("event happening no try_spawn_chest")
		return
		
	# Spawn chest at % chance
	var rando = randf()
	if rando > treasure_spawn_chance:
		return
	
	should_spawn_chest_on_stop = true
	
func do_spawn_chest():
	# Spawn chest
	current_chest = CHEST_SCENE.instantiate()
	#print("SPAWNED CHEST")
	current_chest.position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y * 2 / 3)
	current_chest.player_gain_hearts.connect(_on_player_gain_hearts)
	add_child(current_chest)
	is_event_happening = true

func _update_enemy_transform(frame := pov_sprite.frame as float):
	if is_event_happening:
		#print("event happening no _update_enemy_transform")
		return
		
	if frame == 0:
		frame = 8
	var enemy_scale := enemy_scale_frame * frame * 4
	current_enemy.scale = Vector2.ONE * enemy_scale
	var pov_size := _animated_sprite_size(pov_sprite)
	current_enemy.position = \
		pov_size / 2 + \
		pov_size * current_enemy.start_pos * enemy_pos_frame * frame
		
	if frame == 7:
		trigger_battle()


func trigger_battle():
	if is_event_happening:
		#print("event happening no trigger_battle")
		return
		
	if current_enemy != null:
		remove_child(current_enemy)
		current_enemy.queue_free()
		current_enemy = null
		
	move_button_control.visible = false
	pulsing_light_ring.visible = false
	#move_button_control.process = PROCESS_MODE_DISABLED
	is_event_happening = true
	battle_manager.visible = true
	battle_engine._init_battle()
	world_box.visible = false
	world_box.process_mode = Node.PROCESS_MODE_DISABLED
	
	
func battle_ended():
	if !is_event_happening:
		#print("battle_ended but is_event_happening = " + str(is_event_happening))
		return
		
	move_button_control.visible = true
	pulsing_light_ring.visible = true
	#move_button_control.process = PROCESS_MODE_INHERIT
	PlayerStats.level += 1
	world_box.visible = true
	world_box.process_mode = Node.PROCESS_MODE_INHERIT
	is_event_happening = false



func _animated_sprite_size(sprite: AnimatedSprite2D) -> Vector2:
	return sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame,
	).get_size() * sprite.scale


func _on_pov_sprite_frame_changed() -> void:
	if current_enemy == null:
		return
	_update_enemy_transform()


func _on_pov_sprite_animation_finished() -> void:
	if is_event_happening:
		#print("event happening no _on_pov_sprite_animation_finished")
		return
		
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


func _on_battle_engine_battle_ended() -> void:
	battle_ended()


func _on_move_button_button_up() -> void:
	SoundManager.log()

	#print("move button pressed")
	if !is_moving:
		_try_press_on()
