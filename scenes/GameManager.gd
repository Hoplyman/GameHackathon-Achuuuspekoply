extends Node

var current_turn: int = 0
var pits: Array
var main_houses: Array
var game_active: bool = true
var is_distributing: bool = false
var awaiting_special_shell_selection: bool = false

# UI Elements
var turn_indicator: Label
var player1_label: Label
var player2_label: Label
var special_shell_selector: Control

# Resolution scaling
var base_resolution = Vector2(1920, 1080)
var ui_scale_factor: float = 1.0

func _ready():
	add_to_group("game_manager")
	pits = get_tree().get_nodes_in_group("pits")
	main_houses = get_tree().get_nodes_in_group("main_houses")
	
	calculate_ui_scale()
	call_deferred("create_ui_elements")
	call_deferred("start_game")
	call_deferred("create_special_shell_selector")

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
	await get_tree().process_frame
	
	turn_indicator = Label.new()
	turn_indicator.text = "Player 1's Turn"
	turn_indicator.position = scaled_position(Vector2(50, 50))
	turn_indicator.add_theme_font_size_override("font_size", scaled_font_size(28))
	turn_indicator.add_theme_color_override("font_color", Color.WHITE)
	turn_indicator.add_theme_color_override("font_shadow_color", Color.BLACK)
	turn_indicator.add_theme_constant_override("shadow_offset_x", 2)
	turn_indicator.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(turn_indicator)
	
	player1_label = Label.new()
	player1_label.text = "PLAYER 1 (BLUE)"
	player1_label.position = Vector2(600, 520)
	player1_label.add_theme_font_size_override("font_size", scaled_font_size(24))
	player1_label.add_theme_color_override("font_color", Color.CYAN)
	player1_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player1_label.add_theme_constant_override("shadow_offset_x", 2)
	player1_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(player1_label)
	
	player2_label = Label.new()
	player2_label.text = "PLAYER 2 (RED)"
	player2_label.position = Vector2(600, 800)
	player2_label.add_theme_font_size_override("font_size", scaled_font_size(24))
	player2_label.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	player2_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player2_label.add_theme_constant_override("shadow_offset_x", 2)
	player2_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(player2_label)
	
	await get_tree().process_frame
	update_turn_display()
	print("UI Elements created successfully!")

func create_special_shell_selector():
	# Get reference to the selector that's already in the scene
	special_shell_selector = get_parent().get_node("SpecialShellSelector")
	if special_shell_selector:
		special_shell_selector.special_shell_selected.connect(_on_special_shell_selected)
		print("Special shell selector connected!")
	else:
		print("ERROR: SpecialShellSelector not found in scene!")

func update_turn_display():
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	for child in pvp.get_children():
		if child.is_in_group("pits"):
			child.pit_startround()
			var tween = create_tween()
			tween.tween_interval(0.05)
			await tween.finished
	if not turn_indicator:
		print("Turn indicator not found!")
		return
		
	if awaiting_special_shell_selection:
		turn_indicator.text = "Player " + str(current_turn + 1) + " - Choose Special Shell"
		return
		
	if current_turn == 0:
		turn_indicator.text = "PLAYER 1's Turn (BLUE)"
		turn_indicator.add_theme_color_override("font_color", Color.CYAN)
		highlight_player_pits(0)
	else:
		turn_indicator.text = "PLAYER 2's Turn (RED)"
		turn_indicator.add_theme_color_override("font_color", Color.LIGHT_CORAL)
		highlight_player_pits(1)

func highlight_player_pits(player: int):
	for i in range(pits.size()):
		var pit = pits[i]
		if pit:
			pit.modulate = Color.WHITE
	
	var player_range = get_player_pit_range(player)
	var highlight_color = Color.CYAN if player == 0 else Color.LIGHT_CORAL
	
	for i in range(player_range[0], player_range[1] + 1):
		var pit = get_pit(i)
		if pit:
			pit.modulate = highlight_color

