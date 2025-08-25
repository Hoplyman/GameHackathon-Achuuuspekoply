extends RigidBody2D

var Moving: bool = false # is Moving 
var Player: int = 0 # whose player turn for turn purposes
var Pit: int = 0 # what Pit is the Shell is in
var Move: int = 0 # number of Moves 
var Score: int = 0 # total score to tally when in Pits
var Type: int = 1 # CHANGED: Start with normal shell type (1)
var shellsprite: Sprite2D # the sprite of Shell
var waiting_for_timer: bool = false  # New variable to track timer waiting
var is_echo_duplicate: bool = false  # Track if this is an Echo duplicate

@onready var movetimer := $MoveTimer
@onready var scoretimer := $ScoreTimer
@onready var labelscore := $Container/Score
@onready var labeleffect := $Container/Effect
@onready var shell_sprite := $ShellSprite  # Use @onready for proper initialization

# Movement variables
var move_target: Vector2
var move_speed: float = 200.0
var arrival_threshold: float = 10.0

func _ready() -> void:
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# CHANGED: Always start with normal shell type (1) unless it's an Echo duplicate
	if not is_echo_duplicate:
		Type = 1  # Normal shell
	shellsprite = shell_sprite  # Assign the @onready reference
	
	# Update appearance and score
	update_shell_frame()
	set_score()
	set_pit()
	
	add_to_group("Shells")  # Fixed: was "Shell", should be "Shells"
	
	# Fix: Check if signal is already connected before connecting
	if not movetimer.timeout.is_connected(_on_move_timer_timeout):
		movetimer.connect("timeout", Callable(self, "_on_move_timer_timeout"))
	if not scoretimer.timeout.is_connected(_on_score_timer_timeout):
		scoretimer.connect("timeout", Callable(self, "_on_score_timer_timeout"))
	
	print("Shell initialized with type: ", Type)

func shell_drop():
	if Type == 1:
		Score += 1
	elif Type == 2:
		if Pit == 25 or Pit == 16:
			Score += 5
		else:
			Score += 1
	elif Type == 3:
		# FIXED: Only trigger Echo effect if this is NOT already a duplicate
		if not is_echo_duplicate:
			trigger_echo_effect()
		else:
			# This is already an Echo duplicate, just add normal score
			Score += 1
	elif Type == 4:
		Score *= 2
		labeleffect.text = "ANCHOR"
		labeleffect.modulate = Color(0.0, 0.0, 1.0, 0.0)  # Blue but transparent
		labeleffect.visible = true
		# Create tween for fade in and fade out
		var tween = create_tween()
		tween.tween_property(labeleffect, "modulate:a", 1.0, 0.2)  # Fade in over 0.2 seconds
		tween.tween_interval(2.0)  # Stay visible for 2 seconds
		tween.tween_property(labeleffect, "modulate:a", 0.0, 0.5)  # Fade out over 0.5 seconds
		tween.tween_callback(func(): labeleffect.visible = false)

func trigger_echo_effect():
	# Show ECHO effect label FIRST
	labeleffect.text = "ECHO"
	labeleffect.modulate = Color(1.0, 0.0, 0.0, 1.0)  # Full red, fully visible
	labeleffect.visible = true

	# Create tween for the label effect
	var label_tween = create_tween()
	label_tween.tween_interval(1.5)  # Show for 1.5 seconds
	label_tween.tween_property(labeleffect, "modulate:a", 0.0, 0.5)  # Fade out
	label_tween.tween_callback(func(): labeleffect.visible = false)

	# Wait a bit for physics to settle before creating duplicate
	await get_tree().create_timer(0.2).timeout

	# FIXED: Create the duplicate shell properly positioned within the current pit
	create_echo_duplicate()

