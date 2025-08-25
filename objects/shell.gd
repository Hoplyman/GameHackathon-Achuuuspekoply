extends RigidBody2D

var Moving: bool = false # is Moving 
var Player: int = 0 # whose player turn for turn purposes
var Pit: int = 0 # what Pit is the Shell is in
var Move: int = 0 # number of Moves 
var Score: int = 0 # total score to tally when in Pits
var shell_type: int = 0 # the type of shell for unique effects
var shellsprite: Sprite2D # the sprite of Shell
var waiting_for_timer: bool = false  # New variable to track timer waiting

@onready var timer := $Timer

# Movement variables
var move_target: Vector2
var move_speed: float = 200.0
var arrival_threshold: float = 10.0

func _ready() -> void:
	set_pit()
	Score = 1
	shellsprite = get_node("ShellSprite")
	shell_type = randi_range(1, 12)  # This will be 1-12, but we need 0-11 for frames
	add_to_group("Shells")  # Fixed: was "Shell", should be "Shells"
	
	# Fix: Check if signal is already connected before connecting
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	
	# Don't start timer automatically - only when needed
	update_shell_frame()

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
			var match := name.match("Pit(\\d+)")
			var pit_number = name.replace("Pit", "")
			Pit = int(pit_number)
		return closest_pit

func set_shell_type(new_type: int) -> void:
	# Fix: Ensure the type is within valid range (0-11 for 12 frames)
	if new_type >= 1 and new_type <= 12:
		shell_type = new_type - 1  # Convert 1-12 range to 0-11 range
		update_shell_frame()
	else:
		print("Invalid shell type:", new_type)

func update_shell_frame() -> void:
	# Fix: Ensure frame index is within bounds (0-11 for 12 frames)
	var frame_index = shell_type
	if shell_type >= 1 and shell_type <= 12:
		frame_index = shell_type - 1  # Convert 1-12 to 0-11
	elif shell_type > 12:
		frame_index = 11  # Use last frame if out of bounds
	elif shell_type < 1:
		frame_index = 0   # Use first frame if out of bounds
	
	shellsprite.frame = frame_index

func assign_move(amount: int, player: int):
	Move += amount
	Player = player  # Store the player
	print("Assigned " + str(Move) + " moves for player " + str(player))
	move_shell(player)

func move_shell(player: int):
	var target: Vector2
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
	if gamemode == "Campaign":
		var boardc = campaign.get_node_or_null("BoardC")
		if Pit <= 6:
			target = boardc.get_node("PitC" + str(Pit+1)).global_position
		elif Pit == 7:
			target = boardc.get_node("MainHouse1").global_position
		elif Pit >= 8:
			target = boardc.get_node("PitC1").global_position
			Pit = 0
	if gamemode == "Pvp":
		if Pit == 7:
			if player == 1:
				target = pvp.get_node("MainHouse1").global_position
				Pit = 14
			else:
				target = pvp.get_node("Pit8").global_position
		elif Pit == 14:
			if player == 2:
				target = pvp.get_node("MainHouse2").global_position
				Pit = 15
			else:
				target = pvp.get_node("Pit1").global_position
				Pit = 0
		elif Pit <= 6 or (Pit >= 8 and Pit <= 13):
			target = pvp.get_node("Pit" + str(Pit+1)).global_position
		elif Pit == 15:
			target = pvp.get_node("Pit" + str(8)).global_position
			Pit = 7
		elif Pit == 16:
			target = pvp.get_node("Pit" + str(1)).global_position
			Pit = 0
		else:
			Pit = 1
			target = pvp.get_node("Pit1").global_position
		if Move >= 1:
			if Moving == false and waiting_for_timer == false:
				remove_from_group("Shells")
				add_to_group("MoveShells")
				# CRITICAL FIX: Disable collision detection during movement to prevent duplication
				collision_layer = 0
				collision_mask = 0
				gravity_scale = 0
				freeze = true  # Freeze the body to prevent falling
				Move -= 1
				Pit += 1
				Moving = true
				# Store the target for the physics process
				move_target = target
				print("Starting movement to:", target)
		elif Move == 0:
			if Moving == true:
				# Stop the shell and re-enable physics
				linear_velocity = Vector2.ZERO
				Moving = false
				# CRITICAL FIX: Only enable collision when movement is completely finished
				collision_layer = 2
				collision_mask = 2 | 3
				gravity_scale = 1
				freeze = false  # Unfreeze the body
				remove_from_group("MoveShells")
				add_to_group("Shells")
				print("All movements complete")

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
			
			# IMPORTANT: Keep collision disabled during intermediate stops
			# This prevents the shell from being detected by pit areas during movement
			
			# Check if there are more moves
			if Move > 0:
				# Wait for timer before next move
				waiting_for_timer = true
				timer.start()
				print("Waiting for timer before next move...")
			else:
				# All moves complete - NOW we can re-enable physics and collision
				collision_layer = 2
				collision_mask = 2 | 3
				gravity_scale = 1
				freeze = false
				linear_velocity = Vector2.ZERO
				remove_from_group("MoveShells")
				add_to_group("Shells")
				print("All movements complete - collision re-enabled")

func _on_timer_timeout() -> void:
	timer.stop()  # Stop the timer
	if waiting_for_timer and Move > 0:
		waiting_for_timer = false
		print("Timer finished - continuing movement")
		move_shell(Player)  # Continue with next move
