extends Node2D

var shells: int = 0
var scores: int = 0
var HouseType: int = 0  # NEW: House type variable
var HouseSprite: Sprite2D  # NEW: Reference to house sprite
var use_timer_counting: bool = true  # Flag to control counting method
var use_visual_spawning: bool = false  # NEW: Flag to control visual shell spawning

@onready var timer := $Timer  # Access the Timer node
@onready var label = $StoneLabel
# FIXED: Remove the problematic line and handle sprite reference more safely
@onready var audio_player := $AudioStreamPlayer2D
const SOUND_SHELL_ENTER_HOUSE = preload("res://assets/Sound/Pit sound/Retro - Chip Power.wav")

func _ready():
	add_to_group("main_houses")
	
	# FIXED: Safely get the house sprite reference
	setup_house_sprite()
	
	# NEW: Initialize house type and update sprite
	HouseType = randi_range(1, 11)  # Random house type between 1-11 (adjust range as needed)
	update_house_frame()
	
	setup_click_area()  # NEW: Setup click area for tooltip
	setup_shell_area_signals()  # NEW: Setup shell area signals
	
	# Only connect timer if we're using timer-based counting
	if use_timer_counting:
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		timer.start()
	update_label()

# FIXED: New function to safely setup house sprite reference
func setup_house_sprite():
	# Try different possible node names for the sprite
	var possible_names = ["HouseSprite", "Sprite2D", "Sprite", "House_Sprite"]
	
	for sprite_name in possible_names:
		var sprite_node = get_node_or_null(sprite_name)
		if sprite_node and sprite_node is Sprite2D:
			HouseSprite = sprite_node
			print("Found house sprite: ", sprite_name)
			return
	
	# If no sprite found, create a warning
	print("Warning: No house sprite found. Checked names: ", possible_names)
	print("Available child nodes:")
	for child in get_children():
		print("  - ", child.name, " (", child.get_class(), ")")

# NEW: Setup shell area signals
func setup_shell_area_signals():
	var shell_area = get_node_or_null("ShellArea")
	if shell_area:
		print("ShellArea found: ", shell_area.name)
		print("ShellArea type: ", shell_area.get_class())
		
		# Connect signals if not already connected
		if not shell_area.is_connected("body_entered", _on_shell_area_body_entered):
			shell_area.connect("body_entered", _on_shell_area_body_entered)
			print("Connected body_entered signal")
		else:
			print("body_entered signal already connected")
			
		if not shell_area.is_connected("body_exited", _on_shell_area_body_exited):
			shell_area.connect("body_exited", _on_shell_area_body_exited)
			print("Connected body_exited signal")
		else:
			print("body_exited signal already connected")
		
		# Check if ShellArea has a CollisionShape2D
		var collision_shape = shell_area.get_node_or_null("CollisionShape2D")
		if collision_shape:
			print("CollisionShape2D found in ShellArea")
			print("Shape resource: ", collision_shape.shape)
		else:
			print("WARNING: No CollisionShape2D found in ShellArea!")
			
		# List all monitoring settings
		print("ShellArea monitoring: ", shell_area.monitoring)
		print("ShellArea monitorable: ", shell_area.monitorable)
		
	else:
		print("WARNING: ShellArea node not found!")
		print("Available child nodes in MainHouse:")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")

func play_shell_enter_sound():
	print("play_shell_enter_sound() called")
	print("audio_player exists:", audio_player != null)
	if audio_player:
		print("Audio player found, attempting to play sound")
		print("Sound file path:", SOUND_SHELL_ENTER_HOUSE.resource_path if SOUND_SHELL_ENTER_HOUSE else "NULL")
		audio_player.stream = SOUND_SHELL_ENTER_HOUSE
		audio_player.play()
		print("Playing shell enter main house sound")
		print("Audio player playing:", audio_player.playing)
		print("Audio player volume:", audio_player.volume_db)
	else:
		print("ERROR: audio_player is null!")

