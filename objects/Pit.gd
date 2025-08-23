extends Node2D

var shells: int = 0

@onready var timer := $Timer  # Access the Timer node
@onready var label = $ShellLabel

func _ready():
	setup_click_area()	
	add_to_group("pits")
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()
	update_label()

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
	var oldshell = shells
	shells = amount
	spawn_shells(oldshell, shells)
	
func add_shells(amount: int):
	var oldshell = shells
	shells += amount
	spawn_shells(oldshell, shells)
	
func move_shells():
	pass

func spawn_shells(shells:int ,amount: int):
	var gamemode: String = ""
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var pvp = get_tree().root.get_node_or_null("Gameplay")
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
		pvp.set_shells(shells, amount, pitx, pity)
		print("Pit found in group")
	else:
		print("Pit not found in group")
		return 0

func _on_timer_timeout():
	print("Timer triggered!")

	# No need to check timer.value — the timeout already means 1 second passed
	shells = count_shells_in_area()
	update_label()
	print("Shells in area:", shells)

	var value := 0
	print("Value reset to:", value)
	# Restart the timer to loop
	timer.start()

func count_shells_in_area() -> int:
	var cshells: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	shells = 0
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif  pvp:
		print("Gameplay found!")
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child is RigidBody2D:
				if child in overlapping_bodies:
					print("Shell overlapping in Campaign:", child.name)
					cshells += 1
		return cshells

	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child is RigidBody2D:
				if child in overlapping_bodies:
					print("Shell overlapping in Pvp:", child.name)
					cshells += 1
		return cshells
	else:
		return 0


func _on_shell_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		print("RigidBody2D entered:", body.name)
		update_label()

func _on_shell_area_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		print("RigidBody2D exited:", body.name)
		update_label()
		
func update_label():
	var shell_count = shells
	if label:
		label.text = str(shell_count)
	else:
		print("Warning: ShellLabel not found in Pit")
