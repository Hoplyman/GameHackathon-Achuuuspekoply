extends Node

var current_turn: int = 0  # 0 for player 1, 1 for player 2
var pits: Array
var main_houses: Array
var game_active: bool = true
var is_distributing: bool = false  # Prevent clicks during distribution

# UI Elements
var turn_indicator: Label
var player1_label: Label
var player2_label: Label

# Resolution scaling
var base_resolution = Vector2(1920, 1080)
var ui_scale_factor: float = 1.0

func _ready():
	add_to_group("game_manager")  # Add to group so pits can find us
	pits = get_tree().get_nodes_in_group("pits")
	main_houses = get_tree().get_nodes_in_group("main_houses")
	
	# Calculate UI scale factor
	calculate_ui_scale()
	
	call_deferred("create_ui_elements")
	call_deferred("start_game")

func calculate_ui_scale():
	var viewport_size = get_viewport().get_visible_rect().size
	var width_ratio = viewport_size.x / base_resolution.x
	var height_ratio = viewport_size.y / base_resolution.y
	ui_scale_factor = min(width_ratio, height_ratio)
	print("UI Scale factor: ", ui_scale_factor)

func scaled_font_size(base_size: int) -> int:
	return int(base_size * ui_scale_factor)

func scaled_position(base_pos: Vector2) -> Vector2:
	return base_pos * ui_scale_factor

func create_ui_elements():
	# Wait for the scene to be ready before adding UI elements
	await get_tree().process_frame
	
	# Create turn indicator with scaled font and position
	turn_indicator = Label.new()
	turn_indicator.text = "Player 1's Turn"
	turn_indicator.position = scaled_position(Vector2(50, 50))
	turn_indicator.add_theme_font_size_override("font_size", scaled_font_size(28))
	turn_indicator.add_theme_color_override("font_color", Color.WHITE)
	# Add black outline for better visibility
	turn_indicator.add_theme_color_override("font_shadow_color", Color.BLACK)
	turn_indicator.add_theme_constant_override("shadow_offset_x", 2)
	turn_indicator.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(turn_indicator)
	
	# Create Player 1 label (bottom side) - positioned near bottom pits
	player1_label = Label.new()
	player1_label.text = "PLAYER 1 (BLUE)"
	player1_label.position = Vector2(600, 520)  # Positioned above bottom row of pits
	player1_label.add_theme_font_size_override("font_size", scaled_font_size(24))
	player1_label.add_theme_color_override("font_color", Color.CYAN)
	# Add black outline for better visibility
	player1_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player1_label.add_theme_constant_override("shadow_offset_x", 2)
	player1_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(player1_label)
	
	# Create Player 2 label (top side) - positioned near top pits
	player2_label = Label.new()
	player2_label.text = "PLAYER 2 (RED)"
	player2_label.position = Vector2(600, 800)  # Positioned below top row of pits
	player2_label.add_theme_font_size_override("font_size", scaled_font_size(24))
	player2_label.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	# Add black outline for better visibility
	player2_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player2_label.add_theme_constant_override("shadow_offset_x", 2)
	player2_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(player2_label)
	
	# Wait a frame then update display
	await get_tree().process_frame
	update_turn_display()
	
	print("UI Elements created successfully!")

func update_turn_display():
	# Check if UI elements exist before trying to use them
	if not turn_indicator:
		print("Turn indicator not found!")
		return
		
	if current_turn == 0:
		turn_indicator.text = "PLAYER 1's Turn (BLUE)"
		turn_indicator.add_theme_color_override("font_color", Color.CYAN)
		# Highlight player 1's pits
		highlight_player_pits(0)
	else:
		turn_indicator.text = "PLAYER 2's Turn (RED)"
		turn_indicator.add_theme_color_override("font_color", Color.LIGHT_CORAL)
		# Highlight player 2's pits
		highlight_player_pits(1)

func highlight_player_pits(player: int):
	# Reset all pit colors first
	for i in range(pits.size()):
		var pit = pits[i]
		# The pit itself is a Sprite2D, so we modify it directly
		if pit:
			pit.modulate = Color.WHITE
	
	# Highlight current player's pits
	var player_range = get_player_pit_range(player)
	var highlight_color = Color.CYAN if player == 0 else Color.LIGHT_CORAL
	
	for i in range(player_range[0], player_range[1] + 1):
		var pit = get_pit(i)
		if pit:
			# The pit itself is a Sprite2D, so we modify it directly
			pit.modulate = highlight_color
			print("Highlighted pit ", i, " for player ", player + 1, " with color ", highlight_color)

