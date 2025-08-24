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
		if child is RigidBody2D:
			var dist = child.position.distance_to(center)
			if dist <= radius:
				nearby_shells.append({"node": child, "distance": dist})

	# Step 2: Sort shells by distance to center
	nearby_shells.sort_custom(func(a, b): return a["distance"] < b["distance"])

	# Step 3: Remove the closest RemoveShells shells
	for i in range(min(RemoveShells, nearby_shells.size())):
		nearby_shells[i]["node"].queue_free()
	
func move_shells(pit_index: int, player: int):
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	if not pvp:
		return
	
	var shell_count: int = 0
	for child in pvp.get_children():
		if child.is_in_group("MoveShells"):
			shell_count += 1

	print("Total MoveShells:", shell_count)
	var current_index := pit_index
	if pit_index >= 7:
		current_index += 1

	while shell_count > 0:
		print("1 Shellcount " + str(shell_count))
		current_index += 1
		print("1 current_index " + str(current_index))
		var target_position: Vector2

		if current_index <= 7:
			target_position = pvp.get_node("Pit" + str(current_index)).global_position
			print("Moving to Pit " + str(current_index))
			
			for child in pvp.get_children():
				if child.is_in_group("MoveShells"):
					var tween := create_tween()
					print("Moving Shell")
					tween.tween_property(child, "global_position", target_position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					await tween.finished
					child.global_position = target_position
			randomize()
			var move_shells := []
			for child in pvp.get_children():
				if child.is_in_group("MoveShells"):
					move_shells.append(child)
					print("looking MoveShells " + str(child))
			# Change the group of one randomly selected child
			if move_shells.size() > 0:
				var selected_shell: RigidBody2D = move_shells[randi() % move_shells.size()]
				print("Group Change of Shell " + str(selected_shell))
				selected_shell.remove_from_group("MoveShells")
				selected_shell.add_to_group("Shells")
				print("2 Shellcount " + str(shell_count))
				shell_count -= 1
				print("3 Shellcount " + str(shell_count))
		elif current_index == 8:
			if player == 1:
				target_position = pvp.get_node_or_null("MainHouse1").global_position
				var tween := create_tween()
				for child in pvp.get_children():
					if child.is_in_group("MoveShells"):
						tween.tween_property(child, "global_position", target_position, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				await tween.finished
				randomize()
			var move_shells := []
			for child in pvp.get_children():
				if child.is_in_group("MoveShells"):
					move_shells.append(child)
			# Change the group of one randomly selected child
			if move_shells.size() > 0:
				var selected_shell: RigidBody2D = move_shells[randi() % move_shells.size()]
				selected_shell.remove_from_group("MoveShells")
				selected_shell.add_to_group("Shells")
				shell_count -= 1
			else:
				print("Skip")
		elif current_index >= 9 and current_index <= 15:
			target_position = pvp.get_node("Pit" + str(current_index - 1)).global_position
			var tween := create_tween()
			for child in pvp.get_children():
				if child.is_in_group("MoveShells"):
					tween.tween_property(child, "global_position", target_position, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tween.finished
			randomize()
			var move_shells := []
			for child in pvp.get_children():
				if child.is_in_group("MoveShells"):
					move_shells.append(child)
			# Change the group of one randomly selected child
			if move_shells.size() > 0:
				var selected_shell: RigidBody2D = move_shells[randi() % move_shells.size()]
				selected_shell.remove_from_group("MoveShells")
				selected_shell.add_to_group("Shells")
				shell_count -= 1
		elif current_index == 16:
			if player == 2:
				target_position = pvp.get_node_or_null("MainHouse2").global_position
				var tween := create_tween()
				for child in pvp.get_children():
					if child.is_in_group("MoveShells"):
						tween.tween_property(child, "global_position", target_position, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				await tween.finished
				randomize()
			var move_shells := []
			for child in pvp.get_children():
				if child.is_in_group("MoveShells"):
					move_shells.append(child)
			# Change the group of one randomly selected child
			if move_shells.size() > 0:
				var selected_shell: RigidBody2D = move_shells[randi() % move_shells.size()]
				selected_shell.remove_from_group("MoveShells")
				selected_shell.add_to_group("Shells")
				shell_count -= 1
			else:
				print("Skip")
		else:
			current_index = 0
