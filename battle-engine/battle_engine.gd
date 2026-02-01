extends Node2D

@onready var attack_button = $BattleGroup/AttackButton
@onready var common_enemy: Node2D = $BattleGroup/Enemy
#@onready var lich_enemy: Node2D = $LichEnemy
@onready var enemy_healthbar: Control = $BattleGroup/EnemyHealthBar
@onready var player_healthbar: Control = $BattleGroup/PlayerHealthBar
@onready var player_sprite: AnimatedSprite2D = $BattleGroup/PlayerAttackSprite
@onready var victory_panel: Panel = $VictoryPanel
@onready var you_died_panel: Panel = $YouDiedPanel
@onready var game_win_panel: Panel = $GameWinPanel
@onready var win_forever_label: Label = $GameWinPanel/ForEverLabel
@onready var victory_screen_timer: Timer = $VictoryScreenTimer
@onready var you_died_screen_timer: Timer = $YouDiedTimer
@onready var game_win_timer: Timer = $GameWinTimer
@onready var for_now_label: Label = $VictoryPanel/ForNowLabel
@onready var died_for_now_label: Label = $YouDiedPanel/ForNowLabel
@onready var died_level_down_label: Label = $YouDiedPanel/LevelDownLabel
@onready var level_up_label: Label = $VictoryPanel/LevelUpLabel
@onready var battle_status_label: Label = $BattleGroup/BattleStatusLabel
@onready var battle_status_timer: Timer = $BattleStatusTimer

@onready var battle_group: Node2D = $BattleGroup

var lich_scene: PackedScene = preload("res://battle-engine/lich_enemy.tscn")

var has_init: bool = false
var victory: bool = false;
var victory_timer_count: int = 0
var you_died_timer_count: int = 0
var win_timer_count: int = 0
var player_is_dead: bool = false
var is_final_boss_battle: bool = false
var did_final_boss_init: bool = false # hacky bool weee
var is_final_boss_dead: bool = false

var which_bgm_to_play = 0 # 0 for 1st bgm, 1 for 2nd bgm currently swapping back and forth every combat
#var should_play_bgm = false

signal battle_ended
signal battle_ended_with_player_death

var enemy: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_end_battle()

func _init_battle(is_final_boss: bool = false):
	print("is this final boss init? " + str(is_final_boss))
	if !is_final_boss:
		enemy = common_enemy
	else:
		print("Ffight the lich!")
		if enemy:
			print("QUEUE FREE ENEMY")
			enemy.queue_free() # lich is final boss so kill off existing enemy instance
			
		if common_enemy:
			print("QUEUE FREE COMMON_ENEMY")
			common_enemy.queue_free()
			
		enemy = lich_scene.instantiate()
		add_child(enemy)
	
	var center := get_viewport_rect().size / 2.0
	player_sprite.position.x = center.x
	is_final_boss_battle = is_final_boss
	attack_button.disabled = false
	died_for_now_label.visible = false
	died_level_down_label.visible = false
	player_is_dead = false
	#should_play_bgm = true
	battle_status_label.visible = false
	for_now_label.visible = true
	level_up_label.visible = true
	victory_timer_count = 0
	you_died_timer_count = 0
	victory_screen_timer.stop()
	you_died_screen_timer.stop()
	#print("INIT BATTLE")
	attack_button.init()
	victory_panel.visible = false
	you_died_panel.visible = false
	game_win_panel.visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	#print("enemy health set to " + str(enemy.health))
	
	if !is_final_boss and enemy != null: # this is hacky looooool
		enemy.position.x = center.x
		#enemy.position.y = center.y
		enemy.enter_battle()
		enemy_healthbar.set_max_health(enemy.health)
		enemy_healthbar.set_health(enemy.health)
		try_stop_combat_bgm()
		if which_bgm_to_play == 0:
			#print("Play combat bgm")
			SoundManager.play("combat_bgm", -3.0, true)
			which_bgm_to_play = 1
		else:
			#print("Play combat bgm ALT")
			SoundManager.play("combat_bgm_alt", -3.0, true)
			which_bgm_to_play = 0

	player_healthbar.set_max_health(PlayerStats.max_health)
	player_healthbar.set_health(PlayerStats.health)
	
	has_init = true



	
