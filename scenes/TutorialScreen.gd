extends Control

# Tutorial content data
var tutorial_steps: Array = []
var scroll_container: ScrollContainer
var content_container: VBoxContainer

# Resolution scaling
var base_resolution = Vector2(1920, 1080)
var ui_scale_factor: float = 1.0

# Navigation
var start_game_button: Button
var back_to_menu_button: Button

# Video players for each step
var video_players: Array[VideoStreamPlayer] = []

func _ready():
	# Wait for the scene to be fully ready
	await get_tree().process_frame
	
	calculate_ui_scale()
	setup_tutorial_steps()
	create_scrollable_tutorial()

func calculate_ui_scale():
	var viewport_size = get_viewport().get_visible_rect().size
	var width_ratio = viewport_size.x / base_resolution.x
	var height_ratio = viewport_size.y / base_resolution.y
	ui_scale_factor = min(width_ratio, height_ratio)
	ui_scale_factor = max(ui_scale_factor, 0.5)  # Minimum scale

func scaled_font_size(base_size: int) -> int:
	return max(int(base_size * ui_scale_factor), 12)  # Minimum font size

func scaled_size(base_size: Vector2) -> Vector2:
	return base_size * ui_scale_factor

func setup_tutorial_steps():
	tutorial_steps = [
		{
			"title": "Game Objective",
			"description": "Win by collecting the most shells!\n\nHow to Win:\n• The game ends when one player has no shells left in their pits\n• All remaining shells go to their owner's main house\n• Player with most shells in their main house wins\n\nYour Goal:\n• Collect shells in your main house (scoring area)\n• Use strategy to capture opponent shells\n• Empty opponent's pits while protecting your own",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Board Layout & Starting Setup",
			"description": "Understanding the Game Board\n\nBoard Components:\n• 14 Small Pits: 7 for each player\n• 2 Main Houses: Your scoring areas on the sides\n• Starting shells: 7 normal shells in each pit\n\nPlayer Areas:\n• Player 1 (Blue): Bottom row (pits 1-7)\n• Player 2 (Red): Top row (pits 8-14)\n• Each player's main house is on their side",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Basic Shell Movement",
			"description": "How to Move Shells\n\nMovement Rules:\n• Pick up ALL shells from one of YOUR pits\n• Drop shells one-by-one, counter-clockwise\n• Include your own main house in the path\n• Skip opponent's main house completely\n• Continue around the board if you have more shells\n\nImportant: You can only select pits on your side that contain shells!",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Extra Turn Rule",
			"description": "Get Bonus Turns!\n\nExtra Turn Trigger:\n• When your last shell lands exactly in YOUR main house\n• You immediately get another turn\n• No special shell selection after extra turns\n• Can chain multiple extra turns together\n\nStrategy:\n• Count shells to land in your main house\n• Extra turns give huge advantages\n• Plan moves to maximize bonus turns",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Capture Mechanics",
			"description": "Steal Opponent Shells!\n\nCapture Conditions:\n• Your last shell lands in an EMPTY pit on YOUR side\n• The opposite pit (opponent's side) contains shells\n• You capture shells from BOTH pits\n• All captured shells go to YOUR main house\n\nStrategy Tips:\n• Look for empty pits opposite full opponent pits\n• Plan moves to create capture opportunities\n• Defend against opponent captures",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Special Shell System Overview",
			"description": "12 Unique Special Shells!\n\nSpecial Shell Mechanics:\n• After each normal turn, select a special shell type (1-12)\n• Choose any pit to place the special shell\n• Special shells have unique abilities and timing\n• They activate at different phases of the game\n\nShell Categories:\n• Combat Shells: Destroy and damage\n• Defensive Shells: Protect and block\n• Utility Shells: Transform and manipulate\n• Strategic Shells: Control and enhance",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Normal & Golden Shells (Types 1-2)",
			"description": "Foundation Shells\n\nType 1 - Normal Shell (Base Score: 1):\n• In houses: Gains +1 score each end round\n• In pits: Resets to 1 score if not already 1\n• Basic building block of the game\n• Safe and reliable for movement\n\nType 2 - Golden Shell (Base Score: 5):\n• Always gains +1 score each end round\n• In houses: +5 score when dropped\n• High value shell for scoring\n• Consistent growth over time",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Echo & Anchor Shells (Types 3-4)",
			"description": "Duplication & Multiplication\n\nType 3 - Echo Shell (Base Score: 1):\n• End round: Creates a duplicate of itself\n• Drop: Affects nearby shells with echo effect\n• Can rapidly multiply your shell count\n• Strategic for late game advantage\n\nType 4 - Anchor Shell (Base Score: 1):\n• In pits: Gains multiplier stacks (+50% per stack)\n• Affects nearby shells on drop\n• Powerful for score multiplication\n• Best placed in stable pit positions",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Spirit & Time Shells (Types 5-6)",
			"description": "Spawning & Enhancement\n\nType 5 - Spirit Shell (Base Score: 1):\n• Drop: Spawns random shell (1-12) in same pit\n• End round in houses: Also spawns random shell\n• Creates unpredictable advantages\n• Good for resource generation\n\nType 6 - Time Shell (Base Score: 2):\n• In houses end round: +2 score bonus\n• In pits end round: Affects nearby shells with +1 score\n• Drop: Gives nearby shells +1 score immediately\n• Excellent support shell",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Lucky & Mirror Shells (Types 7-8)",
			"description": "Luck & Reflection Effects\n\nType 7 - Lucky Shell (Base Score: 2):\n• Drop: Gains 1-3 random score bonus\n• End round in pits: Gives nearby shells luck stacks\n• Gains luck stacks for score bonuses\n• Unpredictable but potentially powerful\n\nType 8 - Mirror Shell (Base Score: 1):\n• End round: Affects nearby shells with mirror\n• Drop: Copies one nearby shell type to another\n• Can transform shell types strategically\n• Versatile adaptation tool",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Flame & Chain Shells (Types 9-10)",
			"description": "Damage & Chain Reactions\n\nType 9 - Flame Shell (Base Score: 3):\n• End round: Burns nearby shells (reduces their score)\n• Gains +1 score per shell burned\n• Offensive area-of-effect shell\n• Good for weakening opponent positions\n\nType 10 - Chain Shell:\n• Drop: Triggers complex chain reactions on nearby shells\n• Can cause different effects based on nearby shell types\n• May trigger movement or other shell abilities\n• Advanced combo potential",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Purify & Ice Shells (Types 11-12)",
			"description": "Cleansing & Freezing\n\nType 11 - Purify Shell (Base Score: 5):\n• Drop: Removes all negative effects from nearby shells\n• Cleanses burn, freeze, decay, curse, and disable stacks\n• High base score with utility\n• Essential counter to debuff strategies\n\nType 12 - Ice Shell (Base Score: 3):\n• End round: Freezes nearby shells (reduces actions)\n• Gains +1 score per shell frozen\n• Control shell that limits opponent options\n• Defensive area denial",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Shell Status Effects & Stacks",
			"description": "Advanced Shell Mechanics\n\nStack Effects:\n• Multiplier Stacks: +50% score per stack (Type 4 shells)\n• Luck Stacks: Bonus effects from lucky interactions\n• Burn Stacks: -1 score per stack at end round\n• Freeze Stacks: Reduces shell actions, shows ice particle\n• Decay Stacks: Halves score at end round\n• Rust Stacks: Affects multiplier calculations\n• Cursed Stacks: -50% base score, +10% penalty per stack\n• Disable Stacks: Prevents certain shell abilities\n\nScore Calculation:\n• Base score modified by shell type\n• Multiplier stacks applied (except rust-affected shells)\n• Curse reduction applied (except types 7 & 11)\n• Final TotalScore displayed on shell",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Turn Phases & Activation Order",
			"description": "Understanding Game Timing\n\nShell Activation Phases:\n1. Shell Drop: When shell lands in a pit\n2. End Round: After all moves complete\n3. Status Updates: Stack effects applied\n\nEffect Timing:\n• Drop Effects: Immediate when shell lands\n• End Round Effects: After movement phase\n• Stack Decay: Automatic each end round\n• Score Updates: Continuous via timer\n\nArea of Effect:\n• Shells use ShellRange area to detect nearby shells\n• Effects apply to overlapping shells only\n• Different shells have different effect ranges\n• Chain reactions can cascade through multiple shells",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Special Shell Selection Interface",
			"description": "How to Place Special Shells\n\nSelection Process:\n1. After your turn, the selector appears\n2. Choose shell type (1-12) or click 'Skip'\n3. Click on any pit to place the shell\n4. Special shell is added to that pit's contents\n\nStrategic Considerations:\n• Consider pit location and contents\n• Think about activation timing\n• Plan for opponent reactions\n• Balance offense and defense",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Advanced Strategies & Tips",
			"description": "Master Level Play\n\nKey Strategies:\n• Shell Counting: Calculate exact landing positions\n• Chain Planning: Set up multiple extra turns\n• Trap Setting: Use special shells to create traps\n• Resource Control: Manage shell distribution\n• Timing Mastery: Coordinate special effects\n\nPro Tips:\n• Always think 2-3 moves ahead\n• Watch for opponent weaknesses\n• Balance aggression with defense\n• Control the pace of the endgame",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		}
	]