# NEW: Setup click area for tooltip functionality
func setup_click_area():
	var click_area = get_node_or_null("ClickArea")
	if click_area and click_area.has_method("setup"):
		var main_houses = get_tree().get_nodes_in_group("main_houses")
		var house_index = main_houses.find(self)
		if house_index >= 0:
			click_area.setup(self, house_index)
			print("Setup click area with hover for MainHouse ", house_index)
	else:
		print("Warning: No ClickArea found in MainHouse ", name)

# NEW: Set house type function
func set_house_type(new_type: int) -> void:
	# Ensure the type is within valid range (1-11 for house types)
	if new_type >= 1 and new_type <= 11:
		HouseType = new_type
		update_house_frame()
		print("House type set to: ", HouseType)
	else:
		print("Invalid house type:", new_type)

# FIXED: Update house sprite frame based on type
func update_house_frame() -> void:
	# Safety check: Make sure HouseSprite exists before trying to use it
	if not HouseSprite:
		print("Warning: HouseSprite is null, cannot update frame")
		return
	
	# Ensure the sprite has a texture with frames
	if not HouseSprite.texture:
		print("Warning: HouseSprite has no texture assigned")
		return
	
	# Ensure frame index is within bounds (0-10 for 11 frames)
	var frame_index = HouseType - 1 if HouseType >= 1 else 0
	frame_index = clamp(frame_index, 0, 10)
	
	# Additional safety check for frame bounds
	if HouseSprite.texture.has_method("get_width"):
		# This is likely a texture with frames
		HouseSprite.frame = frame_index
		print("House frame updated to: ", frame_index, " (Type: ", HouseType, ")")
	else:
		print("Warning: Texture doesn't support frames")

func set_shells(amount: int):
	var oldshell = shells
	shells = amount
	# Only spawn visual shells if we're in visual spawning mode
	if use_visual_spawning:
		spawn_shells(oldshell, shells)
	update_label()  # Update label immediately
	
func add_shells(amount: int):
	# This is called by GameManager - disable timer counting to avoid double counting
	use_timer_counting = false
	if timer.is_connected("timeout", _on_timer_timeout):
		timer.disconnect("timeout", _on_timer_timeout)
	timer.stop()
	
	var oldshell = shells
	shells += amount
	
	# CRITICAL FIX: Don't spawn visual shells when physical shells are being used
	# The physical shells already exist and moved here, we just need to update the counter
	print("MainHouse: Added ", amount, " shells. Total: ", shells, " (no visual spawning)")
	
	# NEW: Trigger house effect when shells are added
	house_shells_added(amount)
	
	update_label()

# Take all shells (used at end of game to collect remaining pits)
func take_all_shells() -> int:
	var temp = shells
	shells = 0
	scores = 0  # Also reset scores when taking all shells
	update_label()
	return temp

# Take all scores (useful for game end calculations)
func take_all_scores() -> int:
	var temp = scores
	scores = 0
	update_label()
	return temp

func spawn_shells(old_shells: int, new_shells: int):
	# Only spawn visual shells if explicitly enabled
	if not use_visual_spawning:
		print("Visual spawning disabled - skipping shell spawn")
		return
		
	var gamemode: String = ""
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var main_houses = get_tree().get_nodes_in_group("main_houses")
	var house_index = main_houses.find(self)
	
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		gamemode = ""
		
	if house_index != -1 and gamemode == "Campaign":
		var house_node = main_houses[house_index]
		var housex = house_node.position.x
		var housey = house_node.position.y
		campaign.set_shells(old_shells, housex, housey)
		print("MainHouse found in group")
	elif house_index != -1 and gamemode == "Pvp":
		var house_node = main_houses[house_index]
		var housex = house_node.position.x
		var housey = house_node.position.y
		pvp.set_shells(old_shells, new_shells, housex, housey)
		print("MainHouse found in group")
	else:
		print("MainHouse not found in group")
		return 0

# NEW: Function to enable visual spawning mode (for initialization only)
func enable_visual_spawning():
	use_visual_spawning = true
	print("Visual spawning enabled for MainHouse")

# NEW: Function to disable visual spawning mode (for gameplay)
func disable_visual_spawning():
	use_visual_spawning = false
	print("Visual spawning disabled for MainHouse")