func handle_pit_click(pit_index: int):
	if not game_active or is_distributing:
		return
	
	var pit = get_pit(pit_index)
	if not pit or pit.shells <= 0:
		print("Cannot select empty pit or invalid pit")
		return
	
	# Check if it's the correct player's turn
	var player_pits_range = get_player_pit_range(current_turn)
	if pit_index < player_pits_range[0] or pit_index > player_pits_range[1]:
		print("Not your turn! Player ", current_turn + 1, " can only select pits ", player_pits_range[0] + 1, "-", player_pits_range[1] + 1)
		return
	
	print("Player ", current_turn + 1, " selected pit ", pit_index + 1)
	distribute_shells(pit_index, current_turn + 1)

func get_player_pit_range(player: int) -> Array:
	# Player 0 (Player 1): pits 0-6 (bottom row)
	# Player 1 (Player 2): pits 7-13 (top row)
	if player == 0:
		return [0, 6]
	else:
		return [7, 13]

func distribute_shells(start_pit_index: int, player: int):
	is_distributing = true
	var pit = get_pit(start_pit_index)
	var shells_to_distribute = pit.shells
	
	print("Distributing ", shells_to_distribute, " shells from pit ", start_pit_index + 1)
	
	# Use the physical shell movement system ONLY
	pit.move_shells(player)
	
	is_distributing = false
	
	# Wait for shell movement to complete, then check rules
	# You'll need to modify this to wait for the physical shells to finish moving
	await get_tree().create_timer(shells_to_distribute * 0.5).timeout
	check_end_turn_rules(start_pit_index + shells_to_distribute)  # This needs to be calculated properly

func get_next_position(current_pos: int) -> int:
	# Sungka board layout: 
	# Player 1 pits: 0-6, Player 1 main house: 14
	# Player 2 pits: 7-13, Player 2 main house: 15
	
	if current_pos < 6:  # Moving through player 1's pits (0-5)
		return current_pos + 1
	elif current_pos == 6:  # From last player 1 pit to player 1 main house
		if current_turn == 0:  # Only go to own main house
			return 14  # Player 1 main house
		else:
			return 7  # Skip to player 2's first pit
	elif current_pos < 13:  # Moving through player 2's pits (7-12)
		return current_pos + 1
	elif current_pos == 13:  # From last player 2 pit to player 2 main house
		if current_turn == 1:  # Only go to own main house
			return 15  # Player 2 main house
		else:
			return 0  # Skip to player 1's first pit
	elif current_pos == 14:  # From player 1 main house
		return 7  # To player 2's first pit
	elif current_pos == 15:  # From player 2 main house
		return 0  # To player 1's first pit
	else:
		return 0  # Default fallback

func get_position_node(position: int) -> Node2D:
	if position < 14:  # Regular pits (0-13)
		return get_pit(position)
	elif position == 14:  # Player 1 main house
		return get_main_house(0)
	elif position == 15:  # Player 2 main house
		return get_main_house(1)
	return null

func check_end_turn_rules(last_position: int):
	print("Checking end turn rules. Last position: ", last_position)
	
	# Rule: If last shell lands in your main house, get another turn
	if (current_turn == 0 and last_position == 14) or (current_turn == 1 and last_position == 15):
		print("Player ", current_turn + 1, " gets another turn!")
		return  # Don't switch turns
	
	# Rule: If last shell lands in your empty pit, capture opponent's shells
	if last_position < 14:  # Landed in a regular pit
		var pit = get_pit(last_position)
		if pit and pit.shells == 1:  # Was empty before we placed the shell
			var player_range = get_player_pit_range(current_turn)
			if last_position >= player_range[0] and last_position <= player_range[1]:
				# Landed in own empty pit - capture opposite pit
				capture_opposite_pit(last_position)
	
	# Switch turns if no extra turn was earned
	switch_turn()
	check_game_over()

func capture_opposite_pit(pit_index: int):
	var opposite_index = 13 - pit_index  # Calculate opposite pit
	var opposite_pit = get_pit(opposite_index)
	var own_pit = get_pit(pit_index)
	
	if opposite_pit and own_pit and opposite_pit.shells > 0:
		var captured_shells = opposite_pit.shells + own_pit.shells
		opposite_pit.set_shells(0)
		own_pit.set_shells(0)
		add_shells_to_main_house(current_turn, captured_shells)
		print("Player ", current_turn + 1, " captured ", captured_shells, " shells!")

func clear_all_shells():
	"""Clear ALL shells from the game scene before initialization"""
	print("Clearing all existing shells...")
	
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var target_node = pvp if pvp else campaign
	
	if not target_node:
		print("No game scene found")
		return
	
	var shells_removed = 0
	var children_to_remove = []
	
	# Collect all shells that need to be removed
	for child in target_node.get_children():
		if child.is_in_group("Shells") or child.is_in_group("MoveShells"):
			children_to_remove.append(child)
	
	# Remove all shells
	for shell in children_to_remove:
		shell.queue_free()
		shells_removed += 1
	
	print("Removed ", shells_removed, " existing shells")
	
	# Wait for shells to be actually removed
	if shells_removed > 0:
		await get_tree().process_frame
		await get_tree().process_frame

