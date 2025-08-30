extends Node

var current_turn: int = 0
var total_turns: int = 0
var pits: Array
var main_houses: Array
var game_active: bool = true
var is_distributing: bool = false
var awaiting_special_shell_selection: bool = false

var timer: Timer

# UI Elements
var turn_indicator: Label
var player1_label: Label
var player2_label: Label
var special_shell_selector: Control


# END GAME SCREEN ELEMENTS
var end_game_overlay: Control
var end_game_background: ColorRect
var winner_label: Label
var final_scores_label: Label
var play_again_button: Button
var quit_button: Button
var WINNING_SCORE: int = 100

# Resolution scaling
var base_resolution = Vector2(1920, 1080)
var ui_scale_factor: float = 1.0

func _ready():
	add_to_group("game_manager")
	pits = get_tree().get_nodes_in_group("pits")
	main_houses = get_tree().get_nodes_in_group("main_houses")
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	# Connect timer timeout to our check function
	timer.timeout.connect(_on_timer_timeout)
	
	calculate_ui_scale()
	call_deferred("create_ui_elements")
	call_deferred("start_game")
	call_deferred("create_special_shell_selector")
	call_deferred("create_end_game_screen")
	
	

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

# NEW: Create end game overlay screen
func create_end_game_screen():
	await get_tree().process_frame
	
	# SINGLE CONTROL POINT - Change these values to move everything
	var ui_offset_x = 390   # Negative = left, Positive = right
	var ui_offset_y = 200   # Negative = up, Positive = down
	
	# BACKGROUND OPACITY CONTROL - Change this single value
	var background_opacity = 0.7  # 0.0 = transparent, 1.0 = completely black
	
	# Create overlay container
	end_game_overlay = Control.new()
	end_game_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_game_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	end_game_overlay.visible = false
	get_parent().add_child(end_game_overlay)
	
	# *** THIS IS THE KEY PART - Semi-transparent BLACK background ***
	end_game_background = ColorRect.new()
	end_game_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_game_background.color = Color(0, 0, 0, background_opacity)  # BLACK with opacity
	end_game_overlay.add_child(end_game_background)
	
	# Winner announcement - APPLY OFFSET
	winner_label = Label.new()
	winner_label.text = "GAME OVER"
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	winner_label.position = scaled_position(Vector2(460 + ui_offset_x, 300 + ui_offset_y))
	winner_label.size = scaled_position(Vector2(1000, 150))
	winner_label.add_theme_font_size_override("font_size", scaled_font_size(72))
	winner_label.add_theme_color_override("font_color", Color.WHITE)
	winner_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	winner_label.add_theme_constant_override("shadow_offset_x", 4)
	winner_label.add_theme_constant_override("shadow_offset_y", 4)
	end_game_overlay.add_child(winner_label)
	
	# Final scores - APPLY OFFSET
	final_scores_label = Label.new()
	final_scores_label.text = ""
	final_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_scores_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	final_scores_label.position = scaled_position(Vector2(460 + ui_offset_x, 480 + ui_offset_y))
	final_scores_label.size = scaled_position(Vector2(1000, 200))
	final_scores_label.add_theme_font_size_override("font_size", scaled_font_size(36))
	final_scores_label.add_theme_color_override("font_color", Color.WHITE)
	final_scores_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	final_scores_label.add_theme_constant_override("shadow_offset_x", 2)
	final_scores_label.add_theme_constant_override("shadow_offset_y", 2)
	end_game_overlay.add_child(final_scores_label)
	
	# Play Again button - APPLY OFFSET
	play_again_button = Button.new()
	play_again_button.text = "PLAY AGAIN"
	play_again_button.position = scaled_position(Vector2(705 + ui_offset_x, 1020 + ui_offset_y))
	play_again_button.size = scaled_position(Vector2(220, 100))
	play_again_button.add_theme_font_size_override("font_size", scaled_font_size(24))
	play_again_button.pressed.connect(_on_play_again_pressed)
	end_game_overlay.add_child(play_again_button)
	
	# Quit button - APPLY OFFSET
	quit_button = Button.new()
	quit_button.text = "MAIN MENU"
	quit_button.position = scaled_position(Vector2(1005 + ui_offset_x, 1020 + ui_offset_y))
	quit_button.size = scaled_position(Vector2(220, 100))
	quit_button.add_theme_font_size_override("font_size", scaled_font_size(24))
	quit_button.pressed.connect(_on_quit_pressed)
	end_game_overlay.add_child(quit_button)
	
	print("End game screen created successfully with black overlay!")

