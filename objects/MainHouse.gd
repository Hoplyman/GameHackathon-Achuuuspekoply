extends Node2D

var shells: int = 0
var scores: int = 0
var use_timer_counting: bool = true  # Flag to control counting method
var use_visual_spawning: bool = false  # NEW: Flag to control visual shell spawning

@onready var timer := $Timer  # Access the Timer node
@onready var label = $StoneLabel
@onready var House_Sprite := $HouseSprite  # NEW: Reference to house sprite node

func _ready():
	add_to_group("main_houses")
	setup_click_area()  # NEW: Setup click area for tooltip
	# Only connect timer if we're using timer-based counting
	if use_timer_counting:
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		timer.start()
	update_label()

# NEW: Setup click area for tooltip functionality
func setup_click_area():
	var click_area = get_node_or_null("ClickArea")
	if click_area and click_area.has_method("setup"):
		var main_houses = get_tree().get_nodes_in_group("main_houses")
		var house_index = main_houses.find(self)
		if house_index >= 0:
			click_area.setup(self, house_index)
			print("Setup click area with hover for MainHouse ", house_index)
	else:
		print("Warning: No ClickArea found in MainHouse ", name)

func set_shells(amount: int):
	var oldshell = shells
	shells = amount
	# Only spawn visual shells if we're in visual spawning mode
	if use_visual_spawning:
		spawn_shells(oldshell, shells)
	update_label()  # Update label immediately
	
func add_shells(amount: int):
	# This is called by GameManager - disable timer counting to avoid double counting
	use_timer_counting = false
	if timer.is_connected("timeout", _on_timer_timeout):
		timer.disconnect("timeout", _on_timer_timeout)
	timer.stop()
	
	var oldshell = shells
	shells += amount
	
	# CRITICAL FIX: Don't spawn visual shells when physical shells are being used
	# The physical shells already exist and moved here, we just need to update the counter
	print("MainHouse: Added ", amount, " shells. Total: ", shells, " (no visual spawning)")
	
	update_label()

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

func spawn_shells(old_shells: int, new_shells: int):
	# Only spawn visual shells if explicitly enabled
	if not use_visual_spawning:
		print("Visual spawning disabled - skipping shell spawn")
		return
		
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
		campaign.set_shells(old_shells, housex, housey)
		print("MainHouse found in group")
	elif house_index != -1 and gamemode == "Pvp":
		var house_node = main_houses[house_index]
		var housex = house_node.position.x
		var housey = house_node.position.y
		pvp.set_shells(old_shells, new_shells, housex, housey)
		print("MainHouse found in group")
	else:
		print("MainHouse not found in group")
		return 0

# NEW: Function to enable visual spawning mode (for initialization only)
func enable_visual_spawning():
	use_visual_spawning = true
	print("Visual spawning enabled for MainHouse")

# NEW: Function to disable visual spawning mode (for gameplay)
func disable_visual_spawning():
	use_visual_spawning = false
	print("Visual spawning disabled for MainHouse")

# NEW: House effect functions (similar to pit effects)

func _on_timer_timeout():
	# Only count if timer counting is enabled
	if not use_timer_counting:
		return
		
	# No need to check timer.value – the timeout already means 1 second passed
	var new_shell_count = count_shells_in_area()
	if new_shell_count != shells:
		shells = new_shell_count
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
					cscores += child.TotalScore
		# Update scores before returning
		scores = cscores
		return cshells
		
	elif gamemode == "Pvp":
		for child in pvp.get_children():
			# CRITICAL FIX: Only count shells that are NOT currently moving
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
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
	if body is RigidBody2D and use_timer_counting:
		print("RigidBody2D entered:", body.name)
		# Small delay to let physics settle
		await get_tree().create_timer(0.1).timeout
		update_label()

func _on_shell_area_body_exited(body: Node2D) -> void:
	if body is RigidBody2D and use_timer_counting:
		print("RigidBody2D exited:", body.name)
		# Small delay to let physics settle
		await get_tree().create_timer(0.1).timeout
		update_label()
		
func update_label():
	var shell_count = shells
	var totalscores = scores
	if label:
		# NEW: Include house type in the label display
		label.text = "Shells: " + str(shell_count) + " Points: " + str(totalscores)
	else:
		print("Warning: StoneLabel not found in MainHouse")
