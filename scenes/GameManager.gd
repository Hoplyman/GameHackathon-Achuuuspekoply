extends Node

var current_turn: int = 0
var pits: Array

func _ready():
	pits = get_tree().get_nodes_in_group("pits")
	start_game()

func start_game():
	for pit in pits:
		pit.add_shells(7)  # put 7 shells in each pit