# QUICK REFERENCE FOR ADJUSTMENTS:
# ui_offset_x = 390     # Current right offset
# ui_offset_y = 200     # Current down offset  
# background_opacity = 0.8  # Current darkness level

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
	player1_label.position = Vector2(150, 500)
	player1_label.add_theme_font_size_override("font_size", scaled_font_size(30))
	player1_label.add_theme_color_override("font_color", Color.CYAN)
	player1_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player1_label.add_theme_constant_override("shadow_offset_x", 2)
	player1_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(player1_label)
	
	player2_label = Label.new()
	player2_label.text = "PLAYER 2 (RED)"
	player2_label.position = Vector2(1440, 500)
	player2_label.add_theme_font_size_override("font_size", scaled_font_size(30))
	player2_label.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	player2_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player2_label.add_theme_constant_override("shadow_offset_x", 2)
	player2_label.add_theme_constant_override("shadow_offset_y", 2)
	get_parent().add_child(player2_label)
	
	await get_tree().process_frame
	total_turns = 1
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	pvp.updateRoundlabel(total_turns)
	update_turn_display()
	print("UI Elements created successfully!")

func create_special_shell_selector():
	# Get reference to the selector that's already in the scene
	special_shell_selector = get_parent().get_node("SpecialShellSelector")
	if special_shell_selector:
		special_shell_selector.special_shell_selected.connect(_on_special_shell_selected)
		special_shell_selector.pit_type_selected.connect(_on_pit_type_selected)
		print("Special shell selector connected!")
	else:
		print("ERROR: SpecialShellSelector not found in scene!")
		
func _on_pit_type_selected(pit_type: int, pit_index: int):
	awaiting_special_shell_selection = false
	
	if pit_type > 0:
		print("Player ", current_turn + 1, " selected pit type ", pit_type)
	else:
		print("Player ", current_turn + 1, " skipped pit type selection")
	
	switch_turn()
	check_game_over()
	
func update_turn_display():
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	for child in pvp.get_children():
		if is_instance_valid(child):
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
	else:
		turn_indicator.text = "PLAYER 2's Turn (RED)"
		turn_indicator.add_theme_color_override("font_color", Color.LIGHT_CORAL)

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
	
	var estimated_duration = shells_to_distribute * 0.15
	await get_tree().create_timer(estimated_duration).timeout
	
	# Calculate the final position properly
	var final_position = calculate_final_position(start_pit_index, shells_to_distribute)
	
	is_distributing = false
	check_end_turn_rules(final_position)

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

func _on_timer_timeout():
	
	var moving_shells = get_tree().get_nodes_in_group("MoveShells")
	
	if moving_shells.size() == 0:
		var pvp = get_tree().root.get_node_or_null("Gameplay")
		var camera = pvp.get_node_or_null("Camera2D")
		camera.move_to_position("Top")
		is_distributing = false
		Pit_Order()
		show_special_shell_selection()
		timer.stop()
	else:
		timer.start()

func check_end_turn_rules(last_position: int):
	print("Checking end turn rules. Last position: ", last_position)
	
	# Rule: Extra turn for landing in own main house
	if (current_turn == 0 and last_position == 14) or (current_turn == 1 and last_position == 15):
		print("Player ", current_turn + 1, " gets another turn!")
		return
	
	# Rule: Capture for landing in own empty pit
	if last_position < 14:
		var pit = get_pit(last_position)
		if pit and pit.shells == 1:  # Was empty before the shell
			var player_range = get_player_pit_range(current_turn)
			if last_position >= player_range[0] and last_position <= player_range[1]:
				capture_opposite_pit(last_position)
	
	# Show special shell selection before switching turns
	timer.start()
	is_distributing = true

func show_special_shell_selection():
	awaiting_special_shell_selection = true
	update_turn_display()
	special_shell_selector.show_selection(current_turn)

func _on_special_shell_selected(shell_type: int, pit_index: int):
	awaiting_special_shell_selection = false
	
	if shell_type > 0:
		print("Player ", current_turn + 1, " selected special shell type ", shell_type)
	else:
		print("Player ", current_turn + 1, " skipped special shell selection")
	
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
		force_normal_shells_in_pit(pit)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	# Now enable timer counting for all pits
	for pit in pits:
		if pit.has_method("enable_timer_counting"):
			pit.enable_timer_counting()
	
	for house in main_houses:
		if house.has_method("update_label"):
			house.update_label()
	
	print("Game initialized with ", pits.size(), " pits and ", main_houses.size(), " main houses")
	
	if turn_indicator:
		update_turn_display()

