extends Node2D
# or: extends CharacterBody2D

enum State {
	WAITING_FOR_BATTLE,
	INITIAL,
	IDLE,
	WIND_UP,
	ATTACK,
	DEAD
}

var state: State = State.INITIAL
var attack_amplitude:float = 16.0
var attack_speed: float = 6.0
var time_between_decisions: float = 2.0 # in seconds

signal damage_player(amount: int)
signal enemy_died

var attack_damage: float = 9.0
var health: float = 4.0
var is_dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var battle_decision_timer: Timer = $BattleDecisionTimer


func _ready() -> void:
	sprite.reset_amplitude()
	sprite.reset_speed()
	battle_decision_timer.wait_time = time_between_decisions
	_enter_state(State.IDLE)
	
func die():
	sprite.set_speed(0)
	sprite.set_amplitude(0)
	battle_decision_timer.stop()
	_enter_state(State.DEAD)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_update_idle(delta)
		State.WIND_UP:
			_update_wind_up(delta)
		State.ATTACK:
			_update_attack(delta)
		State.DEAD:
			if is_dead:
				#print("DENY DEAD STATE UPDATE: " + str(State.keys()[state]))
				return
			_update_dead(delta)
		State.WAITING_FOR_BATTLE:
			#print("DO NOTHING WE ARE WAITING: " + str(State.keys()[state]))
			pass # Do nothing we're just waiting and parent will disable our processing soon

# All the things to reset enemy back to beginning of battle
func enter_battle():
	_enter_state(State.IDLE)
	is_dead = false
	sprite.modulate.a = 1.0
	sprite.rotation = 0.0
	sprite.reset_amplitude()
	sprite.reset_speed()
	battle_decision_timer.start()  # Ensure timer ready
	#print("enemy entering battle. hp: " + str(health) + ", atk: " + str(attack_damage))

func start_attack() -> void:
	if state == State.DEAD:
		return
	_enter_state(State.ATTACK)

func kill() -> void:
	_enter_state(State.DEAD)



func _enter_state(new_state: State) -> void:
	if state == new_state:
		#print("TRYING TO ENTER SAME STATE AGAIN " + State.keys()[new_state])
		return

	state = new_state

	match state:
		State.IDLE:
			#print("ENEMY GOING IDLE")
			battle_decision_timer.start()
			sprite.play("idle")
		State.WIND_UP:
			sprite.set_amplitude(0)
			sprite.set_speed(0)
			sprite.play("wind_up")
		State.ATTACK:
			sprite.set_amplitude(attack_amplitude)
			sprite.set_speed(attack_speed)
			#print("ENEMY GOING ATTACK")
			sprite.play("attack")
			damage_player.emit(attack_damage)
		State.DEAD:
			#print("ENEMY GOING DEAD")
			sprite.play("dead")
			# Optional: disable collisions / logic here


func _update_idle(_delta: float) -> void:
	# For now, nothing special; you can add patrol logic here later.
	pass


func _update_wind_up(_delta: float) -> void:
	if not sprite.is_playing():
		_enter_state(State.ATTACK)

func _update_attack(_delta: float) -> void:
	# If attack is a one-shot animation, when it finishes return to idle.
	# Make sure the AnimatedSprite2D's "attack" animation is non-looping.
	if not sprite.is_playing():
		sprite.reset_amplitude()
		sprite.reset_speed()
		_enter_state(State.IDLE)


func _update_dead(_delta: float) -> void:
	# Play dead animation
	is_dead = true

	sprite.play("dead")
	
	# Create tween
	var tween = create_tween()
	
	# Parallel: fade + rotate over 2 seconds
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 2.0)  # fade out
	tween.parallel().tween_property(sprite, "rotation", rotation + deg_to_rad(720), 2.0)  # 2 full spins (720°)
	
	# Optional: easing for polish
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Cleanup when done
	tween.tween_callback(cleanup)


func cleanup():
	#print("cleanup!")
	enemy_died.emit()
	_enter_state(State.WAITING_FOR_BATTLE)
	#queue_free() # if we queue_free() we can't reuse for next battle

func _on_battle_decision_timer_timeout() -> void:
	#print("ENEMY MAKING DECISION")
	_enter_state(State.WIND_UP)
	
	
	
func take_damage(value: float):
	health -= value
	
func set_health(value: float):
	health = value
	
func set_attack_damage(value: float):
	attack_damage = value
