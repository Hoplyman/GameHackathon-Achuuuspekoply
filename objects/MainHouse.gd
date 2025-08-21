extends Node2D

# Holds how many shells are in this main house
var shells: int = 0

@onready var shell_label: Label = $StoneLabel

func _ready():
	update_label()
	update_shell_visibility()

# Add shells
func add_shells(amount: int):
	shells += amount
	update_label()
	update_shell_visibility()

# Take all shells (used at end of game to collect remaining pits)
func take_all_shells() -> int:
	var temp = shells
	shells = 0
	update_label()
	update_shell_visibility()
	return temp

# Update the number display
func update_label():
	shell_label.text = str(shells)

# Show Shell1–Shell37 based on current shell count
func update_shell_visibility():
	for i in range(1, 38):  # Shell1 to Shell37
		var shell_name = "Shell%d" % i
		var shell = get_node_or_null(shell_name)
		if shell:
			shell.visible = i <= shells