func start_game():
	print("Starting Shell Masters game!")
	
	# CRITICAL FIX: Clear ALL existing shells first
	await clear_all_shells()
	
	# CRITICAL FIX: Enable visual spawning only for initialization
	for house in main_houses:
		if house.has_method("enable_visual_spawning"):
			house.enable_visual_spawning()
		if house.has_method("disable_visual_spawning"):
			house.disable_visual_spawning()  # Actually keep it disabled for gameplay
	
	# Wait another frame to ensure all shells are cleared
	await get_tree().process_frame
	
	# Initialize pits with shells - this should now create exactly 7 shells per pit
	for pit in pits:
		pit.set_shells(7)  # This will create exactly 7 visual shells
	
	# Initialize main houses (basic setup)
	for house in main_houses:
		if house.has_method("update_label"):
			house.update_label()
	
	print("Game initialized with ", pits.size(), " pits and ", main_houses.size(), " main houses")
	print("Player 1 (BLUE) controls pits 1-7 (bottom row)")
	print("Player 2 (RED) controls pits 8-14 (top row)")
	print("Player 1's turn - click on highlighted pits!")
	
	# Debug: Check shell counts after initialization
	await get_tree().process_frame
	await get_tree().process_frame  # Wait for all spawning to complete
	
	for i in range(pits.size()):
		var pit = pits[i]
		if pit:
			var visual_count = pit.count_shells_in_area()
			var label_count = pit.shells
			print("Pit ", i + 1, ": Label=", label_count, ", Visual=", visual_count)
			
			if visual_count != label_count:
				print("WARNING: Shell count mismatch in pit ", i + 1)
	
	# Only update display if UI elements are ready
	if turn_indicator:
		update_turn_display()
	else:
		# Highlight pits even if UI isn't ready
		highlight_player_pits(0)

# Function to get specific main house (0 for player 1, 1 for player 2)
func get_main_house(player_index: int) -> Node2D:
	if player_index < main_houses.size():
		return main_houses[player_index]
	return null

# Function to add shells to a specific player's main house
func add_shells_to_main_house(player_index: int, amount: int):
	var house = get_main_house(player_index)
	if house:
		if house.has_method("add_shells"):
			house.add_shells(amount)
		print("Added ", amount, " shells to player ", player_index + 1, "'s main house")

# Function to get shells from a specific player's main house
func get_main_house_shells(player_index: int) -> int:
	var house = get_main_house(player_index)
	if house and house.has_method("shells"):
		return house.shells
	return 0

# Function to get a specific pit by index (0-13)
func get_pit(pit_index: int) -> Node2D:
	if pit_index < pits.size():
		return pits[pit_index]
	return null

# Function to switch turns
func switch_turn():
	current_turn = 1 - current_turn  # Toggle between 0 and 1
	print("Turn switched to player ", current_turn + 1)
	update_turn_display()

# Function to check if game is over
func check_game_over() -> bool:
	# Check if all pits on one side are empty
	var player1_empty = true
	var player2_empty = true
	
	# Check player 1's pits (assuming first 7 pits belong to player 1)
	for i in range(7):
		if get_pit(i) and get_pit(i).shells > 0:
			player1_empty = false
			break
	
	# Check player 2's pits (assuming last 7 pits belong to player 2)
	for i in range(7, 14):
		if get_pit(i) and get_pit(i).shells > 0:
			player2_empty = false
			break
	
	if player1_empty or player2_empty:
		end_game()
		return true
	
	return false

# Function to end the game
func end_game():
	game_active = false
	print("Game Over!")
	
	# Collect remaining shells
	var player1_remaining = 0
	var player2_remaining = 0
	
	for i in range(7):
		var pit = get_pit(i)
		if pit:
			player1_remaining += pit.shells
			pit.set_shells(0)
	
	for i in range(7, 14):
		var pit = get_pit(i)
		if pit:
			player2_remaining += pit.shells
			pit.set_shells(0)
	
	# Add remaining shells to main houses
	add_shells_to_main_house(0, player1_remaining)
	add_shells_to_main_house(1, player2_remaining)
	
	# Determine winner
	var player1_score = get_main_house_shells(0)
	var player2_score = get_main_house_shells(1)
	
	if player1_score > player2_score:
		turn_indicator.text = "PLAYER 1 WINS! (" + str(player1_score) + " shells)"
		turn_indicator.add_theme_color_override("font_color", Color.CYAN)
	elif player2_score > player1_score:
		turn_indicator.text = "PLAYER 2 WINS! (" + str(player2_score) + " shells)"
		turn_indicator.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	else:
		turn_indicator.text = "IT'S A TIE! (" + str(player1_score) + " shells each)"
		turn_indicator.add_theme_color_override("font_color", Color.YELLOW)