func _end_battle():
	#print("DISABLE BATTLE PROCESS")
	visible = false
	has_init = false
	process_mode = Node.PROCESS_MODE_DISABLED

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#print("processing battle frame")
	if !has_init: # currently WILL NOT RUN for final boss battle so we duping logic soz m8
		attack_button.init()
		_init_battle()
			
		SoundManager.log()
		has_init = true
		
	#print ("did_final_boss_init? " + str(did_final_boss_init) + ", enemy != null? " + str(enemy != null))
	if !did_final_boss_init and enemy != null and is_final_boss_battle: # hax lul
		attack_button.init()
		print("init final boss time")
		SoundManager.play("lich_intro_bgm", -3.0)
		var center := get_viewport_rect().size / 2.0
		enemy.position.x = center.x
		enemy.position.y = center.y - 24
		#enemy.enter_battle()
		enemy_healthbar.set_max_health(enemy.health)
		enemy_healthbar.set_health(enemy.health)
		did_final_boss_init = true
		enemy.enter_battle()
		enemy.damage_player.connect(_on_enemy_damage_player)
		enemy.enemy_died.connect(_on_enemy_enemy_died)
		
	if did_final_boss_init:
		# print("try to play lich loop")
		if !SoundManager.is_playing("lich_intro_bgm") and !SoundManager.is_playing("lich_loop_bgm") and !is_final_boss_dead:
			print("playing lich loop")
			SoundManager.play("lich_loop_bgm", -3.0, true)


func _on_enemy_damage_player(amount: int) -> void:
	var is_player_blocking: bool = player_sprite.is_playing() and player_sprite.animation == "defend"
	#print("is blocking? " + str(is_player_blocking))
	
	if !is_player_blocking:
		SoundManager.play("player_hurt")
		player_healthbar.damage(amount)
		
		print("player health: " + str(player_healthbar.current_health))
		if player_healthbar.current_health <= 0:
			player_died()
	else:
		battle_status_timer.start()
		battle_status_label.visible = true
		#print("play block_clang")
		SoundManager.play("block_clang")
		
		if is_final_boss_battle:
			enemy.cancel_attacks()


func _on_player_attack_sprite_damage_enemy() -> void:
	#print("DAMAGE ENEMY")
	enemy_healthbar.damage(PlayerStats.level)
	if enemy_healthbar.current_health <= 0:
		#print("ENEMY DEDD")
		enemy.die()
	


func _on_enemy_enemy_died() -> void:
	#print("enemy died ending battle")
	if is_final_boss_battle:
		is_final_boss_dead = true
		try_stop_combat_bgm()
		print("start game win timer")
		game_win_timer.start()
		game_win_panel.visible = true
		victory_panel.visible = false
		battle_group.visible = false
	else:
		print("start victory screen regular timer")
		victory_screen_timer.start()
		victory_panel.visible = true
		game_win_panel.visible = false

	level_up_label.visible = false
	for_now_label.visible = false
	you_died_panel.visible = false
	
	
func player_died():
	attack_button.disabled = true
	enemy.cleanup(false)
	player_is_dead = true
	await get_tree().create_timer(1.0).timeout
	print("player died")
	you_died_screen_timer.start()
	level_up_label.visible = false
	for_now_label.visible = false
	victory_panel.visible = false
	you_died_panel.visible = true
	game_win_panel.visible = false
	
	
func try_stop_combat_bgm():
		SoundManager.fade_out_and_stop("combat_bgm", 3.0)
		SoundManager.fade_out_and_stop("combat_bgm_alt", 3.0)
		SoundManager.fade_out_and_stop("lich_intro_bgm")
		SoundManager.fade_out_and_stop("lich_loop_bgm")
		
func _on_victory_screen_timer_timeout() -> void:
	victory_timer_count += 1
	#print("victory count: " + str(victory_timer_count))
	
	try_stop_combat_bgm()
	
	match victory_timer_count:
		1:
			for_now_label.visible = true
			victory_screen_timer.start()
		2:
			level_up_label.visible = true
			victory_screen_timer.start()
		3:
			victory_screen_timer.start()
		4:
			PlayerStats.health = player_healthbar.current_health
			battle_ended.emit()
			_end_battle()


func _on_battle_status_timer_timeout() -> void:
	battle_status_label.visible = false


func _on_you_died_timer_timeout() -> void:
	you_died_timer_count += 1
	print("you died timer count: " + str(you_died_timer_count))
	
	try_stop_combat_bgm()
	
	match you_died_timer_count:
		1:
			died_for_now_label.visible = true
			you_died_screen_timer.start()
		2:
			died_level_down_label.visible = true
			you_died_screen_timer.start()
		3:
			you_died_screen_timer.start()
		4:
			print("End battle")
			battle_ended_with_player_death.emit()
			_end_battle()


func _on_game_win_timer_timeout() -> void:
	win_timer_count += 1
	print("you died timer count: " + str(win_timer_count))
	
	#try_stop_combat_bgm()
	
	match win_timer_count:
		1:
			SoundManager.play("game_win_bgm", 0.0, true)
			win_forever_label.visible = true
