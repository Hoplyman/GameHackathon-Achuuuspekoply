extends Node2D

var shells: int = 0
var PitType: int = 0
var PitSprite: Sprite2D # the sprite of Shell
var use_timer_counting: bool = true
var initialization_complete: bool = false

@onready var Pit_Sprite := $PitSprite
@onready var timer := $Timer
@onready var labelshell = $ShellLabel
@onready var labeleffect := $Effect
func _ready():
	setup_click_area()
	PitType = randi_range(5,5)
	update_pit_frame()
	add_to_group("pits")
	# CRITICAL FIX: Stop timer immediately and disable timer counting from the start
	use_timer_counting = false
	timer.stop()
	# Don't connect timer signal until explicitly enabled
	update_label()

func setup_click_area():
	var click_area = get_node_or_null("ClickArea")
	if click_area and click_area.has_method("setup"):
		var pits = get_tree().get_nodes_in_group("pits")
		var pit_index = pits.find(self)
		if pit_index >= 0:
			click_area.setup(self, pit_index)
			print("Setup click area with hover for pit ", pit_index)
	else:
		print("Warning: No ClickArea found in ", name)

func set_shells(amount: int):
	# This is called by GameManager during initialization
	use_timer_counting = false
	initialization_complete = false  # Mark as initializing
	
	# CRITICAL FIX: Force stop timer and disconnect signal immediately
	timer.stop()
	if timer.timeout.is_connected(_on_timer_timeout):
		timer.disconnect("timeout", _on_timer_timeout)
	
	# Force an immediate update without counting to prevent the brief "14" display
	shells = amount  # Set directly without spawning
	update_label()  # Update display immediately
	
	# Now spawn the visual shells
	var oldshell = 0  # Always start from 0 during initialization
	spawn_shells(oldshell, shells)
	
	# Mark initialization as complete
	initialization_complete = true
	print("Pit initialized with ", amount, " shells")

func enable_timer_counting():
	"""Called by GameManager after all initialization is complete"""
	if initialization_complete and not use_timer_counting:
		use_timer_counting = true
		# Connect the timer signal if not already connected
		if not timer.timeout.is_connected(_on_timer_timeout):
			timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		
		# Do one immediate count to sync, then start the timer
		var current_count = count_shells_in_area()
		if current_count != shells:
			print("Timer sync: Pit ", name, " correcting from ", shells, " to ", current_count)
			shells = current_count
			update_label()
		
		timer.start()
		print("Timer counting enabled for ", name, " with ", shells, " shells")
	
func add_shells(amount):
	# This is called by GameManager during gameplay
	use_timer_counting = false
	if timer.is_connected("timeout", _on_timer_timeout):
		timer.disconnect("timeout", _on_timer_timeout)
	timer.stop()
	
	var oldshell = shells
	shells += amount
	spawn_shells(oldshell, shells)
	update_label()
	print("Pit: Added ", amount, " shells. Total: ", shells)
	
func move_shells(player: int):
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					print("Removing shell from Campaign:", child.name)
					child.queue_free()
		shells = 0
		update_label()
		return 0

	elif gamemode == "Pvp":
		var totalmove = 1
		var shells_to_remove = []
		
		for child in pvp.get_children():
			if child.is_in_group("Shells"):
				if child in overlapping_bodies:
					print("Shell overlapping in Pvp:", child.name)
					shells_to_remove.append(child)
		
		for child in shells_to_remove:
			child.remove_from_group("Shells")
			child.add_to_group("MoveShells")
			child.assign_move(totalmove, player)
			totalmove += 1
		
		print("Pit ", name, " - Started moving ", shells_to_remove.size(), " shells")
		return 0
	else:
		shells = 0
		update_label()
		return 0