func create_echo_duplicate():
	# Find the current pit this shell is in
	var current_pit = find_current_pit()
	if not current_pit:
		print("Echo shell could not find current pit for duplication")
		return

	# Create the duplicate
	var Echo_Dup = self.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
	
	# CRITICAL: Mark it as an Echo duplicate to prevent infinite duplication
	Echo_Dup.is_echo_duplicate = true
	Echo_Dup.Type = 3  # Keep it as Echo type but prevent further duplication
	
	# Add to the current scene
	get_parent().add_child(Echo_Dup)
	
	# Wait for the duplicate to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# NEW: Position the duplicate at a spawn location (above the pit or to the side)
	var pit_position = current_pit.global_position
	var spawn_offset = Vector2(randf_range(-50, 50), -100)  # Spawn above with some randomness
	Echo_Dup.global_position = pit_position + spawn_offset
	
	# Reset the duplicate's state
	Echo_Dup.Moving = false
	Echo_Dup.Move = 0  # Start with no moves
	Echo_Dup.Player = 0
	Echo_Dup.waiting_for_timer = false
	
	# Set the correct starting pit (where it spawned, not the target)
	# We'll calculate this based on spawn position or use a "spawn pit" concept
	Echo_Dup.Pit = get_pit_number_from_node(current_pit)
	
	# Make sure it's in the right group initially
	Echo_Dup.remove_from_group("MoveShells") 
	Echo_Dup.add_to_group("Shells")
	
	# Set up proper physics
	Echo_Dup.collision_layer = 2
	Echo_Dup.collision_mask = 22
	Echo_Dup.gravity_scale = 1
	Echo_Dup.freeze = false
	Echo_Dup.linear_velocity = Vector2.ZERO
	Echo_Dup.angular_velocity = 0
	
	# Update its appearance
	Echo_Dup.update_shell_frame()
	
	print("Echo duplicate created at spawn position: ", Echo_Dup.global_position)
	
	# NEW: Use assign_move() to move the duplicate to the target pit!
	# Give it 1 move to animate to the target pit
	await get_tree().create_timer(0.2).timeout  # Small delay before starting movement
	Echo_Dup.assign_move(1, Player)  # Use the same player and 1 move

func get_pit_number_from_node(pit_node: Node2D) -> int:
	if not pit_node:
		return 1
	
	var pit_name = pit_node.name
	var pit_number = pit_name.replace("Pit", "")
	return int(pit_number) if pit_number.is_valid_int() else 1

func find_current_pit() -> Node2D:
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		return null
	
	# Check all pits to find which one this shell is currently in
	var pits = get_tree().get_nodes_in_group("pits")
	
	for pit in pits:
		if pit and pit.has_node("ShellArea"):
			var shell_area = pit.get_node("ShellArea")
			var overlapping_bodies = shell_area.get_overlapping_bodies()
			
			if self in overlapping_bodies:
				print("Found shell in pit: ", pit.name)
				return pit
	
	print("Shell not found in any pit - using closest pit")
	# Fallback: find closest pit
	var closest_pit: Node2D = null
	var shortest_distance = INF
	
	for pit in pits:
		if pit:
			var dist = global_position.distance_to(pit.global_position)
			if dist < shortest_distance:
				shortest_distance = dist
				closest_pit = pit
	
	return closest_pit

func shell_effect():
	pass

func set_score():
	if Type == 1 or Type >= 3 and Type <= 5 or Type == 8 :
		Score = 1
	elif Type == 6 or Type == 7:
		Score = 2
	elif Type == 9 or Type == 12:
		Score = 3
	elif Type == 2 or Type == 11:
		Score = 5
	labelscore.text = str(Score)

func get_score() -> int:
	var score: int = Score
	return score

func set_pit():
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
	if gamemode == "Campaign":
		pass
	elif gamemode == "Pvp":
		var closest_pit: Node2D = null
		var shortest_distance: = INF

		for child in pvp.get_children():
			if child.is_in_group("pits"):
				var dist : = self.global_position.distance_to(child.global_position)
				if dist < shortest_distance:
					shortest_distance = dist
					closest_pit = child
		if closest_pit:
			var name := closest_pit.name
			var pit_number = name.replace("Pit", "")
			Pit = int(pit_number) if pit_number.is_valid_int() else 1
			print("Shell assigned to pit: ", Pit)
		return closest_pit

func set_shell_type(new_type: int) -> void:
	# Fix: Ensure the type is within valid range (0-11 for 12 frames)
	if new_type >= 1 and new_type <= 12:
		Type = new_type
		update_shell_frame()
		set_score()  # Recalculate score for new type
		print("Shell type set to: ", Type)
	else:
		print("Invalid shell type:", new_type)

func update_shell_frame() -> void:
	# Safety check: Make sure shellsprite exists before trying to use it
	if not shellsprite:
		await get_tree().process_frame  # Wait for shell to be ready
		if shell_sprite:
			shellsprite = shell_sprite
		else:
			print("Warning: shellsprite is still null")
			return
	
	# Fix: Ensure frame index is within bounds (0-11 for 12 frames)
	var frame_index = Type - 1 if Type >= 1 else 0
	frame_index = clamp(frame_index, 0, 11)
	
	shellsprite.frame = frame_index
	
	# FIXED: Set color based on shell type
	if Type == 3:  # Echo shell should be red
		shellsprite.modulate = Color.RED
		print("Echo shell set to RED color")
	else:
		shellsprite.modulate = Color.WHITE

func assign_move(amount: int, player: int):
	Move += amount
	Player = player  # Store the player
	print("Shell at pit ", Pit, " assigned " + str(Move) + " moves for player " + str(player))
	move_shell(player)