func handle_pit_click(pit_index: int):
	# First check if we're in special shell selection mode
	if awaiting_special_shell_selection:
		if special_shell_selector.handle_pit_click(pit_index):
			return  # Pit click was handled by special shell selector
	
	if not game_active or is_distributing or awaiting_special_shell_selection:
		return
	
	var pit = get_pit(pit_index)
	if not pit or pit.shells <= 0:
		print("Cannot select empty pit or invalid pit")

		return
	
	var player_pits_range = get_player_pit_range(current_turn)
	if pit_index < player_pits_range[0] or pit_index > player_pits_range[1]:
		print("Not your turn! Player ", current_turn + 1, " can only select pits ", player_pits_range[0] + 1, "-", player_pits_range[1] + 1)
		return
	
	print("Player ", current_turn + 1, " selected pit ", pit_index + 1)
	distribute_shells(pit_index, current_turn + 1)

func get_player_pit_range(player: int) -> Array:
	if player == 0:
		return [0, 6]
	else:
		return [7, 13]

func distribute_shells(start_pit_index: int, player: int):
	is_distributing = true
	var pit = get_pit(start_pit_index)
	var shells_to_distribute = pit.shells
	
	print("Distributing ", shells_to_distribute, " shells from pit ", start_pit_index + 1)
	
	# Use the physical shell movement system
	pit.move_shells(player)
	
	# FIXED: Much shorter wait time and better calculation
	var estimated_duration = shells_to_distribute * 0.15  # Reduced from 0.5 to 0.15
	await get_tree().create_timer(estimated_duration).timeout
	
	# Calculate the final position properly
	var final_position = calculate_final_position(start_pit_index, shells_to_distribute)
	
	is_distributing = false
	check_end_turn_rules(final_position)

# Function to properly calculate where the last shell will land
func calculate_final_position(start_pit: int, shell_count: int) -> int:
	var current_pos = start_pit
	
	for i in range(shell_count):
		current_pos = get_next_position(current_pos)
	
	return current_pos

func get_next_position(current_pos: int) -> int:
	if current_pos < 6:
		return current_pos + 1
	elif current_pos == 6:
		if current_turn == 0:
			return 14  # Player 1 main house
		else:
			return 7  # Skip to player 2's first pit
	elif current_pos < 13:
		return current_pos + 1
	elif current_pos == 13:
		if current_turn == 1:
			return 15  # Player 2 main house
		else:
			return 0  # Skip to player 1's first pit
	elif current_pos == 14:  # From player 1 main house
		return 7  # To player 2's first pit
	elif current_pos == 15:  # From player 2 main house
		return 0  # To player 1's first pit
	else:
		return 0

func get_position_node(position: int) -> Node2D:
	if position < 14:
		return get_pit(position)
	elif position == 14:
		return get_main_house(0)
	elif position == 15:
		return get_main_house(1)
	return null

func check_end_turn_rules(last_position: int):
	print("Checking end turn rules. Last position: ", last_position)
	
	# Rule: Extra turn for landing in own main house
	if (current_turn == 0 and last_position == 14) or (current_turn == 1 and last_position == 15):
		print("Player ", current_turn + 1, " gets another turn!")
		# NO special shell selection after extra turn - just continue turn
		update_turn_display()
		return
	
	# Rule: Capture for landing in own empty pit
	if last_position < 14:
		var pit = get_pit(last_position)
		if pit and pit.shells == 1:  # Was empty before the shell
			var player_range = get_player_pit_range(current_turn)
			if last_position >= player_range[0] and last_position <= player_range[1]:
				capture_opposite_pit(last_position)
	
	# Show special shell selection before switching turns
	show_special_shell_selection()

func show_special_shell_selection():
	awaiting_special_shell_selection = true
	update_turn_display()
	special_shell_selector.show_selection(current_turn)

func _on_special_shell_selected(shell_type: int, pit_index: int):
	awaiting_special_shell_selection = false
	
	if shell_type > 0:
		# Player selected a special shell (already spawned by SpecialShellSelector)
		print("Player ", current_turn + 1, " selected special shell type ", shell_type)
	else:
		print("Player ", current_turn + 1, " skipped special shell selection")
	
	# Now switch turns and continue game
	switch_turn()
	check_game_over()

func capture_opposite_pit(pit_index: int):
	var opposite_index = 13 - pit_index
	var opposite_pit = get_pit(opposite_index)
	var own_pit = get_pit(pit_index)
	
	if opposite_pit and own_pit and opposite_pit.shells > 0:
		var captured_shells = opposite_pit.shells + own_pit.shells
		opposite_pit.set_shells(0)
		own_pit.set_shells(0)
		add_shells_to_main_house(current_turn, captured_shells)
		print("Player ", current_turn + 1, " captured ", captured_shells, " shells!")