# NEW: House effect functions (similar to pit effects)
func house_round_start():
	"""Called at the start of each round"""
	match HouseType:
		1:
			house_effect_basic_start()
		2:
			house_effect_fortress_start()
		3:
			house_effect_mystic_start()
		4:
			house_effect_merchant_start()
		5:
			house_effect_warrior_start()
		# Add more house types as needed

func house_round_end():
	"""Called at the end of each round"""
	match HouseType:
		6:
			house_effect_harvest_end()
		7:
			house_effect_blessed_end()
		8:
			house_effect_cursed_end()
		9:
			house_effect_void_end()
		10:
			house_effect_golden_end()
		11:
			house_effect_random_end()

func house_shells_added(amount: int):
	"""Called when shells are added to the house"""
	match HouseType:
		1:
			house_effect_basic_added(amount)
		2:
			house_effect_fortress_added(amount)
		3:
			house_effect_mystic_added(amount)
		# Add more as needed

# NEW: Individual house effect implementations
func house_effect_basic_start():
	effect_text("Basic House Ready", Color(0.8, 0.8, 0.8, 0.0))

func house_effect_fortress_start():
	# Fortress house: Provides protection
	effect_text("Fortress Shield", Color(0.0, 0.5, 1.0, 0.0))

func house_effect_mystic_start():
	# Mystic house: Magical effects
	effect_text("Mystic Aura", Color(0.5, 0.0, 1.0, 0.0))

func house_effect_merchant_start():
	# Merchant house: Economic benefits
	effect_text("Trade Bonus", Color(1.0, 0.84, 0.0, 0.0))

func house_effect_warrior_start():
	# Warrior house: Combat benefits
	effect_text("Battle Ready", Color(1.0, 0.0, 0.0, 0.0))

func house_effect_harvest_end():
	# Harvest house: Bonus shells at round end
	var bonus_shells = min(shells / 10, 3)  # 10% of shells, max 3
	if bonus_shells > 0:
		shells += bonus_shells
		effect_text("Harvest +" + str(bonus_shells), Color(0.0, 0.8, 0.0, 0.0))
		update_label()

func house_effect_blessed_end():
	# Blessed house: Score multiplier
	var bonus_score = shells / 5  # 20% of shells as bonus score
	if bonus_score > 0:
		scores += bonus_score
		effect_text("Blessed +" + str(bonus_score), Color(1.0, 1.0, 0.0, 0.0))
		update_label()

func house_effect_cursed_end():
	# Cursed house: Risk/reward mechanic
	var roll = randf() * 100.0
	if roll <= 30.0:  # 30% chance to lose shells
		var lost_shells = shells / 4  # Lose 25% of shells
		shells = max(0, shells - lost_shells)
		effect_text("Cursed -" + str(lost_shells), Color(0.5, 0.0, 0.5, 0.0))
	else:  # 70% chance to gain bonus score
		var bonus_score = shells / 3
		scores += bonus_score
		effect_text("Dark Blessing +" + str(bonus_score), Color(0.8, 0.0, 0.8, 0.0))
	update_label()

func house_effect_void_end():
	# Void house: Removes some shells but grants big score bonus
	if shells >= 5:
		var consumed_shells = min(shells / 3, 5)  # Consume up to 5 shells
		shells -= consumed_shells
		scores += consumed_shells * 3  # 3x score for consumed shells
		effect_text("Void Consume +" + str(consumed_shells * 3), Color(0.0, 0.0, 0.0, 0.0))
		update_label()

func house_effect_golden_end():
	# Golden house: Score multiplier based on shell count
	if shells >= 10:
		var multiplier = 2
		scores *= multiplier
		effect_text("Golden x" + str(multiplier), Color(1.0, 0.84, 0.0, 0.0))
		update_label()

func house_effect_random_end():
	# Random house: Apply random effect
	var random_effect = randi_range(1, 5)
	match random_effect:
		1:
			house_effect_harvest_end()
		2:
			house_effect_blessed_end()
		3:
			house_effect_cursed_end()
		4:
			house_effect_void_end()
		5:
			house_effect_golden_end()

func house_effect_basic_added(amount: int):
	# Basic house: Small score bonus when shells added
	scores += amount
	effect_text("Basic +" + str(amount), Color(0.8, 0.8, 0.8, 0.0))

