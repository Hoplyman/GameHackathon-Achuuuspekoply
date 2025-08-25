extends Control

signal special_shell_selected(shell_type: int, pit_index: int)

var current_player: int = 0
var selected_shell_type: int = 0
var selection_phase: String = "shell"  # "shell" or "pit"
var available_shells: Array = []  # Will hold 3 random shell types each turn

@onready var shell_buttons_container = $VBoxContainer/ShellButtonsContainer
@onready var pit_selection_label = $VBoxContainer/PitSelectionLabel
@onready var title_label = $VBoxContainer/TitleLabel
@onready var confirm_button = $VBoxContainer/ConfirmButton
@onready var skip_button = $VBoxContainer/SkipButton

# Complete shell type definitions with all 12 types
var shell_types = {
	1: {
		"name": "Normal Shell", 
		"description": "Basic shell that gains +1 score when in main house, starts with 1 score in pits.",
		"effect": "Basic +1",
		"color": Color.WHITE
	},
	2: {
		"name": "Golden Shell", 
		"description": "Gains +1 score each round and +5 score when in main house. A valuable treasure!",
		"effect": "Golden Growth",
		"color": Color.GOLD
	},
	3: {
		"name": "Echo Shell", 
		"description": "Creates a duplicate of itself when dropped into a pit. This magical shell splits into two!",
		"effect": "Duplication",
		"color": Color.RED
	},
	4: {
		"name": "Anchor Shell", 
		"description": "Gains multiplier stacks when in pits, increasing score of nearby shells permanently.",
		"effect": "Multiplier Boost",
		"color": Color.BLUE
	},
	5: {
		"name": "Spirit Shell", 
		"description": "Spawns a random shell type when in main house. Creates magical offspring!",
		"effect": "Random Spawn",
		"color": Color.PURPLE
	},
	6: {
		"name": "Time Shell", 
		"description": "Gains +2 score in main house, +1 in pits. Also boosts nearby shells over time.",
		"effect": "Time Boost",
		"color": Color.CYAN
	},
	7: {
		"name": "Lucky Shell", 
		"description": "Gains random score (1-5) when dropped. Fortune favors the bold!",
		"effect": "Random Luck",
		"color": Color.GREEN
	},
	8: {
		"name": "Mirror Shell", 
		"description": "Copies nearby shell types and can transform itself. Master of disguise!",
		"effect": "Type Copy",
		"color": Color.SILVER
	},
	9: {
		"name": "Burn Shell", 
		"description": "Applies burn effects to nearby shells and gains score for each burned shell.",
		"effect": "Burn Effect",
		"color": Color.ORANGE_RED
	},
	10: {
		"name": "Chain Shell", 
		"description": "Activates nearby shell effects and moves chain effects. Creates combinations!",
		"effect": "Chain Combo",
		"color": Color.YELLOW
	},
	11: {
		"name": "Purify Shell", 
		"description": "Removes negative status effects from nearby shells. Worth 3 base score!",
		"effect": "Status Cleanse",
		"color": Color.LIGHT_BLUE
	},
	12: {
		"name": "Freeze Shell", 
		"description": "Applies freeze effects to nearby shells and gains score for each frozen shell.",
		"effect": "Freeze Effect",
		"color": Color.LIGHT_CYAN
	}
}

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func generate_random_shell_options():
	"""Generate 3 random shell types for this turn (excluding normal shell)"""
	available_shells.clear()
	var possible_shells = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  # Exclude type 1 (normal)
	
	# Shuffle and take first 3
	possible_shells.shuffle()
	for i in range(3):
		available_shells.append(possible_shells[i])
	
	print("Generated random shell options: ", available_shells)

func setup_shell_buttons():
	"""Create card-style buttons for the 3 random shells"""
	# Clear existing buttons
	for child in shell_buttons_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame  # Wait for cleanup
	
	# Create horizontal container for the 3 cards
	var cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	
	for shell_type in available_shells:
		var card = create_shell_card(shell_type)
		cards_container.add_child(card)
	
	shell_buttons_container.add_child(cards_container)

