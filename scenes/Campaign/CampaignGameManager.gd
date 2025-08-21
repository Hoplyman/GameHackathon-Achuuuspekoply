extends Node

var current_turn: int = 0  # 0 for player, 1 for AI (if needed)
var pits: Array
var main_houses: Array
var game_active: bool = true
var is_distributing: bool = false

# Campaign integration
var campaign_manager: Node
var player_shells: Array = []
var moves_made: int = 0
var max_moves: int = 50  # Limit moves per stage

# UI Elements
var turn_indicator: Label
var moves_label: Label

func _ready():
	add_to_group("game_manager")
	pits = get_tree().get_nodes_in_group("pits")
	main_houses = get_tree().get_nodes_in_group("main_houses")
	
	# Get campaign manager
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	if not campaign_manager:
		print("Warning: No campaign manager found!")
	
	call_deferred("create_ui_elements")
	call_deferred("start_campaign_game")

func create_ui_elements():
	await get_tree().process_frame
	
	# Turn indicator
	turn_indicator = Label.new()
	turn_indicator.text = "Your Turn - Choose a pit!"
	turn_indicator.position = Vector2(300, 50)
	turn_indicator.add_theme_font_size_override("font_size", 24)
	turn_indicator.add_theme_color_override("font_color", Color.CYAN)
	turn_indicator.add_theme_color_override("font_shadow_color", Color.BLACK)
	turn_indicator.add_theme_constant_override("shadow_offset_x", 2)
	turn_indicator.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(turn_indicator)
	
	# Moves counter
	moves_label = Label.new()
	moves_label.text = "Moves: 0/" + str(max_moves)
	moves_label.position = Vector2(300, 80)
	moves_label.add_theme_font_size_override("font_size", 20)
	moves_label.add_theme_color_override("font_color", Color.WHITE)
	moves_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	moves_label.add_theme_constant_override("shadow_offset_x", 2)
	moves_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(moves_label)

func start_campaign_game():
	print("Starting campaign game!")
	
	# Get shells from campaign manager
	if campaign_manager:
		player_shells = campaign_manager.get_player_shells()
		print("Player has ", player_shells.size(), " shells")
	
	# Initialize pits with player's shells
	setup_pits_with_shells()
	
	# Initialize main houses
	for house in main_houses:
		if house.has_method("set_shells"):
			house.set_shells(0)

func setup_pits_with_shells():
	# Distribute player's shells across the pits
	for i in range(min(pits.size(), player_shells.size())):
		var pit = pits[i]
		if pit:
			# Set basic shell count (we'll handle special effects during gameplay)
			pit.set_shells(7)  # Base amount
			
			# Store the shell data for later use
			if pit.has_method("set_shell_data"):
				pit.set_shell_data(player_shells[i])
			else:
				# Add shell data as metadata if method doesn't exist
				pit.set_meta("shell_data", player_shells[i])

func handle_pit_click(pit_index: int):
	if not game_active or is_distributing:
		return
	
	# In campaign mode, player controls bottom row (pits 0-6)
	if pit_index < 0 or pit_index > 6:
		print("In campaign mode, you can only select bottom row pits (1-7)")
		return
	
	var pit = get_pit(pit_index)
	if not pit or pit.shells <= 0:
		print("Cannot select empty pit")
		return
	
	print("Selected pit ", pit_index + 1)
	distribute_shells(pit_index)
	
	moves_made += 1
	update_moves_display()
	
	# Check if out of moves
	if moves_made >= max_moves:
		end_game_out_of_moves()

