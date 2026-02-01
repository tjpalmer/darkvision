extends Node2D

@onready var attack_button = $AttackButton
@onready var enemy: Node2D = $Enemy
@onready var enemy_healthbar: Control = $EnemyHealthBar
@onready var player_healthbar: Control = $PlayerHealthBar
@onready var player_sprite: AnimatedSprite2D = $PlayerAttackSprite
@onready var victory_panel: Panel = $VictoryPanel
@onready var victory_screen_timer: Timer = $VictoryScreenTimer
@onready var for_now_label: Label = $VictoryPanel/ForNowLabel
@onready var level_up_label: Label = $VictoryPanel/LevelUpLabel
@onready var battle_status_label: Label = $BattleStatusLabel
@onready var battle_status_timer: Timer = $BattleStatusTimer

var has_init: bool = false
var victory: bool = false;
var victory_timer_count: int = 0

var which_bgm_to_play = 0 # 0 for 1st bgm, 1 for 2nd bgm currently swapping back and forth every combat
#var should_play_bgm = false

signal battle_ended

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_end_battle()

func _init_battle():
	#should_play_bgm = true
	battle_status_label.visible = false
	for_now_label.visible = true
	level_up_label.visible = true
	victory_timer_count = 0
	#print("INIT BATTLE")
	attack_button.init()
	enemy.enter_battle()
	victory_panel.visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	#print("enemy health set to " + str(enemy.health))
	enemy_healthbar.set_max_health(enemy.health)
	enemy_healthbar.set_health(enemy.health)
	#print("player health set to " + str(PlayerStats.health))
	player_healthbar.set_max_health(PlayerStats.max_health)
	player_healthbar.set_health(PlayerStats.health)
	
	
func _end_battle():
	#print("DISABLE BATTLE PROCESS")
	visible = false
	has_init = false
	process_mode = Node.PROCESS_MODE_DISABLED

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !has_init:
		attack_button.init()
		_init_battle()
		
		if which_bgm_to_play == 0:
			#print("Play combat bgm")
			SoundManager.play("combat_bgm", -3.0, true)
			which_bgm_to_play = 1
		else:
			#print("Play combat bgm ALT")
			SoundManager.play("combat_bgm_alt", -3.0, true)
			which_bgm_to_play = 0
			
		SoundManager.log()
		
		has_init = true


func _on_enemy_damage_player(amount: int) -> void:
	var is_player_blocking: bool = player_sprite.is_playing() and player_sprite.animation == "defend"
	#print("is blocking? " + str(is_player_blocking))
	
	if !is_player_blocking:
		SoundManager.play("player_hurt")
		player_healthbar.damage(amount)
	else:
		battle_status_timer.start()
		battle_status_label.visible = true
		#print("play block_clang")
		SoundManager.play("block_clang")


func _on_player_attack_sprite_damage_enemy() -> void:
	#print("DAMAGE ENEMY")
	enemy_healthbar.damage(PlayerStats.level)
	if enemy_healthbar.current_health <= 0:
		#print("ENEMY DEDD")
		enemy.die()
	


func _on_enemy_enemy_died() -> void:
	#print("enemy died ending battle")
	victory_screen_timer.start()
	level_up_label.visible = false
	for_now_label.visible = false
	victory_panel.visible = true
	


func _on_victory_screen_timer_timeout() -> void:
	victory_timer_count += 1
	#print("victory count: " + str(victory_timer_count))
	
	if which_bgm_to_play == 1:
		SoundManager.fade_out_and_stop("combat_bgm", 5.0)
	else:
		SoundManager.fade_out_and_stop("combat_bgm_alt", 5.0)
	
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
