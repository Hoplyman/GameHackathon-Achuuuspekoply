extends Node2D

var shells: int = 0
var scores: int = 0

@onready var timer := $Timer  # Access the Timer node
@onready var label = $StoneLabel

func _ready():
	add_to_group("main_houses")
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()
	update_label()

func set_shells(amount: int):
	var oldshell = shells
	shells = amount
	spawn_shells(oldshell, shells)
	
func add_shells(amount: int):
	var oldshell = shells
	shells += amount
	spawn_shells(oldshell, shells)

# Take all shells (used at end of game to collect remaining pits)
func take_all_shells() -> int:
	var temp = shells
	shells = 0
	scores = 0  # Also reset scores when taking all shells
	update_label()
	return temp

# Take all scores (useful for game end calculations)
func take_all_scores() -> int:
	var temp = scores
	scores = 0
	update_label()
	return temp

func spawn_shells(shells: int, amount: int):
	var gamemode: String = ""
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var main_houses = get_tree().get_nodes_in_group("main_houses")
	var house_index = main_houses.find(self)
	
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		gamemode = ""
		
	if house_index != -1 and gamemode == "Campaign":
		var house_node = main_houses[house_index]
		var housex = house_node.position.x
		var housey = house_node.position.y
		campaign.set_shells(shells, housex, housey)
		print("MainHouse found in group")
	elif house_index != -1 and gamemode == "Pvp":
		var house_node = main_houses[house_index]
		var housex = house_node.position.x
		var housey = house_node.position.y
		pvp.set_shells(shells, amount, housex, housey)
		print("MainHouse found in group")
	else:
		print("MainHouse not found in group")
		return 0

func _on_timer_timeout():
	# No need to check timer.value — the timeout already means 1 second passed
	shells = count_shells_in_area()
	update_label()
	# Restart the timer to loop
	timer.start()

func count_shells_in_area() -> int:
	var cshells: int = 0
	var cscores: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	
	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					print("Shell overlapping in Campaign:", child.name)
					cshells += 1
					cscores += child.Score
		# Update scores before returning
		scores = cscores
		return cshells
		
	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					cshells += 1
					var cscore: int = child.get_score()
					cscores += cscore
		# Update scores before returning
		scores = cscores
		return cshells
	else:
		# Reset scores if no valid gamemode
		scores = 0
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
	var totalscores = scores
	if label:
		label.text = "Shells: " + str(shell_count) + " Score: " + str(totalscores)
	else:
		print("Warning: StoneLabel not found in MainHouse")
