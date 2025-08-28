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

# Your existing shell_types dictionary stays the same...
var shell_types = {
	1: {"name": "Normal Shell", "description": "Basic shell that gains +1 score when in main house, starts with 1 score in pits.", "effect": "Basic +1", "color": Color.WHITE},
	2: {"name": "Golden Shell", "description": "Gains +1 score each round and +5 score when in main house. A valuable treasure!", "effect": "Golden Growth", "color": Color.GOLD},
	3: {"name": "Echo Shell", "description": "Creates a duplicate of itself when dropped into a pit. This magical shell splits into two!", "effect": "Duplication", "color": Color.RED},
	4: {"name": "Anchor Shell", "description": "Gains multiplier stacks when in pits, increasing score of nearby shells permanently.", "effect": "Multiplier Boost", "color": Color.BLUE},
	5: {"name": "Spirit Shell", "description": "Spawns a random shell type when in main house. Creates magical offspring!", "effect": "Random Spawn", "color": Color.PURPLE},
	6: {"name": "Time Shell", "description": "Gains +2 score in main house, +1 in pits. Also boosts nearby shells over time.", "effect": "Time Boost", "color": Color.CYAN},
	7: {"name": "Lucky Shell", "description": "Gains random score (1-5) when dropped. Fortune favors the bold!", "effect": "Random Luck", "color": Color.GREEN},
	8: {"name": "Mirror Shell", "description": "Copies nearby shell types and can transform itself. Master of disguise!", "effect": "Type Copy", "color": Color.SILVER},
	9: {"name": "Burn Shell", "description": "Applies burn effects to nearby shells and gains score for each burned shell.", "effect": "Burn Effect", "color": Color.ORANGE_RED},
	10: {"name": "Chain Shell", "description": "Activates nearby shell effects and moves chain effects. Creates combinations!", "effect": "Chain Combo", "color": Color.YELLOW},
	11: {"name": "Purify Shell", "description": "Removes negative status effects from nearby shells. Worth 3 base score!", "effect": "Status Cleanse", "color": Color.LIGHT_BLUE},
	12: {"name": "Freeze Shell", "description": "Applies freeze effects to nearby shells and gains score for each frozen shell.", "effect": "Freeze Effect", "color": Color.LIGHT_CYAN}
}

# ADD THIS NEW pit_types dictionary:
var pit_types = {
	1: {"name": "Basic Pit", "description": "At end of round, gives +1 score to shells in this pit if they belong to current player.", "effect": "Basic Score", "color": Color.WHITE},
	2: {"name": "Anchor Pit", "description": "At end of round, gives +1 multiplier stack to shells in this pit if they belong to current player.", "effect": "Multiplier Stack", "color": Color.BLUE},
	3: {"name": "Echo Pit", "description": "At end of round, 10% chance (+2.5% per luck) to duplicate shells in this pit (max 3).", "effect": "Shell Duplication", "color": Color.RED},
	4: {"name": "Spirit Pit", "description": "At end of round, 25% chance (+2.5% per luck) to spawn a random shell if owned by current player.", "effect": "Random Spawn", "color": Color.PURPLE},
	5: {"name": "Loot Pit", "description": "At end of round, 25% chance (+2.5% per luck) to move shells to opponent's main house.", "effect": "Loot Move", "color": Color.PINK},
	6: {"name": "Chain Pit", "description": "When clicked, 25% chance (+2.5% per luck) to activate chain effects.", "effect": "Chain Trigger", "color": Color.YELLOW},
	7: {"name": "Golden Pit", "description": "At end of round, gives multiple +1 score bonuses based on luck (up to 6 times).", "effect": "Multi Golden", "color": Color.GOLD},
	8: {"name": "Healing Pit", "description": "At end of round, removes all negative status effects from shells.", "effect": "Status Cleanse", "color": Color.GREEN},
	9: {"name": "Void Pit", "description": "When shells drop in, instantly moves them to void (removed from game).", "effect": "Void Removal", "color": Color.BLACK},
	10: {"name": "Explosive Pit", "description": "At end of round, applies burn and randomly moves shells to other pits.", "effect": "Burn & Move", "color": Color.ORANGE_RED},
	11: {"name": "Random Pit", "description": "At end of round, randomly changes the type of shells in this pit.", "effect": "Type Randomize", "color": Color.GRAY}
}

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

# MISSING FUNCTION - ADD THIS:
func _on_confirm_pressed():
	if selection_phase == "target":
		if selection_mode == "shell":
			emit_signal("special_shell_selected", 0, -1)
		else:
			emit_signal("pit_type_selected", 0, -1)
		hide_selection()
	else:
		hide_selection()

