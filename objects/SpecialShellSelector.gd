extends Control

signal special_shell_selected(shell_type: int, pit_index: int)
signal pit_type_selected(pit_type: int, pit_index: int)

var current_player: int = 0
var selected_shell_type: int = 0
var selected_pit_type: int = 0
var selection_phase: String = "type"  # "type", "shell", "pit", or "target"
var selection_mode: String = "mixed"  # Always "mixed" now - shows both shells and pits
var available_options: Array = []  # Will contain mixed shell and pit options
var option_types: Array = []  # Will track whether each option is "shell" or "pit"

@onready var type_buttons_container = $VBoxContainer/TypeButtonsContainer
@onready var options_container = $VBoxContainer/OptionsContainer
@onready var target_selection_label = $VBoxContainer/TargetSelectionLabel
@onready var title_label = $VBoxContainer/TitleLabel
@onready var confirm_button = $VBoxContainer/ConfirmButton
@onready var skip_button = $VBoxContainer/SkipButton

# Individual complete card image paths for shells
var shell_card_paths = {
	1: "res://assets/Cards/Basic Card.png",
	2: "res://assets/Cards/Golden Card.png",
	3: "res://assets/Cards/Echo Card.png",
	4: "res://assets/Cards/Anchor Card.png",
	5: "res://assets/Cards/Spirit Card.png",
	6: "res://assets/Cards/Time Card.png",
	7: "res://assets/Cards/Lucky Card.png",
	8: "res://assets/Cards/Mirror Card.png",
	9: "res://assets/Cards/Flame Card.png",
	10: "res://assets/Cards/Chain Card.png",
	11: "res://assets/Cards/Purify Card.png",
	12: "res://assets/Cards/Ice Card.png"
}

# Individual complete card image paths for pits
var pit_card_paths = {
	1: "res://assets/Cards/Basic Card.png",
	2: "res://assets/Cards/Anchor Card.png",
	3: "res://assets/Cards/Echo Card.png",
	4: "res://assets/Cards/Spirit Card.png",
	5: "res://assets/Cards/Loot Card.png",
	6: "res://assets/Cards/Chain Card.png",
	7: "res://assets/Cards/Golden Card.png",
	8: "res://assets/Cards/Purify Card.png",
	9: "res://assets/Cards/Void Card.png",
	10: "res://assets/Cards/Flame Card.png",
	11: "res://assets/Cards/Random Card.png"
}

var shell_types = {
	1: {"name": "Normal Shell", "description": "Basic shell that gains +1 score when in main house, starts with 1 score in pits.", "effect": "Basic +1", "color": Color.WHITE, "frame": 0},
	2: {"name": "Golden Shell", "description": "Gains +1 score each round and +5 score when in main house. A valuable treasure!", "effect": "Golden Growth", "color": Color.GOLD, "frame": 1},
	3: {"name": "Echo Shell", "description": "Creates a duplicate of itself when dropped into a pit. This magical shell splits into two!", "effect": "Duplication", "color": Color.RED, "frame": 2},
	4: {"name": "Anchor Shell", "description": "Gains multiplier stacks when in pits, increasing score of nearby shells permanently.", "effect": "Multiplier Boost", "color": Color.BLUE, "frame": 3},
	5: {"name": "Spirit Shell", "description": "Spawns a random shell type when in main house. Creates magical offspring!", "effect": "Random Spawn", "color": Color.PURPLE, "frame": 4},
	6: {"name": "Time Shell", "description": "Gains +2 score in main house, +1 in pits. Also boosts nearby shells over time.", "effect": "Time Boost", "color": Color.CYAN, "frame": 5},
	7: {"name": "Lucky Shell", "description": "Gains random score (1-5) when dropped. Fortune favors the bold!", "effect": "Random Luck", "color": Color.GREEN, "frame": 6},
	8: {"name": "Mirror Shell", "description": "Copies nearby shell types and can transform itself. Master of disguise!", "effect": "Type Copy", "color": Color.SILVER, "frame": 7},
	9: {"name": "Burn Shell", "description": "Applies burn effects to nearby shells and gains score for each burned shell.", "effect": "Burn Effect", "color": Color.ORANGE_RED, "frame": 8},
	10: {"name": "Chain Shell", "description": "Activates nearby shell effects and moves chain effects. Creates combinations!", "effect": "Chain Combo", "color": Color.YELLOW, "frame": 9},
	11: {"name": "Purify Shell", "description": "Removes negative status effects from nearby shells. Worth 3 base score!", "effect": "Status Cleanse", "color": Color.LIGHT_BLUE, "frame": 10},
	12: {"name": "Freeze Shell", "description": "Applies freeze effects to nearby shells and gains score for each frozen shell.", "effect": "Freeze Effect", "color": Color.LIGHT_CYAN, "frame": 11}
}

