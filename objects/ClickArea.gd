extends Area2D

var pit_index: int = -1
var associated_pit: Node2D

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
	# Optional: Add visual feedback when hovering
	if associated_pit:
		var sprite = associated_pit.get_node("Sprite2D")
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.2)  # Slightly brighter

func _on_mouse_exited():
	# Reset visual feedback
	if associated_pit:
		var sprite = associated_pit.get_node("Sprite2D")
		if sprite:
			sprite.modulate = Color.WHITE
