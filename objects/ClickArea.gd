extends Area2D

var pit_index: int = -1
var associated_pit: Node2D
var original_color: Color = Color.WHITE  # Store the original color

# Hover functionality
var hover_timer: Timer
var tooltip_system: ShellTooltip
var is_hovering: bool = false

func _ready():
	# Connect the input event signal
	input_event.connect(_on_input_event)
	
	# Add visual feedback on hover
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Setup hover tooltip functionality
	call_deferred("setup_hover_system")

func setup_hover_system():
	# Create hover timer with delay
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.8  # 0.8 second delay before showing tooltip
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)
	
	# Find or create tooltip system (deferred to avoid setup conflicts)
	call_deferred("find_tooltip_system")

func find_tooltip_system():
	# Look for existing tooltip system in the scene
	var game_node = get_tree().root.get_node_or_null("Gameplay")
	if not game_node:
		game_node = get_tree().root.get_node_or_null("Campaign")
	
	if game_node:
		tooltip_system = game_node.get_node_or_null("ShellTooltip")
		
		# Create tooltip system if it doesn't exist
		if not tooltip_system:
			var tooltip_scene = preload("res://objects/ShellTooltip.tscn")
			if tooltip_scene:
				tooltip_system = tooltip_scene.instantiate()
				game_node.add_child(tooltip_system)
				print("Created tooltip system from scene for ", associated_pit.name if associated_pit else "unknown pit")
			else:
				# Fallback: create tooltip system from script
				tooltip_system = preload("res://objects/ShellTooltip.gd").new()
				tooltip_system.name = "ShellTooltip"
				game_node.add_child(tooltip_system)
				print("Created new tooltip system from script for ", associated_pit.name if associated_pit else "unknown pit")
		else:
			print("Found existing tooltip system for ", associated_pit.name if associated_pit else "unknown pit")

func setup(pit: Node2D, index: int):
	associated_pit = pit
	pit_index = index
	print("ClickArea setup for pit: ", pit.name, " with index: ", index)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Handle left click - notify GameManager
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager and pit_index >= 0:
				print("Left click on pit ", pit_index, " (", associated_pit.name, ")")
				game_manager.handle_pit_click(pit_index)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Handle right click - show detailed tooltip
			if tooltip_system and associated_pit:
				print("Right click on pit ", pit_index, " (", associated_pit.name, ") - showing detailed tooltip")
				tooltip_system.show_detailed_tooltip_for_target(associated_pit)

func _on_mouse_entered():
	print("Mouse entered pit: ", associated_pit.name if associated_pit else "unknown")
	# Store the current color before changing it for visual feedback
	if associated_pit:
		original_color = associated_pit.modulate
		# Make it brighter by multiplying the current color
		associated_pit.modulate = original_color * 1.4  # 40% brighter
	
	# Start hover tooltip functionality
	if associated_pit:
		is_hovering = true
		hover_timer.start()
		print("Started hover timer for: ", associated_pit.name)
		
		# Also directly tell tooltip system to start hover
		if tooltip_system:
			tooltip_system.start_hover(associated_pit)

func _on_mouse_exited():
	print("Mouse exited pit: ", associated_pit.name if associated_pit else "unknown")
	# Restore the original color (which could be the player highlight color)
	if associated_pit:
		associated_pit.modulate = original_color
	
	# Stop hover tooltip functionality
	is_hovering = false
	hover_timer.stop()
	
	if tooltip_system:
		tooltip_system.stop_hover()
		print("Stopped hover for tooltip system")

func _on_hover_timer_timeout():
	print("Hover timer timeout for: ", associated_pit.name if associated_pit else "unknown")
	if is_hovering and tooltip_system and associated_pit:
		tooltip_system.show_tooltip_for_target(associated_pit)
	else:
		print("Cannot show tooltip - hover: ", is_hovering, ", tooltip_system: ", tooltip_system != null, ", pit: ", associated_pit != null)
