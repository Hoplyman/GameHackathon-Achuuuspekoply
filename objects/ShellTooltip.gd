extends Control
class_name ShellTooltip

var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var hover_timer: Timer
var is_hovering: bool = false
var current_target: Node2D = null
var tooltip_locked: bool = false  # New: prevents tooltip from disappearing

# Shell type names for display
var shell_type_names = {
	1: "Normal Shell",
	2: "Gold Shell", 
	3: "Echo Shell",
	4: "Anchor Shell",
	5: "Spirit Shell",
	6: "Time Shell",
	7: "Lucky Shell",
	8: "Mirror Shell",
	9: "Burn Shell",
	10: "Chain Shell",
	11: "Purify Shell",
	12: "Freeze Shell"
}

# Pit type names and descriptions
var pit_type_names = {
	1: {"name": "Basic Pit", "effect": "Shells gain +1 Score at end of turn"},
	2: {"name": "Anchor Pit", "effect": "Shells gain +1 Multiplier at end of turn"},
	3: {"name": "Echo Pit", "effect": "20% chance to duplicate shells at end of turn"},
	4: {"name": "Spirit Pit", "effect": "Chance to spawn random shell at start of turn"},
	5: {"name": "Loot Pit", "effect": "25% chance to move shells to main house at end of turn"},
	6: {"name": "Chain Pit", "effect": "25% chance to trigger chain effects when clicked"},
	7: {"name": "Golden Pit", "effect": "Multiple chances for +1 Score at end of turn"},
	8: {"name": "Healing Pit", "effect": "Removes all debuffs from shells at start of turn"},
	9: {"name": "Void Pit", "effect": "Shells skip to next pit when dropped"},
	10: {"name": "Explosive Pit", "effect": "Shells gain Burn and move to random pit at end of turn"},
	11: {"name": "Random Pit", "effect": "Randomizes shell type or effect at end of turn"}
}

func _ready():
	# Create tooltip UI
	setup_tooltip_ui()
	
	# Create hover timer with delay
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.8  # 0.8 second delay before showing tooltip
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)
	
	# Make tooltip invisible initially
	visible = false
	# Ensure tooltip can receive mouse input
	mouse_filter = Control.MOUSE_FILTER_PASS
	print("ShellTooltip initialized successfully")

func setup_tooltip_ui():
	# Create panel background
	tooltip_panel = Panel.new()
	tooltip_panel.modulate = Color(1, 1, 1, 1)  # Dark semi-transparent background
	# Make sure panel can receive mouse input
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tooltip_panel)
	
	# Create RichTextLabel for text with scrolling enabled
	tooltip_label = RichTextLabel.new()
	tooltip_label.fit_content = false  # Allow manual sizing
	tooltip_label.scroll_active = true  # Enable scrolling
	tooltip_label.bbcode_enabled = true
	tooltip_label.add_theme_color_override("default_color", Color.WHITE)
	# Ensure RichTextLabel can receive mouse input for scrolling
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_panel.add_child(tooltip_label)
	
	# Make tooltip panel intercept mouse events for scrolling
	tooltip_panel.mouse_entered.connect(_on_tooltip_mouse_entered)
	tooltip_panel.mouse_exited.connect(_on_tooltip_mouse_exited)
	tooltip_label.mouse_entered.connect(_on_tooltip_mouse_entered)
	tooltip_label.mouse_exited.connect(_on_tooltip_mouse_exited)

# NEW: Handle mouse entering tooltip area
func _on_tooltip_mouse_entered():
	tooltip_locked = true
	print("Mouse entered tooltip - locking tooltip")
	
	# Find the associated ClickArea and tell it to keep hover active
	var click_areas = get_tree().get_nodes_in_group("click_areas")
	for click_area in click_areas:
		if click_area.associated_pit == current_target:
			click_area.keep_hover_active()
			break