func spawn_shells(old_count: int, new_count: int):
	var gamemode: String = ""
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var pits = get_tree().get_nodes_in_group("pits")
	var pit_index = pits.find(self)
	
	if campaign:
		print("Campaign found!")
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	if pit_index != -1 and gamemode == "Campaign":
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		campaign.set_shells(old_count, pitx, pity)
		print("Pit found in group")
	elif pit_index != -1 and gamemode == "Pvp":
		var pit_node = pits[pit_index]
		var pitx = pit_node.position.x
		var pity = pit_node.position.y
		
		# Clear existing shells during initialization only
		if old_count == 0 and new_count > 0 and not initialization_complete:
			clear_existing_shells_in_area()
		
		pvp.set_shells(old_count, new_count, pitx, pity)
		print("Pit found in group - updating from ", old_count, " to ", new_count, " shells at position (", pitx, ", ", pity, ")")
	else:
		print("Pit not found in group")
		return 0

func clear_existing_shells_in_area():
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		return
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()
	var shells_to_remove = []
	
	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells") and child in overlapping_bodies:
				shells_to_remove.append(child)
	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.is_in_group("Shells") and child in overlapping_bodies:
				shells_to_remove.append(child)
	
	for shell in shells_to_remove:
		shell.queue_free()
		print("Removed existing shell during initialization")

func _on_timer_timeout():
	# Only count if timer counting is enabled AND initialization is complete
	if not use_timer_counting or not initialization_complete:
		return
		
	var new_shell_count = count_shells_in_area()
	if new_shell_count != shells:
		shells = new_shell_count
		update_label()
	timer.start()

func count_shells_in_area() -> int:
	var cshells: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					cshells += 1
		return cshells

	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					cshells += 1
		return cshells
	else:
		return 0

func _on_shell_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("Shells"):
		print("Shell entered pit ", name, ": ", body.name)
		pit_drop()
		# FIXED: Always update shell count when a shell enters, regardless of timer mode
		await get_tree().create_timer(0.1).timeout  # Small delay for physics to settle
		
		if use_timer_counting:
			# Let timer handle the counting
			return
		else:
			# Manually count shells in area
			var new_count = count_shells_in_area()
			if new_count != shells:
				shells = new_count
				update_label()
				print("Updated pit ", name, " to ", shells, " shells")

