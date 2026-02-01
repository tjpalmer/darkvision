extends Button

@onready var player_attack_sprite = $"../PlayerAttackSprite"

func _ready():
	connect("pressed", _on_button_pressed)
	init()

func init():
	text = "ATTACK"

func _on_button_pressed():
	#print("button pressed")
	if text == "ATTACK":
		if player_attack_sprite.play_anim("attack"):
			text = "DEFEND"
			#print("PLAYER ATTACKS!")
	else:
		if player_attack_sprite.play_anim("defend"):
			text = "ATTACK"
			#print("PLAYER DEFENDS!")
			
	#print("end of button func. text = " + text)
