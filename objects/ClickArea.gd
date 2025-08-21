extends Area2D

var pit_index: int = -1
var associated_pit: Node2D
var original_color: Color = Color.WHITE  # Store the original color

func _ready():
	# Connect the input event signal
	input_event.connect(_on_input_event)
	
	# Optional: Add visual feedback on hover
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(pit: Node2D, index: int):
	associated_pit = pit
	pit_index = index

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Notify GameManager directly
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager and pit_index >= 0:
			game_manager.handle_pit_click(pit_index)

func _on_mouse_entered():
	# Store the current color before changing it
	if associated_pit:
		# The pit itself is a Sprite2D, so we modify it directly
		original_color = associated_pit.modulate
		# Make it brighter by multiplying the current color
		associated_pit.modulate = original_color * 1.4  # 40% brighter

func _on_mouse_exited():
	# Restore the original color (which could be the player highlight color)
	if associated_pit:
		# The pit itself is a Sprite2D, so we modify it directly
		associated_pit.modulate = original_color