func create_shell_card(shell_type: int) -> Control:
	"""Create a card for a specific shell type"""
	var card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(180, 220)
	
	# Card background
	var card_bg = ColorRect.new()
	var shell_info = shell_types[shell_type]
	card_bg.color = Color(shell_info.color.r * 0.3, shell_info.color.g * 0.3, shell_info.color.b * 0.3, 0.9)
	card_bg.custom_minimum_size = Vector2(180, 200)
	
	# Shell name label
	var name_label = Label.new()
	name_label.text = shell_info["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", shell_info.color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Effect label
	var effect_label = Label.new()
	effect_label.text = shell_info["effect"]
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", Color.CYAN)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Description label
	var desc_label = Label.new()
	desc_label.text = shell_info["description"]
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(160, 80)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "SELECT"
	select_button.custom_minimum_size = Vector2(120, 30)
	select_button.add_theme_font_size_override("font_size", 12)
	select_button.pressed.connect(_on_shell_button_pressed.bind(shell_type))
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 5)
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 5)
	
	# Assemble the card
	card_container.add_child(card_bg)
	card_container.add_child(spacer1)
	card_container.add_child(name_label)
	card_container.add_child(spacer2)
	card_container.add_child(effect_label)
	card_container.add_child(spacer3)
	card_container.add_child(desc_label)
	card_container.add_child(select_button)
	
	return card_container

func show_selection(player: int):
	current_player = player
	selection_phase = "shell"
	selected_shell_type = 0
	
	# Generate 3 random shell options
	generate_random_shell_options()
	setup_shell_buttons()
	
	title_label.text = "Player " + str(player + 1) + " - Choose Your Special Shell"
	pit_selection_label.visible = false
	shell_buttons_container.visible = true
	confirm_button.visible = false
	skip_button.visible = true
	skip_button.text = "Skip Turn"
	
	visible = true
	
	# Highlight player's pits
	highlight_player_pits(player)

func _on_shell_button_pressed(shell_type: int):
	selected_shell_type = shell_type
	selection_phase = "pit"
	
	var shell_info = shell_types[shell_type]
	title_label.text = "Player " + str(current_player + 1) + " - Place " + shell_info["name"]
	pit_selection_label.text = shell_info["description"] + "\n\nClick on one of your pits to place this shell there."
	pit_selection_label.visible = true
	shell_buttons_container.visible = false
	confirm_button.visible = false
	skip_button.text = "Back to Selection"

func _on_skip_pressed():
	if selection_phase == "shell":
		# Skip special shell selection entirely
		emit_signal("special_shell_selected", 0, -1)  # 0 = no special shell
		hide_selection()
	else:
		# Go back to shell selection
		selection_phase = "shell"
		title_label.text = "Player " + str(current_player + 1) + " - Choose Your Special Shell"
		pit_selection_label.visible = false
		shell_buttons_container.visible = true
		skip_button.text = "Skip Turn"

func _on_confirm_pressed():
	# Currently not used, but could be for confirmation step
	pass

func handle_pit_click(pit_index: int) -> bool:
	if not visible or selection_phase != "pit":
		return false
	
	# Check if pit belongs to current player
	var player_range = get_player_pit_range(current_player)
	if pit_index < player_range[0] or pit_index > player_range[1]:
		print("Invalid pit selection for player ", current_player + 1, ". Must select pits ", player_range[0] + 1, "-", player_range[1] + 1)
		return false
	
	# Use spawn_shell from Gameplay.gd to create the special shell
	spawn_special_shell(selected_shell_type, pit_index)
	
	# Emit the selection (but pit_index -1 since we already spawned)
	emit_signal("special_shell_selected", selected_shell_type, -1)
	hide_selection()
	return true

func spawn_special_shell(shell_type: int, pit_index: int):
	"""Use Gameplay.gd's spawn_shell function to create the special shell"""
	var gameplay_node = get_tree().root.get_node_or_null("Gameplay")
	if not gameplay_node:
		print("ERROR: Gameplay node not found!")
		return
	
	if not gameplay_node.has_method("spawn_shell"):
		print("ERROR: spawn_shell method not found in Gameplay!")
		return
	
	# Convert pit index to the format expected by spawn_shell
	# Pit indices are 0-13, but spawn_shell expects 1-14
	var spawn_pit = pit_index + 1
	
	print("Spawning special shell type ", shell_type, " at pit ", spawn_pit, " using Gameplay.spawn_shell()")
	gameplay_node.spawn_shell(shell_type, spawn_pit)

func get_player_pit_range(player: int) -> Array:
	if player == 0:
		return [0, 6]  # Player 1 pits (0-6 = Pit1-Pit7)
	else:
		return [7, 13]  # Player 2 pits (7-13 = Pit8-Pit14)

func hide_selection():
	visible = false
	clear_pit_highlights()

func highlight_player_pits(player: int):
	var pits = get_tree().get_nodes_in_group("pits")
	
	# Reset all pit colors
	for pit in pits:
		if pit:
			pit.modulate = Color.WHITE
	
	# Highlight current player's pits
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
