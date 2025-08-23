extends Node2D

# Holds how many shells are in this main house
var shells: int = 0

@onready var shell_label: Label = $StoneLabel

func _ready():
	update_label()
	add_to_group("main_houses")

# Add shells
func add_shells(amount: int):
	shells += amount
	update_label()

# Take all shells (used at end of game to collect remaining pits)
func take_all_shells() -> int:
	var temp = shells
	shells = 0
	update_label()
	return temp

# Update the number display
func update_label():
	shell_label.text = str(shells)
