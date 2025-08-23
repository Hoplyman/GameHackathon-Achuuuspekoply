extends Node2D

@onready var label = $ShellLabel
@onready var shell_area = $GravityArea

var shells: int = 0
var fshells: int = 0

func _ready():
	update_label()
	setup_click_area()	
	add_to_group("pits")

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
	var gamemode: String = ""
	var pvp = get_tree().root.get_node("Gameplay")
	var campaign = get_tree().root.get_node("Campaign")
	var pits = get_tree().get_nodes_in_group("pits")
	var pit_index = pits.find(self)
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif  pvp:
		print("Gameplay found!")
		gamemode = ("Pvp")
	else:
		gamemode = ""
	if pit_index != -1 and gamemode == "Campaign":
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		campaign.set_shells(shells, pitx, pity)
		print("Pit found in group")
	elif pit_index != -1 and gamemode == "Pvp":
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		pvp.set_shells(shells, pitx, pity)
		print("Pit found in group")
	else:
		print("Pit not found in group")
		return 0

func update_label():
	var shell_count = fshells
	if label:
		label.text = str(shell_count)
	else:
		print("Warning: ShellLabel not found in Pit")
		
func count_shells_in_area() -> int:
	var gamemode: String = ""
	var pvp = get_tree().root.get_node("Gameplay")
	var campaign = get_tree().root.get_node("Campaign")
	fshells = 0
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif  pvp:
		print("Gameplay found!")
		gamemode = ("Pvp")
	else:
		gamemode = ""
	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.name.begins_with("Shell"):  # Or use `is Shell` if you use a script class
				if shell_area and shell_area.overlaps_body(child):
					fshells += 1
		return fshells
	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.name.begins_with("Shell"):  # Or use `is Shell` if you use a script class
				if shell_area and shell_area.overlaps_body(child):
					fshells += 1
		return fshells
	else:
		return 0
	

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
