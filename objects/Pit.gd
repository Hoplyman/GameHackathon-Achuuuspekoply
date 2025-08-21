extends Node2D

@onready var label = $ShellLabel
var shells: int = 0

func _ready():
	update_label()
	update_shell_visibility()
	setup_click_area()

func setup_click_area():
	var click_area = get_node_or_null("ClickArea")
	if click_area and click_area.has_method("setup"):
		var pits = get_tree().get_nodes_in_group("pits")
		var pit_index = pits.find(self)
		if pit_index >= 0:
			click_area.setup(self, pit_index)
			print("Setup click area for pit ", pit_index)
	else:
		print("Warning: No ClickArea found in ", name)

func add_shells(amount: int):
	shells += amount
	update_label()
	update_shell_visibility()

func set_shells(amount: int):
	shells = amount
	update_label()
	update_shell_visibility()

func update_label():
	if label:
		label.text = str(shells)
	else:
		print("Warning: ShellLabel not found in Pit")

func update_shell_visibility():
	var shells_container = get_node("Shells")
	for i in range(1, 37):  # Shell1 to Shell37
		var shell_name = "Shell%d" % i
		var shell = shells_container.get_node_or_null(shell_name)
		if shell:
			shell.visible = i <= shells
