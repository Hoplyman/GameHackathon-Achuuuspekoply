extends Node2D

@onready var label = $ShellLabel
var shells: int = 0
var pit_index: int = 0

func _ready():
	# Calculate pit index first
	var pits = get_tree().get_nodes_in_group("pitsC")
	pit_index = pits.find(self)
	if pit_index < 0:
		# Fallback: extract from name
		var name_str = name
		if name_str == "PitC":
			pit_index = 0
		else:
			var number_str = name_str.replace("PitC", "")
			if number_str != "":
				pit_index = int(number_str) - 1
			else:
				pit_index = 0
	
	# REMOVE THIS LINE:
	# shells = 7
	
	print("Pit ", pit_index, " initialized with ", shells, " shell count")
	
	update_label()
	update_shell_visibility()
	setup_click_area()

func setup_click_area():
	var click_area = get_node_or_null("ClickArea")
	if click_area and click_area.has_method("setup"):
		var pits = get_tree().get_nodes_in_group("pitsC")
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
	# Check if Shells container exists before trying to use it
	var shells_container = get_node_or_null("Shells")
	if not shells_container:
		# No Shells container found - this is normal for campaign mode
		# In campaign mode, shells are separate ShellC instances, not child nodes
		print("No Shells container in ", name, " - using dynamic shell system")
		return
	
	# Only run this if Shells container actually exists
	for i in range(1, 50):  # Shell1 to Shell50
		var shell_name = "Shell%d" % i
		var shell = shells_container.get_node_or_null(shell_name)
		if shell:
			shell.visible = i <= shells
func move_shells(player: int):
	if shells <= 0:
		print("Pit ", pit_index, " is empty, cannot move shells")
		return
	
	print("Moving ", shells, " shells from pit ", pit_index, " for player ", player)
	
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if not campaign:
		print("Error: Campaign node not found!")
		return
	
	# Find shells near this pit
	var shells_to_move = []
	var search_radius = 100.0  # Search radius
	
	for child in campaign.get_children():
		if child.is_in_group("Shells"):
			var distance = child.global_position.distance_to(global_position)
			if distance <= search_radius:
				shells_to_move.append(child)
	
	print("Found ", shells_to_move.size(), " shells near pit ", pit_index)
	
	if shells_to_move.is_empty():
		print("No shells found near pit! Creating shells...")
		create_shells_for_movement(player)
		return
	
	# Use the shell count from this pit as moves
	var moves_per_shell = shells
	var shells_moved = 0
	
	for shell in shells_to_move:
		if shells_moved >= shells:
			break
			
		if shell.has_method("assign_move"):
			shell.assign_move(moves_per_shell, player)
			shell.Pit = pit_index  # Set starting pit
			shells_moved += 1
			print("Assigned ", moves_per_shell, " moves to shell")
		else:
			print("Warning: Shell doesn't have assign_move method")
	
	# Empty this pit
	var old_shells = shells
	shells = 0
	update_label()
	update_shell_visibility()
	
	print("Pit ", pit_index, " emptied: ", old_shells, " -> ", shells)

func create_shells_for_movement(player: int):
	var shell_scene = preload("res://objects/ShellC.tscn")
	var campaign = get_tree().root.get_node("Campaign")
	
	var shells_to_create = shells
	var moves_per_shell = shells_to_create
	
	print("Creating ", shells_to_create, " shells for movement")
	
	for i in range(shells_to_create):
		var shell = shell_scene.instantiate()
		
		# Position shells directly in the center of the pit (no random offset)
		shell.position = global_position
		
		# Disable physics initially to prevent falling
		shell.gravity_scale = 0
		shell.freeze = true
		shell.collision_layer = 0  # Disable collision temporarily
		shell.collision_mask = 0
		
		campaign.add_child(shell)
		
		# Wait a frame for the shell to be ready
		await get_tree().process_frame
		
		if shell.has_method("assign_move"):
			shell.assign_move(moves_per_shell, player)
			shell.Pit = pit_index
		
		# Small delay between shell creation
		await get_tree().create_timer(0.1).timeout
	
	# Empty this pit
	shells = 0
	update_label()
	update_shell_visibility()

func get_shells() -> int:
	return shells

# Handle shells entering this pit area
func _on_shell_area_body_entered(body):
	if body.is_in_group("Shells") and not body.Moving:
		print("Shell entered pit ", pit_index, " - current count: ", shells)
		add_shells(1)

func _on_shell_area_body_exited(body):
	if body.is_in_group("Shells") and not body.Moving:
		print("Shell exited pit ", pit_index, " - current count: ", shells)
		# Only remove if we have shells to remove
		if shells > 0:
			shells -= 1
			update_label()
			update_shell_visibility()
		
func create_shells_in_formation(player: int):
	var shell_scene = preload("res://objects/ShellC.tscn")
	var campaign = get_tree().root.get_node("Campaign")
	
	var shells_to_create = shells
	var moves_per_shell = shells_to_create
	
	print("Creating ", shells_to_create, " shells in formation")
	
	for i in range(shells_to_create):
		var shell = shell_scene.instantiate()
		
		# Create a tight formation - shells very close to pit center
		var angle = (i * 2.0 * PI) / shells_to_create
		var radius = 5.0  # Very small radius to keep shells near pit center
		var offset = Vector2(cos(angle) * radius, sin(angle) * radius)
		shell.position = global_position + offset
		
		# Disable physics initially
		shell.gravity_scale = 0
		shell.freeze = true
		shell.collision_layer = 0
		shell.collision_mask = 0
		
		campaign.add_child(shell)
		
		# Wait a frame for the shell to be ready
		await get_tree().process_frame
		
		if shell.has_method("assign_move"):
			shell.assign_move(moves_per_shell, player)
			shell.Pit = pit_index
		
		# Very small delay
		await get_tree().create_timer(0.05).timeout
	
	# Empty this pit
	shells = 0
	update_label()
	update_shell_visibility()
