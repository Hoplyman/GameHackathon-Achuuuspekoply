extends Node2D

# Shell distribution settings
const SHELL_MOVE_SPEED = 600.0     # Increased from 400 pixels per second
const SHELL_DROP_DELAY = 0.05   # seconds between each shell drop

func spawn_shell(type: int, pit: int):
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() > 0 and game_manager[0].is_distributing:
		print("Game is distributing - skipping visual shell creation")
		return
	var Pvp = get_tree().root.get_node_or_null("Gameplay")
	var PitNode: Node2D
	if pit == 15:
		PitNode = Pvp.get_node_or_null("MainHouse2")
	elif pit == 16:
		PitNode = Pvp.get_node_or_null("MainHouse2")
	else:
		PitNode = Pvp.get_node_or_null("Pit" + str(pit))
	var PitPosition = PitNode.global_position
	var shell_scene = preload("res://objects/Shell.tscn")
	var shell_instance = shell_scene.instantiate()
	shell_instance.position = Vector2(PitPosition)
	shell_instance.Type = type
	Pvp.add_child(shell_instance)

func set_shells(Shells: int, NewShells: int, x: int, y: int):
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() > 0 and game_manager[0].is_distributing:
		print("Game is distributing - skipping visual shell creation")
		return
	var Pvp = get_tree().root.get_node_or_null("Gameplay")
	if not Pvp:
		Pvp = self
	
	if Shells == NewShells:
		print("Shell counts are equal (", Shells, "), skipping shell creation")
		return
		
	if Shells < NewShells:
		var shell_scene = preload("res://objects/Shell.tscn")
		var AddShells = NewShells - Shells
		print("Creating ", AddShells, " shells at position (", x, ", ", y, ")")
		
		for j in range(AddShells):
			var shell_instance = shell_scene.instantiate()
			shell_instance.position = Vector2(x, y)
			shell_instance.Type = randi_range(1,12)
			Pvp.add_child(shell_instance)
			print("Created shell ", j + 1, " of ", AddShells)
			
	elif Shells > NewShells:
		var RemoveShells = Shells - NewShells
		print("Removing ", RemoveShells, " shells from position (", x, ", ", y, ")")
		remove_shells_near(RemoveShells, x, y, 30)
		
func remove_shells_near(RemoveShells: int, x: int, y: int, radius: float):
	var center = Vector2(x, y)
	var nearby_shells := []

	for child in get_children():
		if child is RigidBody2D:
			var dist = child.position.distance_to(center)
			if dist <= radius:
				nearby_shells.append({"node": child, "distance": dist})

	nearby_shells.sort_custom(func(a, b): return a["distance"] < b["distance"])

	for i in range(min(RemoveShells, nearby_shells.size())):
		nearby_shells[i]["node"].queue_free()

func move_shells(pit_index: int, player: int):
	print("Starting move_shells for pit_index: ", pit_index, " player: ", player)
	
	var game_manager = get_node_or_null("GameManager")
	if not game_manager:
		print("GameManager not found!")
		return
	
	var selected_pit = game_manager.get_pit(pit_index)
	if not selected_pit or selected_pit.shells <= 0:
		print("No shells to move from pit ", pit_index)
		return
	
	var shells_to_move = selected_pit.shells
	print("Moving ", shells_to_move, " shells from pit ", pit_index)
	
	selected_pit.set_shells(0)
	await distribute_shells_smoothly(shells_to_move, pit_index, game_manager)

func distribute_shells_smoothly(shells_to_move: int, start_pit_index: int, game_manager: Node):
	var current_position = start_pit_index
	var last_position = start_pit_index
	
	for i in range(shells_to_move):
		current_position = game_manager.get_next_position(current_position)
		last_position = current_position
		
		var source_pos = get_source_position(i == 0, start_pit_index, current_position, game_manager)
		var target_node = game_manager.get_position_node(current_position)
		

func get_source_position(is_first_shell: bool, start_pit_index: int, current_position: int, game_manager: Node) -> Vector2:
	if is_first_shell:
		# First shell comes from the original pit
		var source_pit = game_manager.get_pit(start_pit_index)
		return source_pit.global_position if source_pit else Vector2.ZERO
	else:
		# Subsequent shells appear to come from the previous position
		var prev_position = get_previous_position(current_position, game_manager)
		var prev_node = game_manager.get_position_node(prev_position)
		return prev_node.global_position if prev_node else Vector2.ZERO

func get_previous_position(current_pos: int, game_manager: Node) -> int:
	# This is the reverse of get_next_position logic
	if current_pos == 0:  # At player 1's first pit
		return 15  # Came from player 2's main house
	elif current_pos <= 6:  # In player 1's pits
		return current_pos - 1
	elif current_pos == 7:  # At player 2's first pit
		if game_manager.current_turn == 1:  # Player 2's turn
			return 14  # Came from player 1's main house (skipped player 1's main house)
		else:
			return 6  # Came from player 1's last pit
	elif current_pos <= 13:  # In player 2's pits
		return current_pos - 1
	elif current_pos == 14:  # Player 1's main house
		return 6  # Came from player 1's last pit
	elif current_pos == 15:  # Player 2's main house
		return 13  # Came from player 2's last pit
	
	return current_pos - 1  # Default fallback