var pit_types = {
	1: {"name": "Basic Pit", "description": "At end of round, gives +1 score to shells in this pit if they belong to current player.", "effect": "Basic Score", "color": Color.WHITE, "frame": 0},
	2: {"name": "Anchor Pit", "description": "At end of round, gives +1 multiplier stack to shells in this pit if they belong to current player.", "effect": "Multiplier Stack", "color": Color.BLUE, "frame": 1},
	3: {"name": "Echo Pit", "description": "At end of round, 10% chance (+2.5% per luck) to duplicate shells in this pit (max 3).", "effect": "Shell Duplication", "color": Color.RED, "frame": 2},
	4: {"name": "Spirit Pit", "description": "At end of round, 25% chance (+2.5% per luck) to spawn a random shell if owned by current player.", "effect": "Random Spawn", "color": Color.PURPLE, "frame": 3},
	5: {"name": "Loot Pit", "description": "At end of round, 25% chance (+2.5% per luck) to move shells to opponent's main house.", "effect": "Loot Move", "color": Color.PINK, "frame": 4},
	6: {"name": "Chain Pit", "description": "When clicked, 25% chance (+2.5% per luck) to activate chain effects.", "effect": "Chain Trigger", "color": Color.YELLOW, "frame": 5},
	7: {"name": "Golden Pit", "description": "At end of round, gives multiple +1 score bonuses based on luck (up to 6 times).", "effect": "Multi Golden", "color": Color.GOLD, "frame": 6},
	8: {"name": "Healing Pit", "description": "At end of round, removes all negative status effects from shells.", "effect": "Status Cleanse", "color": Color.GREEN, "frame": 7},
	9: {"name": "Void Pit", "description": "When shells drop in, instantly moves them to void (removed from game).", "effect": "Void Removal", "color": Color.BLACK, "frame": 8},
	10: {"name": "Explosive Pit", "description": "At end of round, applies burn and randomly moves shells to other pits.", "effect": "Burn & Move", "color": Color.ORANGE_RED, "frame": 9},
	11: {"name": "Random Pit", "description": "At end of round, randomly changes the type of shells in this pit.", "effect": "Type Randomize", "color": Color.GRAY, "frame": 10}
}

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func _on_confirm_pressed():
	if selection_phase == "target":
		if selection_mode == "shell":
			emit_signal("special_shell_selected", 0, -1)
		else:
			emit_signal("pit_type_selected", 0, -1)
		hide_selection()
	else:
		hide_selection()

func show_selection(player: int):
	current_player = player
	selection_phase = "type"
	selection_mode = "mixed"
	
	title_label.text = "Player " + str(player + 1) + " - Special Selection"
	generate_mixed_options()
	
	show_type_selection()
	visible = true
	highlight_player_pits(player)

func show_type_selection():
	selection_phase = "type"
	type_buttons_container.visible = true
	options_container.visible = false
	target_selection_label.visible = false
	confirm_button.visible = false
	skip_button.visible = true
	skip_button.text = "Skip Turn"
	
	setup_card_selection()

func generate_mixed_options():
	available_options.clear()
	option_types.clear()
	
	var possible_shells = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	var possible_pits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	
	possible_shells.shuffle()
	possible_pits.shuffle()
	
	var patterns = [
		["shell", "pit", "shell"],
		["pit", "shell", "pit"], 
		["shell", "shell", "pit"],
		["pit", "pit", "shell"],
		["pit", "shell", "shell"],
		["shell", "pit", "pit"]
	]
	
	var selected_pattern = patterns[randi() % patterns.size()]
	
	var shell_index = 0
	var pit_index = 0
	
	for i in range(3):
		if selected_pattern[i] == "shell":
			available_options.append(possible_shells[shell_index])
			option_types.append("shell")
			shell_index += 1
		else:
			available_options.append(possible_pits[pit_index])
			option_types.append("pit")
			pit_index += 1

