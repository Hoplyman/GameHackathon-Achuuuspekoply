extends Node2D

@onready var label = $ShellLabel
@onready var shell_area = $GravityArea

var shells: int = 0
var fshells: int = 0

func _ready():
	update_label()
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

func set_shells(amount: int):
	shells = amount
	update_label()
	spawn_shells()
	
func add_shells(amount: int):
	shells += amount
	update_label()
	spawn_shells()

func spawn_shells():
	var gameplay = get_tree().root.get_node("Gameplay")  # Adjust path as needed
	var pits = get_tree().get_nodes_in_group("pits")
	var pit_index = pits.find(self)

	if pit_index != -1:
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		gameplay.set_shells(shells, pitx, pity)
	else:
		print("Pit not found in group!")

	
func update_label():
	var shell_count = fshells
	if label:
		label.text = str(shell_count)
	else:
		print("Warning: ShellLabel not found in Pit")
		
func count_shells_in_area() -> int:
	var shell_area = get_node_or_null("GravityArea")
	var gameplay = get_tree().root.get_node("Gameplay")  # Adjust path as needed
	fshells = 0
	for child in gameplay.get_children():
		if child.name.begins_with("Shell"):  # Or use `is ShellClass` if applicable
			if shell_area.overlaps_body(child):  # Checks if the shell is inside the Area2D
				fshells += 1
	return fshells

func _on_gravity_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		print("RigidBody2D entered:", body.name)
		var shell_count := count_shells_in_area()
		print("Shells in area:", shell_count)

func _on_gravity_area_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		print("RigidBody2D exited:", body.name)
		var shell_count := count_shells_in_area()
		print("Shells in area after exit:", shell_count)
