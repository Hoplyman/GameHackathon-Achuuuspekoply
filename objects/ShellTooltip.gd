extends Control
class_name ShellTooltip

var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var hover_timer: Timer
var is_hovering: bool = false
var current_target: Node2D = null

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
	11: {"name": "Random Pit", "effect": "Randomizes shell types at end of turn"}
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
	print("ShellTooltip initialized successfully")

func setup_tooltip_ui():
	# Create panel background
	tooltip_panel = Panel.new()
	tooltip_panel.modulate = Color(0.1, 0.1, 0.1, 0.95)  # Dark semi-transparent background
	add_child(tooltip_panel)
	
	# Create RichTextLabel for text
	tooltip_label = RichTextLabel.new()
	tooltip_label.fit_content = true
	tooltip_label.scroll_active = false
	tooltip_label.bbcode_enabled = true
	tooltip_label.add_theme_color_override("default_color", Color.WHITE)
	tooltip_panel.add_child(tooltip_label)

func start_hover(target: Node2D):
	if current_target == target and is_hovering:
		return
		
	current_target = target
	is_hovering = true
	hover_timer.start()
	print("Started hover for: ", target.name)

func stop_hover():
	is_hovering = false
	hover_timer.stop()
	visible = false
	current_target = null
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
	content += "\n"
	
	if shells_data.is_empty():
		content += format_empty_content_only()
		return content
	
	var total_shells = 0
	var total_points = 0
	
	# Sort shell types for consistent display
	var sorted_types = shells_data.keys()
	sorted_types.sort()
	
	for shell_type in sorted_types:
		var shell_info = shells_data[shell_type]
		var shell_name = shell_info["name"]
		var shell_scores = shell_info["shells"]
		
		total_shells += shell_scores.size()
		
		# Group shells by score for cleaner display
		var score_groups = {}
		for score in shell_scores:
			total_points += score
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
	
	# Add totals
	content += "\n[color=white]Total: %d shells, %d points[/color]" % [total_shells, total_points]
	
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
	
	# Calculate tooltip size
	await get_tree().process_frame
	var content_height = tooltip_label.get_content_height()
	var tooltip_width = 350  # Increased width for pit type info
	var tooltip_height = max(content_height + 30, 80)
	
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
	
	tooltip_label.position = Vector2(15, 15)
	tooltip_label.size = Vector2(tooltip_width - 30, tooltip_height - 30)
	
	# Position the entire tooltip
	position = tooltip_pos
	visible = true
	print("Tooltip displayed at position: ", tooltip_pos)

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