func _on_shell_area_body_exited(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("Shells"):
		print("Shell exited pit ", name, ": ", body.name)
		
		# FIXED: Always update shell count when a shell exits
		await get_tree().create_timer(0.1).timeout  # Small delay for physics to settle
		
		if use_timer_counting:
			# Let timer handle the counting
			return
		else:
			# Manually count shells in area
			var new_count = count_shells_in_area()
			if new_count != shells:
				shells = new_count
				update_label()
				print("Updated pit ", name, " to ", shells, " shells")
		
func update_label():
	var shell_count = shells
	if labelshell:
		labelshell.text = str(shell_count)
	else:
		print("Warning: ShellLabel not found in Pit")
		
func effect_text(Text: String, TextColor: Color):
	labeleffect.text = Text
	labeleffect.modulate = TextColor  # Red but transparent
	labeleffect.visible = true
	var tween = create_tween()
	tween.tween_property(labeleffect, "modulate:a", 1.0, 0.2)  # Fade in
	tween.tween_interval(2.0)  # Wait for 2 seconds (correct function)
	tween.tween_property(labeleffect, "modulate:a", 0.0, 0.6)  # Fade out
	tween.tween_callback(func(): labeleffect.visible = false)  # Hide


func set_pit_type(new_type: int) -> void:
	# Fix: Ensure the type is within valid range (0-11 for 12 frames)
	if new_type >= 1 and new_type <= 11:
		PitType = new_type
		update_pit_frame()
		print("Shell type set to: ", PitType)
	else:
		print("Invalid shell type:", new_type)

func update_pit_frame() -> void:
	# Safety check: Make sure shellsprite exists before trying to use it
	if not PitSprite:
		await get_tree().process_frame  # Wait for shell to be ready
		if Pit_Sprite:
			PitSprite = Pit_Sprite
		else:
			print("Warning: shellsprite is still null")
			return
	
	# Fix: Ensure frame index is within bounds (0-11 for 12 frames)
	var frame_index = PitType - 1 if PitType >= 1 else 0
	frame_index = clamp(frame_index, 0, 10)
	
	PitSprite.frame = frame_index
	

func pit_startround():
	if PitType == 4:
		effect_shells_in_area("SPIRIT")
	elif PitType == 8:
		effect_shells_in_area("HEALING")
	elif PitType == 9:
		effect_shells_in_area("VOID")
		
func pit_endround():
	if PitType == 1:
		effect_shells_in_area("BASIC")
	elif PitType == 2:
		effect_shells_in_area("ANCHOR")
	elif PitType == 3:
		effect_shells_in_area("ECHO")
	elif PitType == 5:
		effect_shells_in_area("LOOT")
	elif PitType == 7:
		effect_shells_in_area("GOLDEN")
	elif PitType == 10:
		effect_shells_in_area("EXPLOSIVE")
	elif PitType == 11:
		effect_shells_in_area("RANDOM")
		
func pit_click():
	if PitType == 6:
		effect_shells_in_area("CHAIN")
		
func pit_drop():
	if PitType == 9:
		effect_shells_in_area("VOID")
		
func effect_shells_in_area(Effect: String):
	var Shell1: Node2D = null
	var Shell2: Node2D = null
	var Effect1Chance: float = 0.0
	var Effect2Chance: float = 0.0
	var TotalEffectChance: float = 0.0
	var count: int = 0
	var rng: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	var GameManager = pvp.get_node_or_null("GameManager")
	var current_turn: int = GameManager.current_turn
	var Player: int = 0
	if current_turn != 0:
		Player = current_turn
	else:
		Player = 0
	var pits = get_tree().get_nodes_in_group("pits")
	var pit_index = pits.find(self)
	Player += 1

	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellArea")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Campaign":
		for child in campaign.get_children():
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					pass

	elif gamemode == "Pvp":
		for child in pvp.get_children():
			if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
				if child in overlapping_bodies:
					if Effect == "BASIC":
						Shell1 = child
						child.Score += 1
					elif Effect == "ANCHOR":
						Shell1 = child
						child.MultiplierStacks += 1
					elif Effect == "ECHO":
						Shell1 = child
						Effect1Chance = 20.0
						Effect2Chance = 80.0
						Effect1Chance += 2.5 * child.LuckStacks
						Effect2Chance -= 2.5 * child.LuckStacks
						if Effect1Chance > 100.0:
							Effect1Chance = 100.0
							Effect2Chance = 0.0
						var roll = randf() * 100.0  # Random float from 0-100
						if roll <= Effect1Chance:	
							count += 1
							var Shell_Dup = child.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
							child.get_parent().add_child(Shell_Dup)
					elif Effect == "SPIRIT":
						Shell1 = child
						TotalEffectChance += 2.5 * child.LuckStacks
					elif Effect == "LOOT":
						Shell1 = child
						Effect1Chance = 25.0
						Effect2Chance = 75.0
						Effect1Chance += 2.5 * child.LuckStacks
						Effect2Chance -= 2.5 * child.LuckStacks
						if Effect1Chance > 100.0:
							Effect1Chance = 100.0
							Effect2Chance = 0.0
						var roll = randf() * 100.0  # Random float from 0-100
						if roll <= Effect1Chance:	
							count += 1
							if Player == 0:
								child.Pit = 7
								child.assign_move(1, Player)
							elif Player == 1:
								child.Pit = 14
								child.assign_move(1, Player)
					elif Effect == "CHAIN":
						Shell1 = child
						TotalEffectChance += 2.5 * child.LuckStacks
						if child.Type == 10:
							TotalEffectChance = 100.0
					elif Effect == "GOLDEN":
						Shell1 = child
						TotalEffectChance += 2.5 * child.LuckStacks
					elif Effect == "HEALING":
						Shell1 = child
						if child.DecayStacks >= 1:
							count += child.DecayStacks
							child.DecayStacks = 0
						if child.BurnStacks >= 1:
							count += child.BurnStacks
							child.BurnStacks = 0
						if child.FreezeStacks >= 1:
							count += child.FreezeStacks
							child.FreezeStacks = 0
						if child.RustStacks >= 1:
							count += child.RustStacks
							child.RustStacks = 0
						if child.CursedStacks >= 1:
							count += child.CursedStacks
							child.CursedStacks = 0
						if child.DisableStacks >= 1:
							count += child.DisableStacks
							child.DisableStacks = 0
					elif Effect == "VOID":
						Shell1 = child
						for movingshells in pvp.get_children():
							if movingshells.is_in_group("MoveShells") and not child.is_in_group("Shells"):
								movingshells.assign_move(1, Player)
						child.assign_move(1, Player)
					elif Effect == "EXPLOSIVE":
						Shell1 = child
						child.BurnStacks += 1
						rng = randi_range(1,14)
						while rng == pit_index + 1:
							rng = randi_range(1,14)
						child.Pit = rng -1
						child.assign_move(1, 0)
					elif Effect == "RANDOM":
						Shell1 = child
						child.Type = randi_range(1,12)
		if Shell1 != null:
			if  Effect == "BASIC":
				effect_text("+1 Score", Color(1.0, 1.0, 1.0, 0.0))
			if Effect == "ANCHOR":	
				effect_text("+1 Multiplier", Color(0.0, 0.5, 1.0, 0.0))
			elif Effect == "ECHO":
				effect_text("Duplicate " + str(count) + " Shells", Color(1.0, 0.0, 0.0, 0.0))
			elif Effect == "SPIRIT":
				Effect1Chance = 25.0
				Effect2Chance = 75.0
				Effect1Chance += TotalEffectChance
				Effect2Chance -= TotalEffectChance
				if Effect1Chance > 100.0:
					Effect1Chance = 100.0
					Effect2Chance = 0.0
				var roll = randf() * 100.0  # Random float from 0-100
				if roll <= Effect1Chance:
					randi_range(1,12)
				var randomType = randi_range(1, 12)  
				pvp.spawn_shell(randomType, pit_index)
				effect_text("Spawn Shell", Color(0.5, 0.0, 1.0, 0.0))
			elif  Effect == "LOOT":
				effect_text("Looted " + str(count) + " Shells", Color(1.0, 0.75, 0.8, 0.0))
			elif Effect == "CHAIN":
				Effect1Chance = 25.0
				Effect2Chance = 75.0
				Effect1Chance += TotalEffectChance
				Effect2Chance -= TotalEffectChance
				if Effect1Chance > 100.0:
					Effect1Chance = 100.0
					Effect2Chance = 0.0
				var roll = randf() * 100.0  # Random float from 0-100
				if roll <= Effect1Chance:
				#add chain click code
					effect_text("Chained Pit", Color(0.0, 0.8, 0.8, 0.0))
			elif Effect == "GOLDEN":
				var times: int = 0
				while times <= 5:
					Effect1Chance = 25.0
					Effect2Chance = 75.0
					Effect1Chance += TotalEffectChance
					Effect2Chance -= TotalEffectChance
					if Effect1Chance > 100.0:
						Effect1Chance = 100.0
						Effect2Chance = 0.0
					var roll = randf() * 100.0  # Random float from 0-100
					if roll <= Effect1Chance:
						count += 1
					times += 1
				effect_text("Golden +" + str(count) + " Score", Color(1.0, 0.84, 0.0, 0.0))
			elif Effect == "HEALING":
				effect_text("Restored " + str(count) + " DebuffShells", Color(0.0, 0.8, 0.0, 0.0))
			elif Effect == "VOID":
				effect_text("Skiped Pit", Color(0.0, 0.0, 0.0, 0.0))
			elif Effect == "EXPLOSIVE":
				effect_text("Explode", Color(1.0, 0.65, 0.0, 0.0))
			elif Effect == "RANDOM":
				effect_text("Types Randomized", Color(0.75, 0.75, 0.75, 0.0))
					
					
					
					
