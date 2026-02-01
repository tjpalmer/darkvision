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

var has_init: bool = false
var victory: bool = false;
var victory_timer_count: int = 0

signal battle_ended

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_end_battle()

func _init_battle():
	for_now_label.visible = true
	level_up_label.visible = true
	victory_timer_count = 0
	print("INIT BATTLE")
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
	print("DISABLE BATTLE PROCESS")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !has_init:
		attack_button.init()
		_init_battle()
		
		has_init = true


func _on_enemy_damage_player(amount: int) -> void:
	var is_player_blocking: bool = player_sprite.is_playing() and player_sprite.animation == "defend"
	print("is blocking? " + str(is_player_blocking))
	
	if !is_player_blocking:
		player_healthbar.damage(amount)


func _on_player_attack_sprite_damage_enemy() -> void:
	print("DAMAGE ENEMY")
	enemy_healthbar.damage(PlayerStats.level)
	if enemy_healthbar.current_health <= 0:
		print("ENEMY DEDD")
		enemy.die()
	


func _on_enemy_enemy_died() -> void:
	print("enemy died ending battle")
	victory_screen_timer.start()
	level_up_label.visible = false
	for_now_label.visible = false
	victory_panel.visible = true
	


func _on_victory_screen_timer_timeout() -> void:
	victory_timer_count += 1
	print("victory count: " + str(victory_timer_count))
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
