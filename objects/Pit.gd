extends Node2D

@onready var label = $ShellLabel
var shells: int = 0

func add_shells(amount: int):
	shells += amount
	update_label()

func set_shells(amount: int):
	shells = amount
	update_label()

func update_label():
	label.text = str(shells)