func force_normal_shells_in_pit(pit: Node2D):
	var game_scene = get_tree().root.get_node_or_null("Gameplay")
	if not game_scene:
		game_scene = get_parent()
	
	var shell_area = pit.get_node_or_null("ShellArea")
	if not shell_area:
		return
	
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	
	for child in game_scene.get_children():
		if child.is_in_group("Shells") and child in overlapping_bodies:
			child.set_shell_type(1)

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

func Pit_Heal():
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("pits"):
				if child.PitType == 8:
					child.pit_endround()
					var tween = create_tween()
					tween.tween_interval(0.05)
					await tween.finished
func Pit_Order():
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("pits"):
				if child.PitType == 5 or child.PitType == 9 or child.PitType == 10:
					child.pit_endround()
					var tween = create_tween()
					tween.tween_interval(0.1)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("pits"):
				if child.PitType == 3 or child.PitType == 4 or child.PitType == 11:
					child.pit_endround()
					var tween = create_tween()
					tween.tween_interval(0.1)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("pits"):
				if child.PitType == 1 or child.PitType == 2 or child.PitType == 7:
					child.pit_endround()
					var tween = create_tween()
					tween.tween_interval(0.1)
					await tween.finished
	Shell_Order()
	
func Shell_Order():
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 3 or child.Type == 5 or child.Type == 8:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.05)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 1 or child.Type == 2:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.05)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 7:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.2)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 4:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.2)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 6:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.2)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 9:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.1)
					await tween.finished
	for child in pvp.get_children():
		if is_instance_valid(child):
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child.Type == 12:
					child.shell_endround()
					var tween = create_tween()
					tween.tween_interval(0.1)
					await tween.finished
	Pit_Heal()

func switch_turn():
	current_turn = 1 - current_turn
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var camera = pvp.get_node_or_null("Camera2D")
	camera.move_to_position("Center")
	print("Turn switched to player ", current_turn + 1)
	total_turns += 1
	pvp.updateRoundlabel(total_turns)
	update_turn_display()

# ENHANCED: Better game over checking with multiple win conditions
func check_game_over() -> bool:
	# NEW: Score-based win condition - check if any player reached 100 total score
	var player1_total_score = 0
	var player2_total_score = 0
	
	if main_houses.size() >= 2:
		# Get total scores from main houses
		if main_houses[0] and main_houses[0].has_method("get_total_score"):
			player1_total_score = main_houses[0].get_total_score()
		
		if main_houses[1] and main_houses[1].has_method("get_total_score"):
			player2_total_score = main_houses[1].get_total_score()
		
		print("Current total scores - Player 1: ", player1_total_score, ", Player 2: ", player2_total_score)
		
		# Check if either player reached the winning score
		if player1_total_score >= WINNING_SCORE or player2_total_score >= WINNING_SCORE:
			print("Score-based win condition met!")
			end_game_score_based(player1_total_score, player2_total_score)
			return true
	
	# Fallback: Standard Mancala win condition if no one reached 100 points yet
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
		print("Standard win condition met - one player has no shells left")
		end_game()
		return true
	
	return false
	
func end_game_score_based(player1_score: int, player2_score: int):
	game_active = false  # This stops new moves but keeps everything else running
	awaiting_special_shell_selection = false
	if special_shell_selector:
		special_shell_selector.hide_selection()
	print("Game Over - Score-based victory!")
	
	# Show end game screen with current scores (no stopping activities)
	show_end_game_screen_score_based(player1_score, player2_score)

