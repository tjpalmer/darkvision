extends Node2D

# Core stats
var health: int = 100
var max_health: int = 100
var mana: int = 50
var max_mana: int = 50
var level: int = 1
var experience: int = 0
var mask_pieces: int = 0
var attack_damage: float = 6.0

# Convenience helpers
func heal(amount: int):
	health = clamp(health + amount, 0, max_health)

func take_damage(amount: int):
	health = clamp(health - amount, 0, max_health)

func gain_xp(amount: int):
	experience += amount

func gain_mask_pieces(amount: int):
	mask_pieces += amount

func is_alive() -> bool:
	return health > 0

# Optional: signal when stats change
# signal stats_changed()