func create_scrollable_tutorial():
	# Clear any existing children
	for child in get_children():
		child.queue_free()
	
	# Clear video players array
	video_players.clear()
	
	# Wait for children to be cleared
	await get_tree().process_frame
	
	# Set up the main control to fill the screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.05, 0.1, 1.0)
	add_child(background)
	
	# Create header with title and navigation
	create_header()
	
	# Create scrollable content area
	scroll_container = ScrollContainer.new()
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.offset_top = 100
	scroll_container.offset_bottom = -100
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll_container)
	
	# Create content container
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 20)
	scroll_container.add_child(content_container)
	
	# Add tutorial steps
	for i in range(tutorial_steps.size()):
		create_tutorial_step(tutorial_steps[i], i)
		
		# Add some space between steps
		if i < tutorial_steps.size() - 1:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 40)
			content_container.add_child(spacer)
	
	# Create footer with action buttons
	create_footer()

func create_header():
	var header = Panel.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 100)
	header.size.y = 100
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	header.add_theme_stylebox_override("panel", style_box)
	add_child(header)
	
	# Tutorial title
	var title = Label.new()
	title.text = "SHELL MASTERS - COMPLETE TUTORIAL"
	title.position = Vector2(50, 25)
	title.add_theme_font_size_override("font_size", scaled_font_size(32))
	title.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(title)
	
	# Back to menu button
	back_to_menu_button = Button.new()
	back_to_menu_button.text = "← BACK TO MENU"
	back_to_menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back_to_menu_button.position.x -= 200
	back_to_menu_button.position.y = 25
	back_to_menu_button.size = Vector2(150, 50)
	back_to_menu_button.add_theme_font_size_override("font_size", scaled_font_size(16))
	back_to_menu_button.pressed.connect(_on_back_to_menu)
	header.add_child(back_to_menu_button)