func setup_card_selection():
	# Clear existing cards
	for child in type_buttons_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Create horizontal container for cards
	var cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 30)
	
	# Create complete card images
	for i in range(available_options.size()):
		var option_id = available_options[i]
		var option_type = option_types[i]
		var card = create_complete_card(option_id, option_type)
		cards_container.add_child(card)
	
	type_buttons_container.add_child(cards_container)

# Main method - uses complete pre-made card images
# Main method - uses complete pre-made card images with better description overlay
func create_complete_card(option_id: int, option_type: String) -> Control:
	# Create main card container (not a button)
	var card_container = Control.new()
	card_container.custom_minimum_size = Vector2(200, 280)
	card_container.size = Vector2(200, 280)
	
	# Get the complete card image path
	var card_image_path: String
	if option_type == "shell":
		card_image_path = shell_card_paths[option_id]
	else:
		card_image_path = pit_card_paths[option_id]
	
	# Load the complete card texture
	var card_texture: Texture2D = load(card_image_path)
	
	# Create texture rect to display the complete card (as background)
	var card_display = TextureRect.new()
	card_display.texture = card_texture
	card_display.size = Vector2(200, 280)
	card_display.position = Vector2(0, 0)
	card_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Calculate the actual card visual size (based on your card design)
	# Your cards appear to be more like 180x260 within the 200x280 container
	var visual_card_size = Vector2(180, 260)
	var visual_card_offset = Vector2(17, 10)  # Exact hitbox alignment with the card
	
	# Create clickable button overlay (invisible but clickable) - matched to visual card size
	var click_button = Button.new()
	click_button.size = visual_card_size  # Match the actual visual card size
	click_button.position = visual_card_offset  # Offset to center on the visual card
	click_button.flat = true
	click_button.modulate = Color(1, 1, 1, 0)  # Completely transparent but still clickable
	click_button.mouse_filter = Control.MOUSE_FILTER_PASS  # Ensure proper mouse handling
	
	# Create name label with outline/shadow effect - positioned in top area
	var name_label = Label.new()
	name_label.size = Vector2(160, 25)
	name_label.position = Vector2(30, 30)  # Centered within the visual card area (17+20, 10+12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Get name text based on type
	var name_text: String
	if option_type == "shell":
		name_text = shell_types[option_id]["name"]
	else:
		name_text = pit_types[option_id]["name"]
	
	name_label.text = name_text
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 12)
	# Add outline for better readability
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)
	
	# Create description label - positioned in bottom area and properly contained
	var desc_label = Label.new()
	desc_label.size = Vector2(160, 70)
	desc_label.position = Vector2(30, 150)  # Centered within the visual card area (17+20, 200+10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Center align description
	desc_label.clip_contents = true  # Ensure text doesn't overflow
	
	# Get description text based on type
	var description_text: String
	if option_type == "shell":
		description_text = shell_types[option_id]["description"]
	else:
		description_text = pit_types[option_id]["description"]
	
	desc_label.text = description_text
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.add_theme_font_size_override("font_size", 10)  # Slightly smaller font
	# Add outline for better readability
	desc_label.add_theme_color_override("font_outline_color", Color.BLACK)
	desc_label.add_theme_constant_override("outline_size", 2)
	
	# Assemble the card (layered properly)
	card_container.add_child(card_display)      # Background card image
	card_container.add_child(name_label)        # Name text with outline
	card_container.add_child(desc_label)        # Description text with outline
	card_container.add_child(click_button)      # Invisible clickable overlay on top
	
	# Connect button functionality to the invisible button
	click_button.pressed.connect(_on_card_selected.bind(option_id, option_type))
	
	# Add hover effects - fix the signal binding issue
	click_button.mouse_entered.connect(_on_card_hover_enter_fixed.bind(card_container))
	click_button.mouse_exited.connect(_on_card_hover_exit_fixed.bind(card_container))
	
	return card_container

