extends Node2D

# Shell distribution settings
const SHELL_MOVE_SPEED = 400.0  # pixels per second
const SHELL_DROP_DELAY = 0.2    # seconds between each shell drop

func set_shells(Shells: int, NewShells: int, x: int, y: int):
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() > 0 and game_manager[0].is_distributing:
		print("Game is distributing - skipping visual shell creation")
		return
	var Pvp = get_tree().root.get_node_or_null("Gameplay")
	if not Pvp:
		Pvp = self
	
	# SAFETY CHECK: Don't create shells if the counts are the same
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
	
	# Clear the selected pit immediately
	selected_pit.set_shells(0)
	
	# Create distribution sequence
	await distribute_shells_smoothly(shells_to_move, pit_index, game_manager)

func distribute_shells_smoothly(shells_to_move: int, start_pit_index: int, game_manager: Node):
	var current_position = start_pit_index
	var last_position = start_pit_index
	
	for i in range(shells_to_move):
		# Get next position
		current_position = game_manager.get_next_position(current_position)
		last_position = current_position
		
		# Get source and target positions
		var source_pos = get_source_position(i == 0, start_pit_index, current_position, game_manager)
		var target_node = game_manager.get_position_node(current_position)
		
		if not target_node:
			print("Target node not found for position: ", current_position)
			continue
		
		# Create and animate shell
		await create_and_animate_shell(source_pos, target_node.global_position, current_position, game_manager)
		
		# Small delay between shells for smooth visual flow
		if i < shells_to_move - 1:  # Don't delay after the last shell
			await get_tree().create_timer(SHELL_DROP_DELAY).timeout
	
	print("Shell distribution complete. Last position: ", last_position)
	
	# Notify GameManager that distribution is complete
	if game_manager.has_method("on_shell_distribution_complete"):
		game_manager.on_shell_distribution_complete(last_position)

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

func create_and_animate_shell(start_pos: Vector2, end_pos: Vector2, target_position: int, game_manager: Node):
	# Create visual shell
	var shell_scene = preload("res://objects/Shell.tscn")
	var shell_instance = shell_scene.instantiate()
	shell_instance.global_position = start_pos
	add_child(shell_instance)
	
	# Calculate movement duration based on distance
	var distance = start_pos.distance_to(end_pos)
	var duration = distance / SHELL_MOVE_SPEED
	duration = clamp(duration, 0.1, 0.8)  # Minimum 0.1s, maximum 0.8s
	
	# Animate shell movement with easing
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(shell_instance, "global_position", end_pos, duration)
	await tween.finished
	
	# FIXED: Update target pit/house shell count WITHOUT creating any visual shells
	if target_position < 14:  # Regular pit
		var target_pit = game_manager.get_pit(target_position)
		if target_pit:
			# DIRECTLY modify the shells property - bypass any methods that might create visuals
			target_pit.shells += 1
			print("Updated pit ", target_position, " shell count to: ", target_pit.shells)
			
			# Only update the label display, don't create shells
			if target_pit.has_node("Label"):
				var label = target_pit.get_node("Label")
				label.text = str(target_pit.shells)
			elif target_pit.has_method("update_label_only"):
				target_pit.update_label_only()
	else:  # Main house
		var house_index = 0 if target_position == 14 else 1
		var target_house = game_manager.get_main_house(house_index)
		if target_house:
			# DIRECTLY modify the shells property for main house too
			if target_house.has_method("get_shells"):
				var current_shells = target_house.get_shells()
				target_house.shells = current_shells + 1
			else:
				# Fallback: try to access shells property directly
				if "shells" in target_house:
					target_house.shells += 1
			
			print("Updated main house ", house_index, " shell count")
			
			# Update label only
			if target_house.has_method("update_label"):
				target_house.update_label()
	
	# Remove the animated shell since the pit/house now shows the shell count visually
	shell_instance.queue_free()
	
	print("Shell placed at position ", target_position)