# NEW: Handle mouse exiting tooltip area  
func _on_tooltip_mouse_exited():
	# Add a small delay to prevent rapid flickering
	await get_tree().create_timer(0.2).timeout
	
	# Check if mouse is still inside tooltip bounds
	var mouse_pos = get_global_mouse_position()
	var tooltip_rect = Rect2(global_position, tooltip_panel.size)
	
	if not tooltip_rect.has_point(mouse_pos):
		tooltip_locked = false
		print("Mouse actually exited tooltip - unlocking tooltip")
		
		# Check if mouse is also not over the original target
		var mouse_over_target = false
		if current_target:
			# Find the associated ClickArea
			var click_areas = get_tree().get_nodes_in_group("click_areas")
			for click_area in click_areas:
				if click_area.associated_pit == current_target:
					# Check if mouse is over the ClickArea
					var overlaps = click_area.get_overlapping_areas()
					var overlaps_bodies = click_area.get_overlapping_bodies()
					# Simple check: see if the click area is still detecting hover
					if click_area.is_hovering:
						mouse_over_target = true
						break
		
		# Only hide tooltip if mouse is not over target either
		if not mouse_over_target and not is_hovering:
			print("Mouse not over target or tooltip - hiding tooltip")
			stop_hover()
		else:
			print("Mouse still over target - keeping tooltip visible")
	else:
		print("Mouse still inside tooltip bounds - keeping locked")

func start_hover(target: Node2D):
	if current_target == target and is_hovering:
		return
	
	# If switching to a new target, clean up the old one first
	if current_target != target and visible:
		print("Switching targets - cleaning up old tooltip")
		visible = false
		tooltip_locked = false
	
	current_target = target
	is_hovering = true
	hover_timer.start()
	print("Started hover for: ", target.name)

func stop_hover():
	# Don't hide tooltip if it's locked (mouse is over it)
	if tooltip_locked:
		print("Tooltip locked - not hiding")
		return
		
	is_hovering = false
	hover_timer.stop()
	visible = false
	current_target = null
	tooltip_locked = false  # Ensure we reset the lock state
	print("Stopped hover")

func _on_hover_timer_timeout():
	print("Hover timer timeout - showing tooltip")
	if is_hovering and current_target:
		show_tooltip_for_target(current_target)

func show_tooltip_for_target(target: Node2D):
	print("Showing tooltip for: ", target.name)
	var content = analyze_shell_content(target, false)  # false = grouped view
	display_tooltip(content, target.global_position)

func show_detailed_tooltip_for_target(target: Node2D):
	print("Showing detailed tooltip for: ", target.name)
	var content = analyze_shell_content(target, true)  # true = detailed view
	display_tooltip(content, target.global_position)

func analyze_shell_content(target: Node2D, detailed_view: bool) -> String:
	var shell_area = target.get_node_or_null("ShellArea")
	if not shell_area:
		return "No shell area found"
	
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	var shells_data = {}  # Dictionary to store shell analysis
	var gamemode = get_gamemode()
	
	if gamemode == "":
		return "No valid game mode"
	
	var game_node = get_game_node(gamemode)
	if not game_node:
		return "Game node not found"
	
	# Analyze each shell
	for child in game_node.get_children():
		if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
			if child in overlapping_bodies:
				analyze_shell(child, shells_data, detailed_view)
	
	# Format the results with pit type information
	return format_shell_analysis(shells_data, target)

func analyze_shell(shell: Node2D, shells_data: Dictionary, detailed_view: bool):
	var shell_type = shell.Type
	var total_score = shell.TotalScore
	
	if not shells_data.has(shell_type):
		shells_data[shell_type] = {
			"name": shell_type_names.get(shell_type, "Unknown Shell"),
			"shells": []
		}
	
	if detailed_view:
		# Store individual shells with their scores
		shells_data[shell_type]["shells"].append(total_score)
	else:
		# Just count shells and sum scores
		shells_data[shell_type]["shells"].append(total_score)

func format_shell_analysis(shells_data: Dictionary, target: Node2D) -> String:
	var content = ""
	
	# Add pit type information at the top
	content += format_pit_info(target)
	
	if shells_data.is_empty():
		content += "\n"
		content += format_empty_content_only()
		return content
	
	var total_shells = 0
	var total_points = 0
	
	# First pass: calculate totals
	for shell_type in shells_data.keys():
		var shell_info = shells_data[shell_type]
		var shell_scores = shell_info["shells"]
		
		total_shells += shell_scores.size()
		for score in shell_scores:
			total_points += score
	
	# Add totals at the top, right after pit info
	content += "[color=white][b]Total: %d shells, %d points[/b][/color]\n\n" % [total_shells, total_points]
	
	# Sort shell types for consistent display
	var sorted_types = shells_data.keys()
	sorted_types.sort()
	
	for shell_type in sorted_types:
		var shell_info = shells_data[shell_type]
		var shell_name = shell_info["name"]
		var shell_scores = shell_info["shells"]
		
		# Group shells by score for cleaner display
		var score_groups = {}
		for score in shell_scores:
			if not score_groups.has(score):
				score_groups[score] = 0
			score_groups[score] += 1
		
		# Format each shell type
		if score_groups.size() == 1:
			# All shells of this type have same score
			var score = score_groups.keys()[0]
			var count = score_groups[score]
			var type_total = score * count
			content += "[color=cyan]%dx %s: %d points[/color]\n" % [count, shell_name, type_total]
		else:
			# Multiple different scores for this shell type
			var sorted_scores = score_groups.keys()
			sorted_scores.sort()
			sorted_scores.reverse()  # Show highest scores first
			
			for score in sorted_scores:
				var count = score_groups[score]
				var type_total = score * count
				content += "[color=cyan]%dx %s: %d points[/color]\n" % [count, shell_name, type_total]
	
	return content

