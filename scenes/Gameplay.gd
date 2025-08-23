extends Node2D

func set_shells(Shells: int,NewShells: int, x: int, y: int):
	var Pvp = get_tree().root.get_node_or_null("Gameplay")
	if Shells <= NewShells:
		var shell_scene = preload("res://objects/Shell.tscn")
		var AddShells = NewShells - Shells
		for j in range(AddShells):
			var shell_instance = shell_scene.instantiate()
			shell_instance.position = Vector2(x, y)  # Set shell position
			Pvp.add_child(shell_instance)  # Add directly to this node or adjust as needed
	elif Shells >= NewShells:
		var RemoveShells = Shells - NewShells
		remove_shells_near(RemoveShells,x, y, 30)  # Clear nearby shells first

func remove_shells_near(RemoveShells: int, x: int, y: int, radius: float):
	var center = Vector2(x, y)
	var nearby_shells := []

	# Step 1: Collect shells within radius
	for child in get_children():
		if child.name.begins_with("Shell"):
			var dist = child.position.distance_to(center)
			if dist <= radius:
				nearby_shells.append({"node": child, "distance": dist})

	# Step 2: Sort shells by distance to center
	nearby_shells.sort_custom(func(a, b): return a["distance"] < b["distance"])

	# Step 3: Remove the closest RemoveShells shells
	for i in range(min(RemoveShells, nearby_shells.size())):
		nearby_shells[i]["node"].queue_free()
		
func get_nearest_pit(x: float, y: float, radius: float) -> Node2D:
	var target_pos = Vector2(x, y)
	var nearest_pit: Node2D = null
	var min_distance = radius

	for node in get_tree().get_nodes_in_group("pits"):
		if node is Node2D and node.name.begins_with("Pit"):
			var dist = node.position.distance_to(target_pos)
			if dist <= min_distance:
				min_distance = dist
				nearest_pit = node
	return nearest_pit
	
func add_shells(x: int, y: int):
	var pit: Node2D = get_nearest_pit(x,y,10)
	var shell_scene = preload("res://objects/Shell.tscn")
	var shell_instance = shell_scene.instantiate()
	shell_instance.position = Vector2(x, y)  # Set shell position
	pit.add_child(shell_instance)  # Add directly to this node or adjust as needed)
