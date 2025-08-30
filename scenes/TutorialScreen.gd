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
			"title": "What is Tangka?",
			"description": "Welcome to Tangka!\n\nTangka is based on traditional Filipino board games called Sungka. These are ancient mancala-style games where players distribute shells or seeds around a board with strategic objectives.\n\nThe digital version adds fantasy elements with:\n• Special shells with unique abilities\n• Magical pit types with special effects\n• Enhanced scoring systems\n• Strategic shell placement mechanics\n\nWhile maintaining the core strategic gameplay of traditional mancala.",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Game Objective & Victory",
			"description": "How to Win Shell Masters\n\nVictory Condition:\n• First player to reach 100 SCORE wins!\n• Score = Shell Amount × Total Shell Points in your Main House\n• This creates a race-to-target gameplay\n\nKey Strategies:\n• Collect shells in your Main House (safe storage)\n• Enhance shell point values through special abilities\n• Balance quantity collection with quality enhancement\n• Use special shells and pit effects strategically\n• Control the board to deny opponent opportunities",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Board Layout & Components",
			"description": "Understanding the Shell Masters Board\n\nBoard Structure:\n• 14 Pits arranged in two rows of 7\n• Pits 1-7 belong to Player 1 (bottom row)\n• Pits 8-14 belong to Player 2 (top row)\n• 2 Main Houses (Store Houses) at the ends\n\nMain Houses:\n• Primary collection areas for shells\n• Shells here are safe from capture\n• Contribute to final score calculation\n• Located at the ends of each player's pit row\n\nPit Types:\n• Each pit has a PitType (1-11) with special effects\n• Pits start as Basic type but can be enhanced\n• Different pit types activate at end of rounds",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Shell Distribution Mechanics",
			"description": "Core Gameplay: Moving Shells Around the Board\n\nDistribution Rules:\n• Select a pit on YOUR side containing at least one shell\n• Pick up ALL shells from that pit\n• Distribute them ONE BY ONE to subsequent pits\n• Move COUNTER-CLOCKWISE around the board\n• Include your own Main House in the path\n• Skip opponent's Main House completely\n\nMovement Pattern:\n• Continue around the board if you have more shells\n• Follow the traditional mancala movement rules\n• Strategic counting is crucial for planning moves\n• Consider where your last shell will land",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Extra Turns & Bonus Actions",
			"description": "Get Additional Turns for Strategic Advantage\n\nExtra Turn Trigger:\n• When your LAST shell lands exactly in YOUR Main House\n• You immediately get another turn\n• Can chain multiple extra turns together\n• No special shell selection after extra turns\n\nStrategic Benefits:\n• Extra turns provide huge advantages\n• Plan shell counts to land in your Main House\n• Use extra turns to set up combinations\n• Control game tempo with bonus actions\n• Essential for advanced play strategies\n\nTip: Count shells carefully to maximize extra turn opportunities!",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Shell Types & Abilities Overview",
			"description": "12 Unique Special Shell Types with Magical Abilities\n\nShell Mechanics:\n• Shells have Type (1-12), Points (1-5 base), and Status Effects\n• Basic shells start as Type 1 with 1 point\n• Enhanced through gameplay and Card Selector\n• Each type has unique Drop and End Round effects\n\nShell Categories:\n• Foundation Shells (Types 1-2): Basic building blocks\n• Multiplication Shells (Types 3-4): Duplication and enhancement\n• Generation Shells (Types 5-6): Spawning and support\n• Utility Shells (Types 7-8): Luck and transformation\n• Combat Shells (Types 9-10): Damage and chain reactions\n• Control Shells (Types 11-12): Cleansing and freezing\n\nActivation Order: Basic → Golden → Echo → Anchor → Spirit → Time → Lucky → Mirror → Flame → Chain → Purify → Ice",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Basic & Golden Shells (Types 1-2)",
			"description": "Foundation Shells - Your Core Building Blocks\n\nBasic Shell (Type 1):\n• Base Points: 1\n• Drop Effect: Gains +1 points\n• End Round in Main House: Gains +1 points\n• End Round in Pits: Resets to 1 points if not already 1\n• Reliable foundation for shell distribution\n• Safe choice for movement planning\n\nGolden Shell (Type 2):\n• Base Points: 1\n• Drop Effect: Gains +1 points (pits) or +5 points (Main House)\n• End Round: Always gains +1 points regardless of location\n• High-value shell for consistent scoring\n• Excellent for long-term point accumulation\n• Strategic placement in Main House gives massive drop bonus",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Echo & Anchor Shells (Types 3-4)",
			"description": "Multiplication Shells - Duplication and Enhancement\n\nEcho Shell (Type 3):\n• Base Points: 1\n• Drop Effect: Duplicates 1 nearby shell\n• End Round: Creates a duplicate copy of itself, resets points to 1\n• Rapidly multiply your shell count\n• Strategic for overwhelming opponents\n• Best placed in stable pit positions\n\nAnchor Shell (Type 4):\n• Base Points: 1\n• Drop Effect: Grants +1 multiplier to nearby shells (pits), +1 to self\n• End Round: Gains +1 multiplier stack if in pit\n• Multiplier stacks increase points by 50% each (x1.5, x2, x2.5...)\n• Powerful for exponential score growth\n• Synergizes well with high-point shells",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Spirit & Time Shells (Types 5-6)",
			"description": "Generation Shells - Spawning and Support\n\nSpirit Shell (Type 5):\n• Base Points: 1\n• Drop Effect: Gains +1 points and spawns random shell (Type 1-12)\n• Start Round: Spawns random shell if in Main House\n• Creates unpredictable advantages\n• Excellent for resource generation\n• Can spawn powerful high-tier shells\n\nTime Shell (Type 6):\n• Base Points: 1\n• Drop Effect: Grants +1 points to all nearby shells\n• End Round in Pits: Grants +1 points to nearby shells\n• End Round in Main House: Gains +(1×Rounds) points bonus\n• Outstanding support shell for team enhancement\n• Scales with game length when in Main House",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Lucky & Mirror Shells (Types 7-8)",
			"description": "Utility Shells - Luck and Transformation\n\nLucky Shell (Type 7):\n• Base Points: 1\n• Drop Effect: Variable points (100%/60%/20%/-20%/-60%/-100% for 1/2/3/4/5/6 points)\n• End Round: Gains +1 luck effect, grants luck to nearby shells\n• Luck stacks improve probability of positive effects\n• High risk, high reward gameplay element\n• Synergizes with percentage-based pit effects\n\nMirror Shell (Type 8):\n• Base Points: 1\n• Drop Effect: Copies nearby shell type and transforms another shell\n• Start Round: Changes nearby shell to random type, or self if alone\n• Versatile adaptation and transformation tool\n• Can copy powerful shell types strategically\n• Useful for disrupting opponent formations",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Flame & Chain Shells (Types 9-10)",
			"description": "Combat Shells - Damage and Chain Reactions\n\nFlame Shell (Type 9):\n• Base Points: 1\n• Drop Effect: Gains +2 points\n• End Round: Burns nearby shells, gains +(1×burned shells) points\n• Offensive area-of-effect capabilities\n• Weakens opponent shell formations\n• Gains power from damaging others\n\nChain Shell (Type 10):\n• Base Points: 1\n• Drop Effect: Gains +1 points, activates 1 nearby shell ability, moves all nearby chain shells to next pit\n• End Round: No special effect\n• Complex chain reaction potential\n• Can trigger cascading combinations\n• Advanced combo setup tool\n• Mobile shell that can relocate strategically",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Purify & Ice Shells (Types 11-12)",
			"description": "Control Shells - Cleansing and Freezing\n\nPurify Shell (Type 11):\n• Base Points: 1\n• Drop Effect: Gains +3 points, removes effects from nearby shells\n• Passive: Immune to all negative effects\n• Essential counter to debuff strategies\n• High immediate point gain on drop\n• Cleanses burn, freeze, decay, curse, and disable\n• Ultimate defensive utility shell\n\nIce Shell (Type 12):\n• Base Points: 1\n• Drop Effect: Gains +2 points\n• End Round: Freezes nearby shells, gains +(1×frozen shells) points\n• Control shell that limits opponent options\n• Defensive area denial capabilities\n• Freeze prevents shell actions and movement\n• Strategic positioning can lock down areas",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Pit Types & Environmental Effects",
			"description": "11 Magical Pit Types with Special Powers\n\nPit Mechanics:\n• Each pit has a PitType (1-11) that grants special effects\n• Pit effects activate at End Round phase\n• Effects apply based on shell ownership and conditions\n• Strategic pit placement is crucial\n\nPit Types Overview:\n• Basic Pit (1): +1 points to owned shells\n• Anchor Pit (2): +1 multiplier to owned shells\n• Echo Pit (3): 10% chance (+2.5% per luck) to duplicate shells\n• Spirit Pit (4): 25% chance (+2.5% per luck) to spawn shells\n• Loot Pit (5): 25% chance to move shells to opponent's house\n• Chain Pit (6): 25% chance to trigger chain effects\n• Golden Pit (7): Multiple +1 point bonuses based on luck\n• Healing Pit (8): Removes negative status effects\n• Void Pit (9): Immediately removes shells from game\n• Explosive Pit (10): Burns and randomly moves shells\n• Random Pit (11): Randomly changes shell types",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Status Effects & Stack System",
			"description": "Advanced Shell Modification System\n\nStatus Effect Types:\n• Multiplier Stacks: +50% points per stack (x1.5, x2, x2.5...)\n• Luck Stacks: Increase probability of positive random effects\n• Burn Stacks: -1 points each round, stack decreases by 1\n• Freeze Stacks: Prevents shell movement for stack count rounds\n• Decay Stacks: Halves points at end round\n• Rust Stacks: Affects multiplier calculations negatively\n• Cursed Stacks: -50% base score, additional penalties\n• Disable Stacks: Prevents certain shell abilities\n\nScore Calculation Priority:\n1. Base shell points by type\n2. Multiplier stacks applied (except rust-affected)\n3. Curse reduction applied (Types 7 & 11 immune)\n4. Final TotalScore displayed on shell\n\nStack Management:\n• Most stacks decay naturally over time\n• Some effects are permanent until cleansed\n• Strategic timing of effects is crucial",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Card Selector System",
			"description": "Strategic Shell & Pit Enhancement\n\nSelection Process:\n1. After each normal turn (not extra turns)\n2. Choose from randomly generated special options\n3. Select shell types (1-12) or pit types (1-11)\n4. Place enhancement on any pit of your choice\n5. Can skip selection if no good options\n\nStrategic Considerations:\n• Consider current board state and shell positions\n• Plan for activation timing and synergies\n• Balance offensive and defensive enhancements\n• Think about opponent's potential reactions\n• Control key board positions with strategic placement\n\nTiming is Everything:\n• Effects activate at different phases\n• Plan combinations for maximum impact\n• Consider shell movement patterns\n• Anticipate opponent responses",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Game Phases & Activation Order",
			"description": "Understanding Turn Structure and Timing\n\nTurn Sequence:\n1. Player selects pit and distributes shells\n2. Shell Drop effects activate as shells land\n3. End Round phase begins\n4. Status effects and pit effects activate\n5. Card Selector appears (if not extra turn)\n6. Turn passes to opponent\n\nActivation Priorities:\n• Shell Drop Effects: Immediate when shell lands\n• Shell End Round Effects: Type 1 → 2 → 3... → 12\n• Pit End Round Effects: After shell effects\n• Status Stack Updates: Automatic decay/application\n• Score Calculations: Continuous updates\n\nArea of Effect Rules:\n• Effects use ShellRange to detect nearby shells\n• Only overlapping shells are affected\n• Chain reactions can cascade through multiple shells\n• Range varies by shell type and effect",
			"video_path": "res://tutorial/clips/a_m_o_g_u_s.ogv"
		},
		{
			"title": "Advanced Strategies & Master Tips",
			"description": "Elevate Your Shell Masters Gameplay\n\nCore Strategies:\n• Shell Counting: Calculate exact landing positions for precision\n• Extra Turn Chains: Set up multiple consecutive bonus turns\n• Combination Planning: Coordinate shell effects for maximum impact\n• Board Control: Dominate key positions with strategic placements\n• Resource Management: Balance shell quantity with quality enhancement\n\nMaster Level Techniques:\n• Tempo Control: Manage the pace and rhythm of the game\n• Defensive Positioning: Protect valuable shells and formations\n• Offensive Pressure: Create multiple threatening scenarios\n• Effect Timing: Coordinate activation phases for optimal results\n• Adaptation: Read opponent strategies and counter effectively\n\nPro Tips:\n• Always think 2-3 moves ahead\n• Watch for opponent weaknesses and capitalize\n• Balance aggression with sustainable defense\n• Master the endgame scoring calculations\n• Practice shell type combinations and synergies",
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
	completion_label.text = "Master the ancient art of Shell Masters - Strategic Mancala!"
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
