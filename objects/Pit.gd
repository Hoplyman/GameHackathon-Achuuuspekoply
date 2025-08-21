extends Node2D

@onready var label = $ShellLabel
var shells: int = 0

func _ready():
	update_label()
	setup_click_area()

func setup_click_area():
	# Look for ClickArea child node
	var click_area = get_node_or_null("ClickArea")
	if click_area and click_area.has_method("setup"):
		# Find our index in the pits array
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

func set_shells(amount: int):
	shells = amount
	update_label()

func update_label():
	if label:
		label.text = str(shells)
	else:
		print("Warning: ShellLabel not found in Pit")