func move_shell(player: int):
	# CRITICAL FIX: Proper movement logic that follows the standard Mancala path
	if Move <= 0:
		# No more moves, finalize shell position
		linear_velocity = Vector2.ZERO
		Moving = false
		collision_layer = 2
		collision_mask = 2 | 3
		gravity_scale = 1
		freeze = false
		remove_from_group("MoveShells")
		add_to_group("Shells")
		shell_drop()
		print("Shell movement complete at pit ", Pit)
		return
	
	var target: Vector2
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		print("No valid game mode found")
		return
	
	# FIXED: Proper pit progression logic using corrected path
	var next_pit = calculate_next_position(Pit, player)
	
	if gamemode == "Pvp":
		if next_pit <= 14 and next_pit >= 1:
			# Regular pit
			var pit_node = pvp.get_node_or_null("Pit" + str(next_pit))
			if pit_node:
				target = pit_node.global_position
			else:
				print("ERROR: Could not find Pit", next_pit)
				return
		elif next_pit == 15:
			# Player 1's main house
			var house_node = pvp.get_node_or_null("MainHouse1")
			if house_node:
				target = house_node.global_position
			else:
				print("ERROR: Could not find MainHouse1")
				return
		elif next_pit == 16:
			# Player 2's main house  
			var house_node = pvp.get_node_or_null("MainHouse2")
			if house_node:
				target = house_node.global_position
			else:
				print("ERROR: Could not find MainHouse2")
				return
		else:
			print("ERROR: Invalid next_pit value: ", next_pit)
			return
	
	# Start the movement
	if Moving == false and waiting_for_timer == false:
		remove_from_group("Shells")
		add_to_group("MoveShells")
		collision_layer = 0
		collision_mask = 0
		gravity_scale = 0
		freeze = true
		
		Move -= 1
		Pit = next_pit
		Moving = true
		move_target = target
		
		print("Shell moving from pit ", (next_pit - 1), " to pit ", next_pit, " (", Move, " moves remaining)")

func calculate_next_position(current_pit: int, player: int) -> int:
	# Use the exact same logic as GameManager.get_next_position()
	# Convert shell numbering (1-14, 15-16) to GameManager numbering (0-13, 14-15)
	var gm_position = current_pit - 1 if current_pit <= 14 else current_pit - 1
	
	# Get GameManager reference
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() == 0:
		print("ERROR: No GameManager found!")
		return current_pit
	
	var gm = game_manager[0]
	
	# Set the current_turn in GameManager to match our player (convert 1,2 to 0,1)
	var original_turn = gm.current_turn
	gm.current_turn = player - 1
	
	# Use GameManager's get_next_position logic
	var next_gm_position = gm.get_next_position(gm_position)
	
	# Restore original turn
	gm.current_turn = original_turn
	
	# Convert back to shell numbering (0-13, 14-15) to (1-14, 15-16)
	var next_shell_position = next_gm_position + 1 if next_gm_position <= 13 else next_gm_position + 1
	
	print("Shell path: pit ", current_pit, " -> pit ", next_shell_position, " (via GameManager logic)")
	return next_shell_position

func _physics_process(delta):
	if Moving and Move >= 0:
		var distance_to_target = global_position.distance_to(move_target)
		
		if distance_to_target > arrival_threshold:
			# Move toward target by directly setting position (since body is frozen)
			var direction = (move_target - global_position).normalized()
			var movement_distance = move_speed * delta
			global_position = global_position + (direction * movement_distance)
		else:
			# Arrived at target
			global_position = move_target  # Snap to exact position
			Moving = false
			
			# Check if there are more moves
			if Move > 0:
				# Wait for timer before next move
				waiting_for_timer = true
				movetimer.start()
				print("Arrived at pit ", Pit, " - waiting for timer (", Move, " moves remaining)")
			else:
				# All moves complete - NOW we can re-enable physics and collision
				collision_layer = 2
				collision_mask = 2 | 3
				gravity_scale = 1
				freeze = false
				linear_velocity = Vector2.ZERO
				remove_from_group("MoveShells")
				add_to_group("Shells")
				shell_drop()
				print("All movements complete - final position: pit ", Pit)

func _on_move_timer_timeout() -> void:
	movetimer.stop()  # Stop the timer
	if waiting_for_timer and Move > 0:
		waiting_for_timer = false
		print("Timer finished - continuing movement from pit ", Pit)
		move_shell(Player)  # Continue with next move

func _on_score_timer_timeout() -> void:
	labelscore.text = str(Score)  # Fixed: was labelscore.Text (capital T)
	scoretimer.start()
