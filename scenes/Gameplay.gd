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
	if not Pvp:
		Pvp = self
		
	var PitNode: Node2D
	if pit == 15:
		PitNode = Pvp.get_node_or_null("MainHouse1")
	elif pit == 16:
		PitNode = Pvp.get_node_or_null("MainHouse2")
	else:
		PitNode = Pvp.get_node_or_null("Pit" + str(pit))
	
	if not PitNode:
		print("ERROR: Could not find target node for pit ", pit)
		return
		
	var PitPosition = PitNode.global_position
	
	# Add some random offset so the shell doesn't spawn exactly at center
	var random_offset = Vector2(
		randf_range(-20, 20),
		randf_range(-20, 20)
	)
	PitPosition += random_offset
	
	var shell_scene = preload("res://objects/Shell.tscn")
	var shell_instance = shell_scene.instantiate()
	shell_instance.position = Vector2(PitPosition)
	shell_instance.Type = type
	
	# Make sure the shell has the correct type set
	Pvp.add_child(shell_instance)
	
	# Wait a frame and then set the shell type properly
	await get_tree().process_frame
	if shell_instance and shell_instance.has_method("set_shell_type"):
		shell_instance.set_shell_type(type)
	
	print("Spawned special shell type ", type, " at pit ", pit, " position: ", PitPosition)

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
			shell_instance.Type = 10 #randi_range(1,12)
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
