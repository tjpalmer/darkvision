extends Control

@onready var potion: HBoxContainer = $Layout/Levels/Potion # health
@onready var sword: HBoxContainer = $Layout/Levels/Sword # level
@onready var treasure: HBoxContainer = $Layout/Levels/Treasure # mask pieces


func update_level(value: int):
	sword.update_label(value)

func update_health(value: int):
	potion.update_label(value)

func update_mask_pieces(value: int):
	treasure.update_label(value)