func format_pit_info(target: Node2D) -> String:
	var header = "[color=yellow][b]%s[/b][/color]\n" % get_target_name(target)
	
	# Add pit type information if it's a pit
	if target.is_in_group("pits") and target.has_method("get") and "PitType" in target:
		var pit_type = target.PitType
		var pit_info = pit_type_names.get(pit_type, {"name": "Unknown Pit", "effect": "No effect"})
		
		header += "[color=orange]Type: %s[/color]\n" % pit_info["name"]
		header += "[color=lightgreen]Effect: %s[/color]\n" % pit_info["effect"]
	elif target.is_in_group("main_houses"):
		header += "[color=orange]Type: Main House[/color]\n"
		header += "[color=lightgreen]Effect: Stores shells and counts final score[/color]\n"
	
	return header

func format_empty_content_only() -> String:
	return "[color=gray]Empty - No shells present[/color]"

func get_target_name(target: Node2D) -> String:
	if target.is_in_group("pits"):
		return target.name
	elif target.is_in_group("main_houses"):
		var main_houses = get_tree().get_nodes_in_group("main_houses")
		var house_index = main_houses.find(target)
		if house_index == 0:
			return "Player 1 Main House"
		elif house_index == 1:
			return "Player 2 Main House"
		else:
			return "Main House"
	else:
		return target.name

func display_tooltip(content: String, world_position: Vector2):
	tooltip_label.text = content
	
	# Set fixed tooltip dimensions with scrolling
	var tooltip_width = 350  # Fixed width for pit type info
	var max_tooltip_height = 300  # Maximum height before scrolling kicks in
	var min_tooltip_height = 80   # Minimum height
	
	# Calculate actual content height
	await get_tree().process_frame
	var content_height = tooltip_label.get_content_height()
	var needed_height = content_height + 30  # Add padding
	
	# Use max height if content is too tall, otherwise use needed height
	var tooltip_height = min(max_tooltip_height, max(needed_height, min_tooltip_height))
	
	# Position tooltip near target but keep it on screen
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_pos = world_position + Vector2(20, -tooltip_height / 2)
	
	# Keep tooltip on screen
	if tooltip_pos.x + tooltip_width > viewport_size.x:
		tooltip_pos.x = world_position.x - tooltip_width - 20
	if tooltip_pos.y < 0:
		tooltip_pos.y = 10
	if tooltip_pos.y + tooltip_height > viewport_size.y:
		tooltip_pos.y = viewport_size.y - tooltip_height - 10
	
	# Set panel and label sizes and positions
	tooltip_panel.position = Vector2.ZERO
	tooltip_panel.size = Vector2(tooltip_width, tooltip_height)
	
	tooltip_label.position = Vector2(10, 10)
	tooltip_label.size = Vector2(tooltip_width - 20, tooltip_height - 20)
	
	# If content is taller than available space, enable scrolling
	if needed_height > max_tooltip_height:
		tooltip_label.scroll_active = true
		# Force focus on the RichTextLabel to ensure scroll events work
		tooltip_label.grab_focus()
		print("Tooltip content is tall (", needed_height, "px) - scrolling enabled")
	else:
		tooltip_label.scroll_active = false
		print("Tooltip content fits (", needed_height, "px) - no scrolling needed")
	
	# Position the entire tooltip
	position = tooltip_pos
	visible = true
	
	# Ensure tooltip is on top
	move_to_front()
	
	print("Tooltip displayed at position: ", tooltip_pos, " with size: ", Vector2(tooltip_width, tooltip_height))

func get_gamemode() -> String:
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if pvp:
		return "Pvp"
	elif campaign:
		return "Campaign"
	else:
		return ""

func get_game_node(gamemode: String) -> Node:
	if gamemode == "Pvp":
		return get_tree().root.get_node_or_null("Gameplay")
	elif gamemode == "Campaign":
		return get_tree().root.get_node_or_null("Campaign")
	else:
		return null
