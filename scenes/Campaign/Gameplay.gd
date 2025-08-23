extends Node2D

func set_shells(Shells: int, x: int, y: int):
	remove_shells_near(x, y, 5)  # Clear nearby shells first
	var shell_scene = preload("res://objects/Shell.tscn")

	for j in range(Shells):
		var shell_instance = shell_scene.instantiate()
		shell_instance.position = Vector2(x, y)  # Set shell position
		add_child(shell_instance)  # Add directly to this node or adjust as needed

func remove_shells_near(x: int, y: int, radius: float):
	var pit: Node2D = get_nearest_pit(x, y, radius)
	var center = Vector2(x, y)
	for child in get_children():
		if child.name.begins_with("Shell"):
			if child.position.distance_to(center) <= radius:
				child.queue_free()
			
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
	var shell_scene = preload("res://objects/Shell.tscn")
	var shell_instance = shell_scene.instantiate()
	shell_instance.position = Vector2(x, y)  # Set shell position
	add_child(shell_instance)  # Add directly to this node or adjust as needed)
