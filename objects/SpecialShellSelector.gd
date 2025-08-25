extends Control

signal special_shell_selected(shell_type: int, pit_index: int)

var current_player: int = 0
var selected_shell_type: int = 0
var selection_phase: String = "shell"  # "shell" or "pit"

@onready var shell_buttons_container = $VBoxContainer/ShellButtonsContainer
@onready var pit_selection_label = $VBoxContainer/PitSelectionLabel
@onready var title_label = $VBoxContainer/TitleLabel
@onready var confirm_button = $VBoxContainer/ConfirmButton
@onready var skip_button = $VBoxContainer/SkipButton

# Shell type definitions
var shell_types = {
	3: {
		"name": "Echo Shell", 
		"description": "Creates a duplicate of itself when dropped into a pit. This magical shell splits into two identical shells, doubling your shells at that location!",
		"effect": "Duplication Effect"
	}
}

func _ready():
	visible = false
	setup_shell_buttons()
	confirm_button.pressed.connect(_on_confirm_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func setup_shell_buttons():
	# Create a card-style button for Echo shell only
	var card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(300, 200)
	
	# Card background
	var card_bg = ColorRect.new()
	card_bg.color = Color(0.2, 0.3, 0.5, 0.9)  # Blue card background
	card_bg.custom_minimum_size = Vector2(300, 180)
	
	# Shell name label
	var name_label = Label.new()
	name_label.text = shell_types[3]["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.GOLD)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Effect label
	var effect_label = Label.new()
	effect_label.text = shell_types[3]["effect"]
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", Color.CYAN)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Description label
	var desc_label = Label.new()
	desc_label.text = shell_types[3]["description"]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(280, 60)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "SELECT ECHO SHELL"
	select_button.custom_minimum_size = Vector2(200, 40)
	select_button.add_theme_font_size_override("font_size", 16)
	select_button.pressed.connect(_on_shell_button_pressed.bind(3))
	
	# Assemble the card
	card_container.add_child(card_bg)
	card_container.add_child(name_label)
	card_container.add_child(effect_label)
	card_container.add_child(desc_label)
	card_container.add_child(select_button)
	
	shell_buttons_container.add_child(card_container)

func show_selection(player: int):
	current_player = player
	selection_phase = "shell"
	selected_shell_type = 0
	
	title_label.text = "Player " + str(player + 1) + " - Choose Your Shell"
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
	
	title_label.text = "Player " + str(current_player + 1) + " - Choose where to place " + shell_types[shell_type]["name"]
	pit_selection_label.text = shell_types[shell_type]["description"] + "\nClick on one of your pits to place this shell."
	pit_selection_label.visible = true
	shell_buttons_container.visible = false
	confirm_button.visible = false
	skip_button.text = "Cancel"

func _on_skip_pressed():
	if selection_phase == "shell":
		# Skip special shell selection
		emit_signal("special_shell_selected", 0, -1)  # 0 = no special shell
		hide_selection()
	else:
		# Cancel pit selection, go back to shell selection
		selection_phase = "shell"
		title_label.text = "Player " + str(current_player + 1) + " - Choose a Special Shell"
		pit_selection_label.visible = false
		shell_buttons_container.visible = true
		skip_button.text = "Skip Turn"

func _on_confirm_pressed():
	# This would be used if we want a confirm step, currently not needed
	pass

func handle_pit_click(pit_index: int) -> bool:
	if not visible or selection_phase != "pit":
		return false
	
	# Check if pit belongs to current player
	var player_range = get_player_pit_range(current_player)
	if pit_index < player_range[0] or pit_index > player_range[1]:
		print("Invalid pit selection for player ", current_player + 1)
		return false
	
	# Emit the selection
	emit_signal("special_shell_selected", selected_shell_type, pit_index)
	hide_selection()
	return true

func get_player_pit_range(player: int) -> Array:
	if player == 0:
		return [0, 6]  # Player 1 pits
	else:
		return [7, 13]  # Player 2 pits

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
