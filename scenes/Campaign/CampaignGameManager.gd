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
	pits = get_tree().get_nodes_in_group("pitsC")  # Changed from "pits" to "pitsC"
	main_houses = get_tree().get_nodes_in_group("main_houses")
	
	# Get campaign manager
	campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
	if not campaign_manager:
		print("Warning: No campaign manager found!")
	
	call_deferred("create_ui_elements")
	call_deferred("start_campaign_game")
	
func setup_initial_shells():
	print("Setting up initial shells for all pits")
	
	# DISABLE pit shell detection temporarily
	for pit in pits:
		if pit:
			var shell_area = pit.get_node_or_null("ShellArea")
			if shell_area:
				shell_area.monitoring = false
	
	var shell_scene = preload("res://objects/ShellC.tscn")
	var campaign = get_tree().root.get_node("Campaign")
	
	for pit in pits:
		if pit:
			print("Creating shells for pit ", pit.name)
			for i in range(7):  # 7 shells per pit
				var shell = shell_scene.instantiate()
				
				# Position shells in a tight circle around pit center
				var angle = (i * 2.0 * PI) / 7  # Fixed PI calculation
				var radius = 8  # Small radius to keep shells close to pit
				var offset = Vector2(cos(angle) * radius, sin(angle) * radius)
				shell.position = pit.global_position + offset
				
				# Make shells stable initially - disable physics
				shell.gravity_scale = 0
				shell.freeze = true
				shell.collision_layer = 2  # Keep collision for detection but disable physics
				shell.collision_mask = 0   # Don't collide with anything initially
				
				campaign.add_child(shell)
				await get_tree().process_frame
				await get_tree().create_timer(0.5).timeout
				shell.gravity_scale = 1
				shell.freeze = false
				shell.collision_mask = 6
	
	# RE-ENABLE pit shell detection and manually set counts
	for pit in pits:
		if pit:
			pit.set_shells(7)  # Set correct count
			var shell_area = pit.get_node_or_null("ShellArea")
			if shell_area:
				shell_area.monitoring = true

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
	setup_initial_shells()
	
	# Initialize main houses
	for house in main_houses:
		if house.has_method("take_all_shells"):
			house.take_all_shells()

func setup_pits_with_shells():
	# Distribute player's shells across the pits (reset to starting positions)
	var shells_per_pit = 7  # Standard starting amount
	
	for i in range(min(pits.size(), 7)):  # Only first 7 pits for campaign
		var pit = pits[i]
		if pit:
			# Reset to base shell count
			pit.set_shells(shells_per_pit)
			
			# Restore original shell type data (keep the special shell types player collected)
			if i < player_shells.size() and player_shells[i] != null:
				if pit.has_method("set_shell_data"):
					pit.set_shell_data(player_shells[i])
				else:
					pit.set_meta("shell_data", player_shells[i])
			else:
				# Default shell type if no special shell assigned
				var default_shell = {"type": "tahong", "value": 1, "effect": "none"}
				pit.set_meta("shell_data", default_shell)
	
	print("Pits setup complete - All pits reset to ", shells_per_pit, " shells each")

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
	# CHANGED: Now uses the same system as VS mode
	is_distributing = true
	var pit = get_pit(start_pit_index)
	
	# Get shell data for special effects
	var shell_data = pit.get_meta("shell_data", {})
	
	print("Player selected pit ", start_pit_index + 1)
	
	# Call the pit's move_shells function just like in VS mode
	pit.move_shells(1)  # Player is always player 1 in campaign
	
	is_distributing = false
	
	# Check for campaign rules after movement completes
	# Note: This happens immediately, but the actual shell movement is handled by Campaign.gd
	await get_tree().create_timer(0.1).timeout  # Small delay to let movement start
	check_campaign_rules_after_movement(shell_data)

func check_campaign_rules_after_movement(shell_data: Dictionary):
	# Apply any special shell effects
	if campaign_manager and shell_data.has("effect"):
		var bonus_points = campaign_manager.apply_shell_effect(shell_data, get_main_house(0))
		if bonus_points > 0:
			campaign_manager.add_score(bonus_points)

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

func reset_for_next_round():
	"""Reset the board state for next round while keeping shell types"""
	print("Resetting for next round...")
	
	# Reset game state
	game_active = true
	is_distributing = false
	moves_made = 0
	
	# Reset UI
	if turn_indicator:
		turn_indicator.text = "Your Turn - Choose a pit!"
		turn_indicator.add_theme_color_override("font_color", Color.CYAN)
	
	if moves_label:
		moves_label.text = "Moves: 0/" + str(max_moves)
		moves_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Clear main houses but keep shell types for next round
	for house in main_houses:
		if house.has_method("take_all_shells"):
			house.take_all_shells()
	
	# Redistribute shells to pits (keeping same shell types/data)
	setup_pits_with_shells()
	
	print("Board reset complete - Ready for next round!")

func start_new_round(new_max_moves: int = 50):
	"""Called by campaign manager to start a fresh round"""
	max_moves = new_max_moves
	reset_for_next_round()
