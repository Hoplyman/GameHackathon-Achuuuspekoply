extends Node2D

var shells: int = 0
var use_timer_counting: bool = true
var initialization_complete: bool = false  # NEW: Track initialization state

@onready var timer := $Timer
@onready var label = $ShellLabel

func _ready():
	setup_click_area()	
	add_to_group("pits")
	# CRITICAL FIX: Stop timer immediately and disable timer counting from the start
	use_timer_counting = false
	timer.stop()
	# Don't connect timer signal until explicitly enabled
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
	# This is called by GameManager during initialization
	use_timer_counting = false
	initialization_complete = false  # Mark as initializing
	
	# CRITICAL FIX: Force stop timer and disconnect signal immediately
	timer.stop()
	if timer.timeout.is_connected(_on_timer_timeout):
		timer.disconnect("timeout", _on_timer_timeout)
	
	# Force an immediate update without counting to prevent the brief "14" display
	shells = amount  # Set directly without spawning
	update_label()  # Update display immediately
	
	# Now spawn the visual shells
	var oldshell = 0  # Always start from 0 during initialization
	spawn_shells(oldshell, shells)
	
	# Mark initialization as complete
	initialization_complete = true
	print("Pit initialized with ", amount, " shells")

func enable_timer_counting():
	"""Called by GameManager after all initialization is complete"""
	if initialization_complete and not use_timer_counting:
		use_timer_counting = true
		# Connect the timer signal if not already connected
		if not timer.timeout.is_connected(_on_timer_timeout):
			timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		
		# Do one immediate count to sync, then start the timer
		var current_count = count_shells_in_area()
		if current_count != shells:
			print("Timer sync: Pit ", name, " correcting from ", shells, " to ", current_count)
			shells = current_count
			update_label()
		
		timer.start()
		print("Timer counting enabled for ", name, " with ", shells, " shells")
	
func add_shells(amount):
	# This is called by GameManager during gameplay
	use_timer_counting = false
	if timer.is_connected("timeout", _on_timer_timeout):
		timer.disconnect("timeout", _on_timer_timeout)
	timer.stop()
	
	var oldshell = shells
	shells += amount
	spawn_shells(oldshell, shells)
	update_label()
	print("Pit: Added ", amount, " shells. Total: ", shells)
	
func move_shells(player: int):
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					print("Removing shell from Campaign:", child.name)
					child.queue_free()
		shells = 0
		update_label()
		return 0

	elif gamemode == "Pvp":
		var totalmove = 1
		var shells_to_remove = []
		
		for child in pvp.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					print("Shell overlapping in Pvp:", child.name)
					shells_to_remove.append(child)
		
		for child in shells_to_remove:
			child.remove_from_group("Shells")
			child.add_to_group("MoveShells")
			child.assign_move(totalmove, player)
			totalmove += 1
		
		print("Pit ", name, " - Started moving ", shells_to_remove.size(), " shells")
		return 0
	else:
		shells = 0
		update_label()
		return 0

func spawn_shells(old_count: int, new_count: int):
	var gamemode: String = ""
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var pits = get_tree().get_nodes_in_group("pits")
	var pit_index = pits.find(self)
	
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	if pit_index != -1 and gamemode == "Campaign":
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		campaign.set_shells(old_count, pitx, pity)
		print("Pit found in group")
	elif pit_index != -1 and gamemode == "Pvp":
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		
		# Clear existing shells during initialization only
		if old_count == 0 and new_count > 0 and not initialization_complete:
			clear_existing_shells_in_area()
		
		pvp.set_shells(old_count, new_count, pitx, pity)
		print("Pit found in group - updating from ", old_count, " to ", new_count, " shells at position (", pitx, ", ", pity, ")")
	else:
		print("Pit not found in group")
		return 0

func clear_existing_shells_in_area():
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		return
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	var shells_to_remove = []
	
	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells") and child in overlapping_bodies:
				shells_to_remove.append(child)
	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.is_in_group("Shells") and child in overlapping_bodies:
				shells_to_remove.append(child)
	
	for shell in shells_to_remove:
		shell.queue_free()
		print("Removed existing shell during initialization")

func _on_timer_timeout():
	# Only count if timer counting is enabled AND initialization is complete
	if not use_timer_counting or not initialization_complete:
		return
		
	var new_shell_count = count_shells_in_area()
	if new_shell_count != shells:
		shells = new_shell_count
		update_label()
	timer.start()

func count_shells_in_area() -> int:
	var cshells: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					cshells += 1
		return cshells

	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					cshells += 1
		return cshells
	else:
		return 0

func _on_shell_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("Shells"):
		print("Shell entered pit ", name, ": ", body.name)
		
		# FIXED: Always update shell count when a shell enters, regardless of timer mode
		await get_tree().create_timer(0.1).timeout  # Small delay for physics to settle
		
		if use_timer_counting:
			# Let timer handle the counting
			return
		else:
			# Manually count shells in area
			var new_count = count_shells_in_area()
			if new_count != shells:
				shells = new_count
				update_label()
				print("Updated pit ", name, " to ", shells, " shells")

func _on_shell_area_body_exited(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("Shells"):
		print("Shell exited pit ", name, ": ", body.name)
		
		# FIXED: Always update shell count when a shell exits
		await get_tree().create_timer(0.1).timeout  # Small delay for physics to settle
		
		if use_timer_counting:
			# Let timer handle the counting
			return
		else:
			# Manually count shells in area
			var new_count = count_shells_in_area()
			if new_count != shells:
				shells = new_count
				update_label()
				print("Updated pit ", name, " to ", shells, " shells")
		
func update_label():
	var shell_count = shells
	if label:
		label.text = str(shell_count)
	else:
		print("Warning: ShellLabel not found in Pit")
