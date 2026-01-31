extends Node2D

@onready var attack_button = $AttackButton
@onready var enemy: Node2D = $Enemy
@onready var enemy_healthbar: Control = $EnemyHealthBar
@onready var player_healthbar: Control = $PlayerHealthBar

var has_init: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _init_battle():
	print("enemy health set to " + str(enemy.health))
	enemy_healthbar.set_max_health(enemy.health)
	enemy_healthbar.set_health(enemy.health)
	print("player health set to " + str(PlayerStats.health))
	player_healthbar.set_max_health(PlayerStats.health)
	player_healthbar.set_health(PlayerStats.health)
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !has_init:
		attack_button.init()
		_init_battle()
		
		has_init = true


func _on_enemy_damage_player(amount: int) -> void:
	player_healthbar.damage(amount)
