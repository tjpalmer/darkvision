extends Button

func _ready():
	connect("pressed", _on_button_pressed)
	init()

func init():
	text = "ATTACK"

func _on_button_pressed():
	if text == "ATTACK":
		text = "DEFEND"
	else:
		text = "ATTACK"
