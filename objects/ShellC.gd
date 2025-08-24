extends RigidBody2D

var Moving: bool = false
var Player: int = 1  # Always player 1 in campaign
var Pit: int = 0
var Move: int = 0
var shell_type: int = 0
var shellsprite: Sprite2D
var waiting_for_timer: bool = false

@onready var timer := $Timer

# Movement variables
var move_target: Vector2
var move_speed: float = 200.0
var arrival_threshold: float = 10.0

func _ready() -> void:
	set_pit()
	shellsprite = get_node("ShellSprite")
	shell_type = randi_range(0, 11)
	add_to_group("Shells")
	
	# Start with physics disabled to prevent falling
	gravity_scale = 0
	freeze = true
	
	# Check if timer exists before connecting
	timer = get_node_or_null("Timer")
	if timer:
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		print("Timer connected for shell")
	else:
		# Create timer if it doesn't exist
		timer = Timer.new()
		timer.wait_time = 0.3
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		print("Created and connected timer for shell")
	
	update_shell_frame()
	
	# Enable physics after a short delay to let shell settle in position
	await get_tree().create_timer(0.2).timeout
	stabilize_shell()
	
func stabilize_shell():
	"""Make the shell stable in its current position"""
	# Keep shells frozen unless they're actively moving
	if not Moving:
		freeze = true
		gravity_scale = 0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0

func set_pit():
	var gamemode: String = "Campaign"
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if not campaign:
		gamemode = ""
		return
	
	if gamemode == "Campaign":
		var closest_pit: Node2D = null
		var shortest_distance: = INF
		var closest_pit_index: int = -1

		# Get all pits and check distance
		for child in campaign.get_children():
			if child.name == "BoardC":
				for board_child in child.get_children():
					if board_child.is_in_group("pitsC"):
						var dist = self.global_position.distance_to(board_child.global_position)
						if dist < shortest_distance:
							shortest_distance = dist
							closest_pit = board_child
		
		# Also check direct children of campaign
		for child in campaign.get_children():
			if child.is_in_group("pitsC"):
				var dist = self.global_position.distance_to(child.global_position)
				if dist < shortest_distance:
					shortest_distance = dist
					closest_pit = child

		if closest_pit:
			var name_str = closest_pit.name
			print("Shell closest to pit: ", name_str)
			
			# Map pit names to indices correctly
			match name_str:
				"PitC": 
					Pit = 0
					print("Shell assigned to PitC (index 0)")
				"PitC2": 
					Pit = 1
					print("Shell assigned to PitC2 (index 1)")
				"PitC3": 
					Pit = 2
					print("Shell assigned to PitC3 (index 2)")
				"PitC4": 
					Pit = 3
					print("Shell assigned to PitC4 (index 3)")
				"PitC5": 
					Pit = 4
					print("Shell assigned to PitC5 (index 4)")
				"PitC6": 
					Pit = 5
					print("Shell assigned to PitC6 (index 5)")
				"PitC7": 
					Pit = 6
					print("Shell assigned to PitC7 (index 6)")
				_:
					print("Unknown pit name: ", name_str)
					Pit = 0  # Default fallback
		else:
			print("No closest pit found, defaulting to index 0")
			Pit = 0
			
		return closest_pit

func set_shell_type(new_type: int) -> void:
	# Fix: Use 0-11 range for valid frame indices (12 total frames)
	if new_type >= 0 and new_type <= 11:
		shell_type = new_type
		update_shell_frame()
	else:
		print("Invalid shell type:", new_type, " - Valid range is 0-11")
		shell_type = 0  # Default to frame 0 if invalid
		update_shell_frame()

func update_shell_frame() -> void:
	shellsprite.frame = shell_type

func assign_move(amount: int, player: int):
	Move += amount
	Player = player
	print("Assigned " + str(Move) + " moves for player " + str(player))
	move_shell(player)