# Fixed hover functions to avoid signal binding errors
func _on_card_hover_enter_fixed(card_container: Control):
	# Scale up slightly on hover with smooth animation
	var tween = card_container.create_tween()
	if tween:
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(card_container, "scale", Vector2(1.05, 1.05), 0.15)
func _on_card_hover_exit_fixed(card_container: Control):
	# Scale back to normal with smooth animation
	var tween = card_container.create_tween()
	if tween:
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.15)

func _on_card_hover_enter(card_button: Button):
	# Scale up slightly on hover with smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card_button, "scale", Vector2(1.05, 1.05), 0.15)

func _on_card_hover_exit(card_button: Button):
	# Scale back to normal with smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card_button, "scale", Vector2(1.0, 1.0), 0.15)

func _on_card_selected(option_id: int, option_type: String):
	selection_mode = option_type
	
	if selection_mode == "shell":
		selected_shell_type = option_id
		var shell_info = shell_types[option_id]
		title_label.text = "Player " + str(current_player + 1) + " - Place " + shell_info["name"]
		target_selection_label.text = shell_info["description"] + "\n\nClick on one of your pits to place this shell there."
	else:
		selected_pit_type = option_id
		var pit_info = pit_types[option_id]
		title_label.text = "Player " + str(current_player + 1) + " - Set " + pit_info["name"]
		target_selection_label.text = pit_info["description"] + "\n\nClick on one of your pits to change it to this type."
	
	selection_phase = "target"
	type_buttons_container.visible = false
	target_selection_label.visible = true
	skip_button.visible = true
	skip_button.text = "Back to Selection"

func handle_pit_click(pit_index: int) -> bool:
	if not visible or selection_phase != "target":
		return false
	
	var player_range = get_player_pit_range(current_player)
	if pit_index < player_range[0] or pit_index > player_range[1]:
		print("Invalid pit selection for player ", current_player + 1)
		return false
	
	if selection_mode == "shell":
		spawn_special_shell(selected_shell_type, pit_index)
		emit_signal("special_shell_selected", selected_shell_type, -1)
	else:
		change_pit_type(selected_pit_type, pit_index)
		emit_signal("pit_type_selected", selected_pit_type, pit_index)
	
	hide_selection()
	return true

func change_pit_type(pit_type: int, pit_index: int):
	var pits = get_tree().get_nodes_in_group("pits")
	if pit_index < pits.size() and pits[pit_index]:
		var pit = pits[pit_index]
		if pit.has_method("set_pit_type"):
			pit.set_pit_type(pit_type)
			print("Changed pit ", pit_index + 1, " to type ", pit_type)

func _on_skip_pressed():
	if selection_phase == "type":
		if selection_mode == "shell":
			emit_signal("special_shell_selected", 0, -1)
		else:
			emit_signal("pit_type_selected", 0, -1)
		hide_selection()
	else:
		show_type_selection()

func spawn_special_shell(shell_type: int, pit_index: int):
	var gameplay = get_tree().root.get_node_or_null("Gameplay")
	if gameplay and gameplay.has_method("spawn_shell"):
		gameplay.spawn_shell(shell_type, pit_index + 1)
		print("Spawned special shell type ", shell_type, " at pit ", pit_index + 1)

func get_player_pit_range(player: int) -> Array:
	if player == 0:
		return [0, 6]
	else:
		return [7, 13]

func hide_selection():
	visible = false
	clear_pit_highlights()

func highlight_player_pits(player: int):
	var pits = get_tree().get_nodes_in_group("pits")
	var player_range = get_player_pit_range(player)
	var highlight_color = Color.CYAN if player == 0 else Color.LIGHT_CORAL
	
	for i in range(player_range[0], player_range[1] + 1):
		if i < pits.size() and pits[i]:
			pits[i].modulate = highlight_color

func clear_pit_highlights():
	var pits = get_tree().get_nodes_in_group("pits")
	for pit in pits:
		if pit:
			pit.modulate = Color.WHITE