func create_tutorial_step(step: Dictionary, step_index: int):
	# Main step container
	var step_container = Panel.new()
	step_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_container.custom_minimum_size = Vector2(0, 600)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.15, 0.9)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	step_container.add_theme_stylebox_override("panel", style_box)
	content_container.add_child(step_container)
	
	# Main vertical layout for the step
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 20
	main_vbox.offset_right = -20
	main_vbox.offset_top = 20
	main_vbox.offset_bottom = -20
	main_vbox.add_theme_constant_override("separation", 20)
	step_container.add_child(main_vbox)
	
	# Step number and title
	var title_container = HBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(title_container)
	
	var step_number = Label.new()
	step_number.text = "STEP " + str(step_index + 1)
	step_number.add_theme_font_size_override("font_size", scaled_font_size(20))
	step_number.add_theme_color_override("font_color", Color.ORANGE)
	step_number.custom_minimum_size = Vector2(120, 0)
	title_container.add_child(step_number)
	
	var title_label = Label.new()
	title_label.text = step.title
	title_label.add_theme_font_size_override("font_size", scaled_font_size(28))
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.add_child(title_label)
	
	# Content area with video and description side by side
	var content_area = HBoxContainer.new()
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 40)
	main_vbox.add_child(content_area)
	
	# Create actual video player (left side)
	var video_container = Panel.new()
	video_container.custom_minimum_size = Vector2(600, 400)
	var video_style = StyleBoxFlat.new()
	video_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	video_style.corner_radius_top_left = 8
	video_style.corner_radius_top_right = 8
	video_style.corner_radius_bottom_left = 8
	video_style.corner_radius_bottom_right = 8
	video_container.add_theme_stylebox_override("panel", video_style)
	content_area.add_child(video_container)
	
	# Create video player
	var video_player = VideoStreamPlayer.new()
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.offset_left = 10
	video_player.offset_right = -10
	video_player.offset_top = 10
	video_player.offset_bottom = -10  # No space needed for controls now
	
	# Configure video player for looping without sound
	video_player.autoplay = false  # We'll start manually after adding to tree
	video_player.loop = true
	video_player.volume_db = -80  # Effectively mute the video
	
	# Try to load the video stream
	if FileAccess.file_exists(step.video_path):
		var video_stream = load(step.video_path)
		if video_stream:
			video_player.stream = video_stream
		else:
			print("Failed to load video: ", step.video_path)
	else:
		print("Video file not found: ", step.video_path)
	
	video_container.add_child(video_player)
	video_players.append(video_player)
	
	# Start playing after the video player is in the scene tree
	if video_player.stream:
		# Use call_deferred to ensure the node is fully ready
		video_player.call_deferred("play")
	
	# Add simple status overlay if video not found
	if not FileAccess.file_exists(step.video_path):
		var status_label = Label.new()
		status_label.text = "Video Not Found:\n" + step.video_path
		status_label.add_theme_color_override("font_color", Color.RED)
		status_label.add_theme_font_size_override("font_size", scaled_font_size(14))
		status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		video_container.add_child(status_label)
	
	# Description (right side)
	var description_container = Panel.new()
	description_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color(0.15, 0.15, 0.25, 0.8)
	desc_style.corner_radius_top_left = 8
	desc_style.corner_radius_top_right = 8
	desc_style.corner_radius_bottom_left = 8
	desc_style.corner_radius_bottom_right = 8
	description_container.add_theme_stylebox_override("panel", desc_style)
	content_area.add_child(description_container)
	
	var description_scroll = ScrollContainer.new()
	description_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	description_scroll.offset_left = 20
	description_scroll.offset_right = -20
	description_scroll.offset_top = 20
	description_scroll.offset_bottom = -20
	description_container.add_child(description_scroll)
	
	# Use regular Label instead of RichTextLabel to avoid BBCode issues
	var description_label = Label.new()
	description_label.text = step.description
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description_label.add_theme_font_size_override("font_size", scaled_font_size(16))
	description_label.add_theme_color_override("font_color", Color.WHITE)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description_scroll.add_child(description_label)