func clear_all_shells():
	print("Clearing all existing shells...")
	
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var target_node = pvp if pvp else campaign
	
	if not target_node:
		print("No game scene found")
		return
	
	var shells_removed = 0
	var children_to_remove = []
	
	for child in target_node.get_children():
		if child.is_in_group("Shells") or child.is_in_group("MoveShells"):
			children_to_remove.append(child)
	
	for shell in children_to_remove:
		shell.queue_free()
		shells_removed += 1
	
	print("Removed ", shells_removed, " existing shells")
	
	if shells_removed > 0:
		await get_tree().process_frame
		await get_tree().process_frame

func start_game():
	print("Starting Shell Masters game!")
	
	await clear_all_shells()
	
	# Disable visual spawning for main houses during gameplay
	for house in main_houses:
		if house.has_method("disable_visual_spawning"):
			house.disable_visual_spawning()
	
	await get_tree().process_frame
	
	# Initialize pits with exactly 7 NORMAL shells each (type 1)
	for pit in pits:
		pit.set_shells(7)
		# Force all starting shells to be normal shells
		force_normal_shells_in_pit(pit)
	
	# Wait longer to ensure all shell spawning is completely finished
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout  # Extra delay to ensure shells are settled
	
	# Now enable timer counting for all pits
	for pit in pits:
		if pit.has_method("enable_timer_counting"):
			pit.enable_timer_counting()
	
	for house in main_houses:
		if house.has_method("update_label"):
			house.update_label()
	
	print("Game initialized with ", pits.size(), " pits and ", main_houses.size(), " main houses")
	print("All starting shells are normal shells (type 1)")
	print("Player 1 (BLUE) controls pits 1-7 (bottom row)")
	print("Player 2 (RED) controls pits 8-14 (top row)")
	print("Hover over pits/main houses to see shell contents!")
	print("Right-click for detailed shell information!")
	
	if turn_indicator:
		update_turn_display()
	else:
		highlight_player_pits(0)

func force_normal_shells_in_pit(pit: Node2D):
	# Find all shells in this pit and force them to be normal shells
	var game_scene = get_tree().root.get_node_or_null("Gameplay")
	if not game_scene:
		game_scene = get_parent()
	
	var shell_area = pit.get_node_or_null("ShellArea")
	if not shell_area:
		return
	
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	
	for child in game_scene.get_children():
		if child.is_in_group("Shells") and child in overlapping_bodies:
			child.set_shell_type(1)  # Force to normal shell

func get_main_house(player_index: int) -> Node2D:
	if player_index < main_houses.size():
		return main_houses[player_index]
	return null

func add_shells_to_main_house(player_index: int, amount: int):
	var house = get_main_house(player_index)
	if house:
		if house.has_method("add_shells"):
			house.add_shells(amount)
		print("Added ", amount, " shells to player ", player_index + 1, "'s main house")

func get_main_house_shells(player_index: int) -> int:
	var house = get_main_house(player_index)
	if house and house.has_method("shells"):
		return house.shells
	return 0

func get_pit(pit_index: int) -> Node2D:
	if pit_index < pits.size():
		return pits[pit_index]
	return null

func switch_turn():
	current_turn = 1 - current_turn
	print("Turn switched to player ", current_turn + 1)
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	for child in pvp.get_children():
		if child.is_in_group("pits"):
			child.pit_endround()
			var tween = create_tween()
			tween.tween_interval(0.05)
			await tween.finished
		if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
			child.shell_endround()
			var tween = create_tween()
			tween.tween_interval(0.05)
			await tween.finished
	update_turn_display()

func check_game_over() -> bool:
	var player1_empty = true
	var player2_empty = true
	
	for i in range(7):
		if get_pit(i) and get_pit(i).shells > 0:
			player1_empty = false
			break
	
	for i in range(7, 14):
		if get_pit(i) and get_pit(i).shells > 0:
			player2_empty = false
			break
	
	if player1_empty or player2_empty:
		end_game()
		return true
	
	return false

func end_game():
	game_active = false
	awaiting_special_shell_selection = false
	special_shell_selector.hide_selection()
	print("Game Over!")
	
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
	
	add_shells_to_main_house(0, player1_remaining)
	add_shells_to_main_house(1, player2_remaining)
	
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