func move_shell(player: int):
	var target: Vector2
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if not campaign:
		print("Error: Campaign node not found!")
		return
	
	var target_node: Node2D = null
	var next_pit_index: int
	
	# Store the next pit index for later update
	var destination_pit_index: int
	
	# FIXED: Proper next pit calculation
	if Pit == 6:  # If at PitC7 (index 6), next is MainHouse
		next_pit_index = 7
		destination_pit_index = 7
	elif Pit == 7:  # If at MainHouse (index 7), next is PitC (index 0)
		next_pit_index = 0
		destination_pit_index = 0
	else:  # Normal increment for pits 0-5
		next_pit_index = Pit + 1
		destination_pit_index = next_pit_index
	
	print("=== MOVEMENT DEBUG ===")
	print("Shell current position: ", global_position)
	print("Current Pit index: ", Pit, " -> Next index: ", next_pit_index)
	print("Shell Move count: ", Move)
	
	# Campaign mode movement - FIXED sequential movement
	if next_pit_index >= 0 and next_pit_index <= 6:  # Regular pits (0-6)
		var next_pit_name: String
		
		# Map pit indices to correct node names
		match next_pit_index:
			0: next_pit_name = "PitC"    # Index 0 = PitC
			1: next_pit_name = "PitC2"   # Index 1 = PitC2
			2: next_pit_name = "PitC3"   # Index 2 = PitC3
			3: next_pit_name = "PitC4"   # Index 3 = PitC4
			4: next_pit_name = "PitC5"   # Index 4 = PitC5
			5: next_pit_name = "PitC6"   # Index 5 = PitC6
			6: next_pit_name = "PitC7"   # Index 6 = PitC7
			_: 
				print("ERROR: Invalid pit index ", next_pit_index)
				return
		
		print("Looking for pit: ", next_pit_name)
		
		# Try to find the node
		target_node = campaign.get_node_or_null("BoardC/" + next_pit_name)
		if not target_node:
			target_node = campaign.get_node_or_null(next_pit_name)
		
		if target_node:
			target = target_node.global_position
			print("SUCCESS: Found ", next_pit_name, " at position ", target)
		else:
			print("ERROR: Node ", next_pit_name, " not found!")
			# Debug: List all available nodes
			print("Available nodes in BoardC:")
			var board = campaign.get_node_or_null("BoardC")
			if board:
				for child in board.get_children():
					print("  - ", child.name)
			return
			
	elif next_pit_index == 7:  # Go to MainHouse
		print("Moving to MainHouse (index 7)")
		target_node = campaign.get_node_or_null("BoardC/MainHouse1")
		if not target_node:
			target_node = campaign.get_node_or_null("MainHouse1")
		if target_node:
			target = target_node.global_position
			print("SUCCESS: Found MainHouse1 at position ", target)
		else:
			print("ERROR: MainHouse1 not found!")
			return
	else:
		print("ERROR: Invalid next_pit_index: ", next_pit_index)
		return
	
	# Set the movement target and start movement
	# NOTE: Pit index will be updated when shell reaches destination
	move_target = target
	Moving = true
	
	# Store destination for pit update when we arrive
	set_meta("destination_pit", destination_pit_index)
	
	# Disable physics during movement
	collision_layer = 0
	collision_mask = 0
	gravity_scale = 0
	freeze = true
	
	# Decrement moves
	Move -= 1
	print("Shell moving from ", global_position, " to ", target, ". Moves remaining: ", Move)

func _physics_process(delta):
	if Moving and Move >= 0:
		var distance_to_target = global_position.distance_to(move_target)
		
		if distance_to_target > arrival_threshold:
			var direction = (move_target - global_position).normalized()
			var movement_distance = move_speed * delta
			global_position = global_position + (direction * movement_distance)
		else:
			# Arrived at target
			global_position = move_target
			Moving = false
			
			# FIXED: Update Pit index AFTER reaching destination
			if has_meta("destination_pit"):
				Pit = get_meta("destination_pit")
				remove_meta("destination_pit")
				print("Shell arrived at destination - Pit index updated to: ", Pit)
			
			# Re-enable physics temporarily for pit detection
			collision_layer = 2
			collision_mask = 2 | 4  # Collide with shells and pits
			gravity_scale = 1
			freeze = false
			linear_velocity = Vector2.ZERO
			
			# No longer automatically placing shells at pits
			# This was causing the bug where shells kept spawning
			
			# Check if there are more moves
			if Move > 0:
				waiting_for_timer = true
				timer.start()
				print("Waiting for timer before next move...")
			else:
				# All moves complete
				remove_from_group("MoveShells")
				add_to_group("Shells")
				print("All movements complete")
				
# REMOVED: This function was causing shells to spawn incorrectly
# The pit shell management should be handled by the pit collision areas
# not by the moving shells themselves

func _on_timer_timeout() -> void:
	timer.stop()
	if waiting_for_timer and Move > 0:
		waiting_for_timer = false
		print("Timer finished - continuing movement")
		move_shell(Player)
