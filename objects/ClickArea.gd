extends Area2D

var pit_index: int = -1
var associated_pit: Node2D
var original_color: Color = Color.WHITE  # Store the original color

# Hover functionality
var hover_timer: Timer
var tooltip_system: ShellTooltip
var is_hovering: bool = false
var mouse_exit_timer: Timer  # New: delay before calling stop_hover

func _ready():
	# Add to group so tooltip can find us
	add_to_group("click_areas")
	
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
	
	# Create mouse exit timer to give time for mouse to reach tooltip
	mouse_exit_timer = Timer.new()
	mouse_exit_timer.wait_time = 0.3  # 0.3 second delay before stopping hover
	mouse_exit_timer.one_shot = true
	mouse_exit_timer.timeout.connect(_on_mouse_exit_timeout)
	add_child(mouse_exit_timer)
	
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
	
	# Cancel any pending mouse exit
	mouse_exit_timer.stop()
	
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
			# If tooltip is showing a different target, force cleanup first
			if tooltip_system.current_target and tooltip_system.current_target != associated_pit and tooltip_system.visible:
				print("Force cleaning up old tooltip before showing new one")
				tooltip_system.visible = false
				tooltip_system.tooltip_locked = false
				tooltip_system.current_target = null
				tooltip_system.is_hovering = false
			
			tooltip_system.start_hover(associated_pit)

func _on_mouse_exited():
	print("Mouse exited pit: ", associated_pit.name if associated_pit else "unknown")
	# Restore the original color (which could be the player highlight color)
	if associated_pit:
		associated_pit.modulate = original_color
	
	# Stop hover tooltip functionality with delay to allow mouse to reach tooltip
	is_hovering = false
	hover_timer.stop()
	
	# Start delayed stop hover to give mouse time to reach tooltip
	mouse_exit_timer.start()
	print("Started mouse exit timer - tooltip will stop in 0.3 seconds unless mouse reaches tooltip")

func _on_mouse_exit_timeout():
	# Only stop hover if tooltip isn't locked (mouse isn't over tooltip)
	if tooltip_system:
		# Always try to stop hover after the timeout - let tooltip decide if it should actually hide
		print("Mouse exit timeout - requesting tooltip stop")
		tooltip_system.stop_hover()
	
	print("ClickArea hover ended for: ", associated_pit.name if associated_pit else "unknown")

func _on_hover_timer_timeout():
	print("Hover timer timeout for: ", associated_pit.name if associated_pit else "unknown")
	if is_hovering and tooltip_system and associated_pit:
		tooltip_system.show_tooltip_for_target(associated_pit)
	else:
		print("Cannot show tooltip - hover: ", is_hovering, ", tooltip_system: ", tooltip_system != null, ", pit: ", associated_pit != null)

# New function: allow tooltip to keep ClickArea "alive" when mouse is over tooltip
func keep_hover_active():
	mouse_exit_timer.stop()
	print("Keeping hover active - tooltip requested it")