func house_effect_fortress_added(amount: int):
	# Fortress house: Defensive bonus
	if amount >= 3:
		var bonus = amount / 3
		scores += bonus
		effect_text("Fortress +" + str(bonus), Color(0.0, 0.5, 1.0, 0.0))

func house_effect_mystic_added(amount: int):
	# Mystic house: Magical conversion
	var roll = randf() * 100.0
	if roll <= 25.0:  # 25% chance
		var bonus = amount * 2
		scores += bonus
		effect_text("Mystic +" + str(bonus), Color(0.5, 0.0, 1.0, 0.0))

# NEW: Effect text display function (similar to pit's effect_text)
func effect_text(text: String, text_color: Color):
	# Create a temporary label for the effect if one doesn't exist
	var effect_label = get_node_or_null("EffectLabel")
	if not effect_label:
		effect_label = Label.new()
		effect_label.name = "EffectLabel"
		add_child(effect_label)
		effect_label.position = Vector2(0, -50)  # Position above the house
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	effect_label.text = text
	effect_label.modulate = text_color
	effect_label.modulate.a = 0.0  # Start transparent
	effect_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(effect_label, "modulate:a", 1.0, 0.2)  # Fade in
	tween.tween_interval(2.0)  # Wait for 2 seconds
	tween.tween_property(effect_label, "modulate:a", 0.0, 0.6)  # Fade out
	tween.tween_callback(func(): effect_label.visible = false)  # Hide

func _on_timer_timeout():
	# Only count if timer counting is enabled
	if not use_timer_counting:
		return
		
	# No need to check timer.value — the timeout already means 1 second passed
	var new_shell_count = count_shells_in_area()
	if new_shell_count != shells:
		shells = new_shell_count
		update_label()
	# Restart the timer to loop
	timer.start()

func count_shells_in_area() -> int:
	var cshells: int = 0
	var cscores: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	
	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					print("Shell overlapping in Campaign:", child.name)
					cshells += 1
					cscores += child.TotalScore
		# Update scores before returning
		scores = cscores
		return cshells
		
	elif gamemode == "Pvp":
		for child in pvp.get_children():
			# CRITICAL FIX: Only count shells that are NOT currently moving
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					cshells += 1
					var cscore: int = child.get_score()
					cscores += cscore
		# Update scores before returning
		scores = cscores
		return cshells
	else:
		# Reset scores if no valid gamemode
		scores = 0
		return 0

func _on_shell_area_body_entered(body: Node2D) -> void:
	print("Body entered MainHouse area:", body.name, " | Type:", body.get_class())
	print("use_timer_counting:", use_timer_counting)
	print("Is RigidBody2D:", body is RigidBody2D)
	
	# Check if it's a shell (regardless of timer counting mode)
	if body.is_in_group("Shells") or body is RigidBody2D:
		print("Shell detected entering MainHouse!")
		play_shell_enter_sound()
		
		# Only do timer-based updates if timer counting is enabled
		if use_timer_counting:
			print("Timer counting enabled - updating with delay")
			# Small delay to let physics settle
			await get_tree().create_timer(0.1).timeout
			update_label()
		else:
			print("Timer counting disabled - immediate update")
			update_label()

func _on_shell_area_body_exited(body: Node2D) -> void:
	print("Body exited MainHouse area:", body.name, " | Type:", body.get_class())
	
	# Check if it's a shell (regardless of timer counting mode)
	if body.is_in_group("Shells") or body is RigidBody2D:
		print("Shell detected exiting MainHouse!")
		
		# Only do timer-based updates if timer counting is enabled
		if use_timer_counting:
			print("Timer counting enabled - updating with delay")
			# Small delay to let physics settle
			await get_tree().create_timer(0.1).timeout
			update_label()
		else:
			print("Timer counting disabled - immediate update")
			update_label()
		
func update_label():
	var shell_count = shells
	var totalscores = scores
	if label:
		# NEW: Include house type in the label display
		label.text = "House " + str(HouseType) + " | Shells: " + str(shell_count) + " | Score: " + str(totalscores)
	else:
		print("Warning: StoneLabel not found in MainHouse")
