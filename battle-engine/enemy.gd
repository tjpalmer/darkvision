extends Node2D
# or: extends CharacterBody2D

enum State {
	INITIAL,
	IDLE,
	ATTACK,
	DEAD
}

var state: State = State.INITIAL
var attack_amplitude:float = 32.0
var attack_speed: float = 7.0
var time_between_decisions: float = 4.0 # in seconds

signal damage_player(amount: int)

var attack_damage: float = 8.0
var health: float = 10.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var battle_decision_timer: Timer = $BattleDecisionTimer

func _ready() -> void:
	battle_decision_timer.wait_time = time_between_decisions
	_enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_update_idle(delta)
		State.ATTACK:
			_update_attack(delta)
		State.DEAD:
			_update_dead(delta)  # usually no-op


# --- Public helpers you can call from other scripts / signals ---

func start_attack() -> void:
	if state == State.DEAD:
		return
	_enter_state(State.ATTACK)

func kill() -> void:
	_enter_state(State.DEAD)


# --- State logic ---

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
		State.ATTACK:
			sprite.set_amplitude(attack_amplitude)
			sprite.set_speed(attack_speed)
			#print("ENEMY GOING ATTACK")
			sprite.play("attack")
		State.DEAD:
			#print("ENEMY GOING DEAD")
			sprite.play("dead")
			# Optional: disable collisions / logic here


func _update_idle(_delta: float) -> void:
	# For now, nothing special; you can add patrol logic here later.
	pass


func _update_attack(_delta: float) -> void:
	# If attack is a one-shot animation, when it finishes return to idle.
	# Make sure the AnimatedSprite2D's "attack" animation is non-looping.
	if not sprite.is_playing():
		damage_player.emit(attack_damage)
		#print("DAMAGE TO PLAYER")
		sprite.reset_amplitude()
		sprite.reset_speed()
		_enter_state(State.IDLE)


func _update_dead(_delta: float) -> void:
	if not sprite.is_playing():
		#print("ENEMY REMOVING AFTER 2 SECONDS")
		# wait 2 seconds after dead animation plays, then remove enemy
		await get_tree().create_timer(2.0).timeout; queue_free()
	pass


func _on_battle_decision_timer_timeout() -> void:
	#print("ENEMY MAKING DECISION")
	_enter_state(State.ATTACK)
	
	
	
func take_damage(value: float):
	health -= value
	
func set_health(value: float):
	health = value
	
func set_attack_damage(value: float):
	attack_damage = value