func create_footer():
	var footer = Panel.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.custom_minimum_size = Vector2(0, 100)
	footer.size.y = 100
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	footer.add_theme_stylebox_override("panel", style_box)
	add_child(footer)
	
	# Start game button
	start_game_button = Button.new()
	start_game_button.text = "START GAME →"
	start_game_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	start_game_button.position.x -= 200
	start_game_button.position.y = 25
	start_game_button.size = Vector2(150, 50)
	start_game_button.add_theme_font_size_override("font_size", scaled_font_size(18))
	start_game_button.add_theme_color_override("font_color", Color.LIME)
	start_game_button.pressed.connect(_on_start_game)
	footer.add_child(start_game_button)
	
	# Tutorial completion indicator
	var completion_label = Label.new()
	completion_label.text = "Scroll through all sections to master Shell Masters!"
	completion_label.position = Vector2(50, 35)
	completion_label.add_theme_font_size_override("font_size", scaled_font_size(16))
	completion_label.add_theme_color_override("font_color", Color.WHITE)
	footer.add_child(completion_label)

func _on_back_to_menu():
	# Stop all videos before leaving
	for video_player in video_players:
		if video_player and is_instance_valid(video_player):
			video_player.stop()
	
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://Main Menu/main_menu.tscn")

func _on_start_game():
	# Stop all videos before leaving
	for video_player in video_players:
		if video_player and is_instance_valid(video_player):
			video_player.stop()
	
	print("Starting Shell Masters game...")
	get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")

# Optional: Add smooth scrolling to specific sections
func scroll_to_step(step_index: int):
	if step_index >= 0 and step_index < tutorial_steps.size() and scroll_container:
		var step_position = step_index * 640  # Approximate height per step
		scroll_container.scroll_vertical = step_position

# Optional: Track scroll progress
func _on_scroll_changed():
	if scroll_container and scroll_container.get_v_scroll_bar():
		var scroll_progress = float(scroll_container.scroll_vertical) / float(scroll_container.get_v_scroll_bar().max_value)
		print("Tutorial scroll progress: ", scroll_progress * 100, "%")