func distribute_shells(start_pit_index: int):
	is_distributing = true
	var pit = get_pit(start_pit_index)
	var shells_to_distribute = pit.shells
	
	# Get shell data for special effects
	var shell_data = pit.get_meta("shell_data", {})
	
	print("Distributing ", shells_to_distribute, " shells from pit ", start_pit_index + 1)
	
	# Empty the starting pit
	pit.set_shells(0)
	
	var current_index = start_pit_index
	var shells_remaining = shells_to_distribute
	var bonus_points = 0
	
	# Distribute shells one by one with delay
	while shells_remaining > 0:
		await get_tree().create_timer(0.3).timeout  # Faster for campaign
		
		current_index = get_next_position(current_index)
		var target = get_position_node(current_index)
		
		if target:
			target.add_shells(1)
			
			# Apply shell effects when landing in big house
			if current_index == 14:  # Player's big house
				if campaign_manager:
					bonus_points += campaign_manager.apply_shell_effect(shell_data, target)
					# Base point for reaching big house
					campaign_manager.add_score(1 + bonus_points)
			
			print("Placed 1 shell at position ", current_index)
			shells_remaining -= 1
	
	is_distributing = false
	
	# Check for capture rules (simplified for campaign)
	check_campaign_rules(current_index)

func get_next_position(current_pos: int) -> int:
	# Campaign mode: only player side, simpler movement
	if current_pos < 6:  # Moving through player's pits (0-5)
		return current_pos + 1
	elif current_pos == 6:  # From last player pit to big house
		return 14  # Player's big house
	elif current_pos == 14:  # From big house, wrap around
		return 0  # Back to first pit
	else:
		return 0  # Default fallback

func get_position_node(position: int) -> Node2D:
	if position < 14:  # Regular pits (0-13, but only 0-6 used in campaign)
		return get_pit(position)
	elif position == 14:  # Player's big house
		return get_main_house(0)
	return null

func check_campaign_rules(last_position: int):
	# Rule: If last shell lands in big house, get bonus turn
	if last_position == 14:
		print("Landed in big house! Bonus turn!")
		return  # Don't end turn
	
	# Rule: Capture opposite pit if landed in empty pit
	if last_position < 7:  # Player's side
		var pit = get_pit(last_position)
		if pit and pit.shells == 1:  # Was empty before placement
			var opposite_index = 13 - last_position
			if opposite_index < pits.size():
				var opposite_pit = get_pit(opposite_index)
				if opposite_pit and opposite_pit.shells > 0:
					capture_opposite_pit(last_position)

func capture_opposite_pit(pit_index: int):
	var opposite_index = 13 - pit_index
	var opposite_pit = get_pit(opposite_index)
	var own_pit = get_pit(pit_index)
	
	if opposite_pit and own_pit and opposite_pit.shells > 0:
		var captured_shells = opposite_pit.shells + own_pit.shells
		opposite_pit.set_shells(0)
		own_pit.set_shells(0)
		
		# Add to big house and score
		var big_house = get_main_house(0)
		if big_house:
			big_house.add_shells(captured_shells)
		
		if campaign_manager:
			campaign_manager.add_score(captured_shells)
		
		print("Captured ", captured_shells, " shells!")

func get_pit(pit_index: int) -> Node2D:
	if pit_index < pits.size():
		return pits[pit_index]
	return null

func get_main_house(player_index: int) -> Node2D:
	if player_index < main_houses.size():
		return main_houses[player_index]
	return null

func update_moves_display():
	if moves_label:
		moves_label.text = "Moves: " + str(moves_made) + "/" + str(max_moves)
		
		# Change color as moves run out
		if moves_made >= max_moves * 0.8:
			moves_label.add_theme_color_override("font_color", Color.RED)
		elif moves_made >= max_moves * 0.6:
			moves_label.add_theme_color_override("font_color", Color.YELLOW)

func end_game_out_of_moves():
	game_active = false
	print("Out of moves!")
	
	if turn_indicator:
		turn_indicator.text = "Out of moves! Check if you reached the target score."
		turn_indicator.add_theme_color_override("font_color", Color.RED)
	
	# Let campaign manager handle win/lose logic
	if campaign_manager:
		# Campaign manager will check if target score was reached
		pass