func show_end_game_screen_score_based(player1_score: int, player2_score: int):
	if not end_game_overlay:
		print("ERROR: End game overlay not found!")
		return
	
	# Determine winner and set colors
	var winner_text: String
	var winner_color: Color
	
	if player1_score >= WINNING_SCORE and player2_score >= WINNING_SCORE:
		# Both reached 100, higher score wins
		if player1_score > player2_score:
			winner_text = "PLAYER 1 WINS!"
			winner_color = Color.CYAN
		elif player2_score > player1_score:
			winner_text = "PLAYER 2 WINS!"
			winner_color = Color.LIGHT_CORAL
		else:
			winner_text = "IT'S A TIE!"
			winner_color = Color.YELLOW
	elif player1_score >= WINNING_SCORE:
		winner_text = "PLAYER 1 WINS!"
		winner_color = Color.CYAN
	elif player2_score >= WINNING_SCORE:
		winner_text = "PLAYER 2 WINS!"
		winner_color = Color.LIGHT_CORAL
	else:
		winner_text = "GAME OVER"
		winner_color = Color.WHITE
	
	# Update winner label
	winner_label.text = winner_text
	winner_label.add_theme_color_override("font_color", winner_color)
	
	# Update final scores
	var scores_text = "FINAL TOTAL SCORES:\n\nPlayer 1 (Blue): " + str(player1_score) + " points"
	if player1_score >= WINNING_SCORE:
		scores_text += " ★ WINNER!"
	
	scores_text += "\nPlayer 2 (Red): " + str(player2_score) + " points"
	if player2_score >= WINNING_SCORE:
		scores_text += " ★ WINNER!"
	
	if player1_score != player2_score:
		var margin = abs(player1_score - player2_score)
		scores_text += "\n\nMargin of Victory: " + str(margin) + " points"
	
	scores_text += "\n\nFirst to " + str(WINNING_SCORE) + " points wins!"
	
	final_scores_label.text = scores_text
	
	# Show the overlay with animation
	end_game_overlay.modulate = Color(1, 1, 1, 0)  # Start transparent
	end_game_overlay.visible = true
	
	var tween = create_tween()
	tween.tween_property(end_game_overlay, "modulate:a", 1.0, 0.5)  # Fade in
	
	print("Score-based end game screen displayed: ", winner_text)
# ENHANCED: Better end game with overlay screen
func end_game():
	game_active = false  # This stops new moves but keeps everything else running
	awaiting_special_shell_selection = false
	if special_shell_selector:
		special_shell_selector.hide_selection()
	print("Game Over!")
	
	# Collect remaining shells from pits
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
	
	# Calculate final scores
	var player1_score = get_main_house_shells(0)
	var player2_score = get_main_house_shells(1)
	
	# Show end game screen with results
	show_end_game_screen(player1_score, player2_score)

# NEW: Display the end game screen
func show_end_game_screen(player1_score: int, player2_score: int):
	if not end_game_overlay:
		print("ERROR: End game overlay not found!")
		return
	
	# Determine winner and set colors
	var winner_text: String
	var winner_color: Color
	
	if player1_score > player2_score:
		winner_text = "PLAYER 1 WINS!"
		winner_color = Color.CYAN
	elif player2_score > player1_score:
		winner_text = "PLAYER 2 WINS!"
		winner_color = Color.LIGHT_CORAL
	else:
		winner_text = "IT'S A TIE!"
		winner_color = Color.YELLOW
	
	# Update winner label
	winner_label.text = winner_text
	winner_label.add_theme_color_override("font_color", winner_color)
	
	# Update final scores
	var scores_text = "FINAL SCORES:\n\nPlayer 1 (Blue): " + str(player1_score) + " shells\nPlayer 2 (Red): " + str(player2_score) + " shells"
	if player1_score != player2_score:
		var margin = abs(player1_score - player2_score)
		scores_text += "\n\nMargin of Victory: " + str(margin) + " shells"
	
	final_scores_label.text = scores_text
	
	# Show the overlay with animation
	end_game_overlay.modulate = Color(1, 1, 1, 0)  # Start transparent
	end_game_overlay.visible = true
	
	var tween = create_tween()
	tween.tween_property(end_game_overlay, "modulate:a", 1.0, 0.5)  # Fade in
	
	print("End game screen displayed: ", winner_text)

# NEW: Handle play again button
func _on_play_again_pressed():
	print("Restarting game...")
	
	# Hide end game screen
	end_game_overlay.visible = false
	
	# Reset game state
	game_active = true
	current_turn = 0
	is_distributing = false
	awaiting_special_shell_selection = false
	
	# Reset main house scores
	for house in main_houses:
		if house.has_method("set_shells"):
			house.set_shells(0)
	
	# Restart the game
	call_deferred("start_game")

# NEW: Handle quit button
func _on_quit_pressed():
	print("Returning to main menu...")
	# Change scene to main menu
	get_tree().change_scene_to_file("res://Main Menu/main_menu.tscn")

# OPTIONAL: Add pause/unpause functionality
func pause_game():
	game_active = false
	print("Game paused")

func unpause_game():
	game_active = true
	print("Game unpaused")

# OPTIONAL: Add game statistics tracking
var games_played: int = 0
var player1_wins: int = 0
var player2_wins: int = 0
var ties: int = 0

func track_game_result(player1_score: int, player2_score: int):
	games_played += 1
	if player1_score > player2_score:
		player1_wins += 1
	elif player2_score > player1_score:
		player2_wins += 1
	else:
		ties += 1
	
	print("Game Statistics - Played: ", games_played, " P1 Wins: ", player1_wins, " P2 Wins: ", player2_wins, " Ties: ", ties)