# REPLACE show_selection function:
func show_selection(player: int):
	current_player = player
	selection_phase = "type"
	selection_mode = "mixed"  # Always use mixed mode now
	
	title_label.text = "Player " + str(player + 1) + " - Special Selection"
	generate_mixed_options()
	
	show_type_selection()
	visible = true
	highlight_player_pits(player)

# ADD these new functions:
func show_type_selection():
	selection_phase = "type"
	type_buttons_container.visible = true
	options_container.visible = false
	target_selection_label.visible = false
	confirm_button.visible = false
	skip_button.visible = true
	skip_button.text = "Skip Turn"
	
	setup_type_buttons()

# ADD new function for mixed options:
func generate_mixed_options():
	available_options.clear()
	option_types.clear()
	
	# Create pools of options
	var possible_shells = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	var possible_pits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	
	possible_shells.shuffle()
	possible_pits.shuffle()
	
	# Create a mixed pattern - we'll alternate but with some randomness
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

func setup_type_buttons():
	for child in type_buttons_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	
	for option in available_options:
		var card = create_option_card(option)
		cards_container.add_child(card)
	
	type_buttons_container.add_child(cards_container)

# REPLACE the create_option_card function with this corrected version:
func create_option_card(option_id: int) -> Control:
	var card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(180, 240)
	
	# Get the index to determine if this is a shell or pit option
	var option_index = available_options.find(option_id)
	var option_type = option_types[option_index] if option_index >= 0 else "shell"
	
	var option_info
	if option_type == "shell":
		option_info = shell_types[option_id]
	else:
		option_info = pit_types[option_id]
	
	# Create background for the entire card
	var card_bg = ColorRect.new()
	card_bg.color = Color(option_info.color.r * 0.3, option_info.color.g * 0.3, option_info.color.b * 0.3, 0.9)
	card_bg.custom_minimum_size = Vector2(180, 200)
	
	# Create content container that goes on top of background
	var content_container = VBoxContainer.new()
	content_container.custom_minimum_size = Vector2(180, 240)
	
	# Add type indicator at the top
	var type_indicator = Label.new()
	type_indicator.text = "SHELL" if option_type == "shell" else "PIT"
	type_indicator.add_theme_font_size_override("font_size", 10)
	type_indicator.add_theme_color_override("font_color", Color.YELLOW if option_type == "shell" else Color.ORANGE)
	type_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var name_label = Label.new()
	name_label.text = option_info["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", option_info.color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var effect_label = Label.new()
	effect_label.text = option_info["effect"]
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", Color.CYAN)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var desc_label = Label.new()
	desc_label.text = option_info["description"]
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(160, 70)
	
	var select_button = Button.new()
	select_button.text = "SELECT"
	select_button.custom_minimum_size = Vector2(120, 30)
	select_button.add_theme_font_size_override("font_size", 12)
	select_button.pressed.connect(_on_option_selected.bind(option_id, option_type))
	
	# Create spacers
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 4)
	
	# Add all content to the content container
	content_container.add_child(spacer1)
	content_container.add_child(type_indicator)
	content_container.add_child(spacer2)
	content_container.add_child(name_label)
	content_container.add_child(spacer2.duplicate()) # Create new spacer instance
	content_container.add_child(effect_label)
	content_container.add_child(spacer3)
	content_container.add_child(desc_label)
	content_container.add_child(select_button)
	
	# Add background first, then content on top
	card_container.add_child(card_bg)
	card_container.add_child(content_container)
	
	return card_container

# REPLACE the _on_option_selected function with this corrected version:
func _on_option_selected(option_id: int, option_type: String):
	# Determine the selection mode based on option_type
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
	skip_button.text = "Back to Selection"

# REPLACE handle_pit_click function:
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

# ADD this new function:
func change_pit_type(pit_type: int, pit_index: int):
	var pits = get_tree().get_nodes_in_group("pits")
	if pit_index < pits.size() and pits[pit_index]:
		var pit = pits[pit_index]
		if pit.has_method("set_pit_type"):
			pit.set_pit_type(pit_type)
			print("Changed pit ", pit_index + 1, " to type ", pit_type)

# UPDATE _on_skip_pressed function:
func _on_skip_pressed():
	if selection_phase == "type":
		if selection_mode == "shell":
			emit_signal("special_shell_selected", 0, -1)
		else:
			emit_signal("pit_type_selected", 0, -1)
		hide_selection()
	else:
		show_type_selection()

# You need to add these missing functions that are referenced but not included in your provided code:
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
