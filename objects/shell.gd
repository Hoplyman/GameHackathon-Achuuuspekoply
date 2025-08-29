extends RigidBody2D

var Moving: bool = false # is Moving 
var Player: int = 0 # whose player turn for turn purposes
var Pit: int = 0 # what Pit is the Shell is in
var Move: int = 0 # number of Moves 
var Score: int = 0 # total score to tally when in Pits
var TotalScore: int = 0 
var Type: int = 1 # CHANGED: Start with normal shell type (1)
var shellsprite: Sprite2D # the sprite of Shell
var waiting_for_timer: bool = false  # New variable to track timer waiting

var MultiplierStacks: int = 0
var LuckStacks: int = 0
var DecayStacks: int = 0
var BurnStacks: int = 0
var FreezeStacks: int = 0
var RustStacks: int = 0
var CursedStacks: int = 0
var DisableStacks: int = 0

@onready var audio_player := $AudioStreamPlayer2D
@onready var movetimer := $MoveTimer
@onready var scoretimer := $ScoreTimer
@onready var labelscore := $Score
@onready var labeleffect := $Effect
@onready var shell_sprite := $ShellSprite  # Use @onready for proper initialization

# Movement variables
var move_target: Vector2
var move_speed: float = 200.0
var arrival_threshold: float = 10.0
var PitNode: Node2D

const SOUND_BASIC = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_GOLDEN = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_ECHO = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_ANCHOR = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_SPIRIT = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_TIME = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_LUCKY = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_BURN = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_ICE = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")
const SOUND_PLACEMENT = preload("res://assets/Sound/Shell sound/Retro - Magic Respawn.wav")


func _ready() -> void:
	# Wait a frame to ensure all nodes are ready
	# Update appearance and score
	scoretimer.start()
	update_shell_frame()
	set_score()
	set_pit()
	
	add_to_group("Shells")  # Fixed: was "Shell", should be "Shells"
	
	# Fix: Check if signal is already connected before connecting
	if not movetimer.timeout.is_connected(_on_move_timer_timeout):
		movetimer.connect("timeout", Callable(self, "_on_move_timer_timeout"))
	if not scoretimer.timeout.is_connected(_on_score_timer_timeout):
		scoretimer.connect("timeout", Callable(self, "_on_score_timer_timeout"))
	
	print("Shell initialized with type: ", Type)

func effect_text(Text: String, TextColor: Color):
		play_shell_effect_sound(Text)
		labeleffect.text = Text
		labeleffect.modulate = TextColor  # Red but transparent
		labeleffect.visible = true
		var tween = create_tween()
		tween.tween_property(labeleffect, "modulate:a", 1.0, 0.2)  # Fade in
		tween.tween_interval(2.0)  # Wait for 2 seconds (correct function)
		tween.tween_property(labeleffect, "modulate:a", 0.0, 0.3)  # Fade out
		tween.tween_callback(func(): labeleffect.visible = false)  # Hide

func shell_status():
	var cTotalScore: int = 0
	cTotalScore = Score
	if MultiplierStacks >= 1 and (Type != 11 or RustStacks <= 1):
		var Multiplier: int = 0.5 * MultiplierStacks
		Multiplier += 1
		cTotalScore *= Multiplier
	if CursedStacks >= 1 and (Type != 7 or Type != 11):
		var curse_reduction: int = 0.5 - (0.1 * CursedStacks)  # -50% base, +10% per stack
		cTotalScore = int(cTotalScore * curse_reduction)
	TotalScore = cTotalScore

		
func shell_endround():
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	if Type == 1:
		if Pit == 15 or Pit == 16:
			Score += 1
			effect_text("+1", Color(1.0, 1.0, 1.0, 0.0))
		elif Pit >= 1 and Pit <= 14:
			if Score != 1:
				Score = 1
				effect_text("RESET", Color(1.0, 1.0, 1.0, 0.0))
	elif Type == 2:
		Score += 1
		effect_text("GOLDEN", Color(1.0, 0.84, 0.0))
	elif Type == 3:
		Score = 1
		var Echo_Dup = self.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
		get_parent().add_child(Echo_Dup)
		effect_text("ECHO", Color(1.0, 0.0, 0.0, 0.0))
	elif Type == 4:
		if Pit >= 1 and Pit <= 14:
			MultiplierStacks += 1
			var Mulipliertext: int = 0.5 * MultiplierStacks
			Mulipliertext += 1
			effect_text("ANCHOR X"+ str(Mulipliertext), Color(0.0, 0.5, 1.0, 0.0))
	elif Type == 5 and (Pit == 15 or Pit == 16): #var Echo_Dup = self.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
		var randomType = randi_range(1, 12)  #get_parent().add_child(Echo_Dup)
		pvp.spawn_shell(randomType, Pit)
		effect_text("SPIRIT SPAWN", Color(0.5, 0.0, 1.0, 0.0))
	elif Type == 6:
		if Pit == 15 or Pit == 16:
			Score += 2
			effect_text("TIME +2", Color(1.0, 0.75, 0.8, 0.0))
		elif Pit >= 1 and Pit <= 14:
			effect_nearbyshells("TIME")
	elif Type == 7:
		effect_nearbyshells("ER-LUCK")
		LuckStacks += 1
		effect_text("+LUCK", Color(0.0, 0.8, 0.0, 0.0))
	elif Type == 8:
		effect_nearbyshells("ER-MIRROR")
	elif Type == 9:
		pass
		effect_nearbyshells("ER-FLAME")
	elif Type == 12:
		pass
		effect_nearbyshells("ER-ICE")
	if self.DecayStacks >= 1:
		Score /= 2
		DecayStacks -= 1
	if BurnStacks >= 1:
		Score -= BurnStacks
		BurnStacks -= 1
	if FreezeStacks >= 1:
		FreezeStacks -= 1

func shell_drop():
	if Type == 1:
		Score += 1
	elif Type == 2:
		if Pit == 25 or Pit == 16:
			Score += 5
			effect_text("GOLDEN", Color(1.0, 0.84, 0.0, 0.0))
		else:
			Score += 1
	elif Type == 3:
		effect_nearbyshells("DROP-ECHO")
	elif Type == 4:
		if Pit >= 1 and Pit <= 14:
			effect_nearbyshells("DROP-ANCHOR")
			MultiplierStacks += 1 
			var Mulipliertext: int = 0.5 * MultiplierStacks
			Mulipliertext += 1
			effect_text("ANCHOR X"+ str(Mulipliertext), Color(0.0, 0.5, 1.0, 0.0))
	elif Type == 5:
		Score += 1
		var pvp = get_tree().root.get_node_or_null("Gameplay")
		var randomType = randi_range(1, 12)  
		pvp.spawn_shell(randomType, Pit)
		effect_text("SPIRIT", Color(0.5, 0.0, 1.0, 0.0))
	elif Type == 6:
		effect_nearbyshells("TIME")
	elif Type == 7:
		var randomScore = randi_range(1,3)  
		Score += randomScore
		effect_text("LUCKY +" + str(randomScore), Color(0.0, 0.8, 0.0, 0.0))
	elif Type == 8:
		effect_nearbyshells("DROP-MIRROR")
		#Copy 1 Nearby Shell type and change another shell type if no another shell found change this shell type to that type
	elif Type == 9:
		Score += 2
	elif Type == 10:
		Score += 1
		effect_nearbyshells("DROP-CHAIN")
	elif Type == 11:
		Score += 3
		effect_nearbyshells("DROP-PURIFY")
	elif Type == 12:
		Score += 2

func set_score():
	if Type == 1 or Type >= 3 and Type <= 5 or Type == 8 :
		Score = 1
	elif Type == 6 or Type == 7:
		Score = 2
	elif Type == 9 or Type == 12:
		Score = 3
	elif Type == 2 or Type == 11:
		Score = 5
	shell_status()
	labelscore.text = str(TotalScore)
	
func play_shell_effect_sound(effect_name: String):
	if not audio_player:
		return
	
	var sound_to_play = null
	
	# Match effect names to specific sounds
	match effect_name.to_upper():
		"+1":
			sound_to_play = SOUND_BASIC
		"GOLDEN":
			sound_to_play = SOUND_GOLDEN
		"ECHO":
			sound_to_play = SOUND_ECHO
		"ANCHOR X2", "ANCHOR X3", "ANCHOR X4":  # Handle multiplier variations
			sound_to_play = SOUND_ANCHOR
		"SPIRIT SPAWN", "SPIRIT":
			sound_to_play = SOUND_SPIRIT
		"TIME +1", "TIME +2":
			sound_to_play = SOUND_TIME
		"LUCKY +1", "LUCKY +2", "LUCKY +3":
			sound_to_play = SOUND_LUCKY
		"BURNED", "FLAME +1", "FLAME +2":
			sound_to_play = SOUND_BURN
		"FREEZED", "ICE +1", "ICE +2":
			sound_to_play = SOUND_ICE
		_:
			# Default sound for unmatched effects
			sound_to_play = SOUND_PLACEMENT
	
	if sound_to_play:
		audio_player.stream = sound_to_play
		audio_player.play()
		print("Playing shell effect sound for: ", effect_name)

func play_placement_sound():
	if audio_player and audio_player.stream:
		audio_player.play()
		print("Playing shell placement sound")

func get_score() -> int:
	var score: int = Score
	return score
	
func effect_nearbyshells(Effect:String):
	var Shell1: Node2D = null
	var Shell2: Node2D = null
	var count: int = 0
	var rng: int = 0
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = ("Pvp")
	else:
		gamemode = ""
		
	var shell_area = get_node("ShellRange")
	var overlapping_bodies = shell_area.get_overlapping_bodies()

	if gamemode == "Pvp":
		for child in pvp.get_children():
			if is_instance_valid(child):
				if child.is_in_group("Shells") and not child.is_in_group("MoveShells"):
					if child in overlapping_bodies and child != self:
						var tween = create_tween()
						tween.tween_interval(0.1)
						await tween.finished
						if Effect == "DROP-ECHO":
							Shell1 = child
						elif Effect == "DROP-ANCHOR":
							child.MultiplierStacks += 1 
							var Mulipliertext: int = 0.5 * child.MultiplierStacks
							Mulipliertext += 1
							child.effect_text("SHELL X"+ str(Mulipliertext), Color(0.0, 0.5, 1.0, 0.0))
						elif Effect == "TIME":
							child.Score += 1
							child.effect_text("TIME +1", Color(1.0, 0.75, 0.8, 0.0))
						elif Effect == "ER-LUCK":
							child.LuckStacks += 1
							child.effect_text("+LUCK", Color(0.0, 0.8, 0.0, 0.0))
						elif Effect == "ER-MIRROR":
							Shell1 = child
						elif Effect == "DROP-MIRROR":
							if Shell1 == null:
								Shell1 = child
							elif Shell2 == null:
								Shell2 = child
						elif Effect == "ER-FLAME":
							child.BurnStacks += 1
							Score += 1
							count += 1
							child.effect_text("BURNED", Color(1.0, 0.65, 0.0, 0.0))
						elif Effect == "DROP-CHAIN":
							if child.Type == 10 and child.Pit >= 1 and child.Pit <= 14:
								child.assign_move(1,Player)
								rng = 4
								child.effect_text("CHAIN MOVE", Color(0.0, 0.8, 0.8, 0.0))
							if child.Type == 1:
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 2:
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 3:
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 4 and (child.Pit >= 1 or child.Pit <= 14):
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 5:
								Shell1 = child
								if child.Pit == 15 or child.Pit == 16:
									rng = randi_range(1,2)
									if rng == 2:
										rng = 3
								else:
									rng = 3
							elif child.Type == 6:
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 7:
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 8:
								Shell1 = child
								rng = randi_range(1,2)
							elif child.Type == 9:
								Shell1 = child
								rng = randi_range(2,3)
							elif child.Type == 11:
								Shell1 = child
								rng = 3
							elif child.Type == 12:
								Shell1 = child
								rng = randi_range(2,3)
							elif rng != 4:
								self.effect_text("CHAIN BREAK", Color(0.0, 0.8, 0.8, 0.0))
						elif Effect == "DROP-PURIFY":
							if DecayStacks >= 1:
								child.DecayStacks = 0
								count += 1
							if BurnStacks >= 1:
								child.BurnStacks = 0
								count += 1
							if FreezeStacks >= 1:
								child.FreezeStacks = 0
								count += 1
							if RustStacks >= 1:
								child.RustStacks = 0
								count += 1
							if CursedStacks >= 1:
								child.CursedStacks = 0
								count += 1
							if DisableStacks >= 1:
								child.DisableStacks = 0
								count += 1
							if count >= 1:
								child.effect_text("PURIFIED", Color(1.0, 1.0, 0.8, 0.0))
						elif Effect == "ER-ICE":
							child.FreezeStacks += 1
							Score += 1
							count += 1
							child.effect_text("FREEZED", Color(0.0, 1.0, 1.0, 0.0))
							
		if Effect == "DROP-ECHO" and Shell1 != null:
			var Shell_Dup = Shell1.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
			get_parent().add_child(Shell_Dup)
			Shell_Dup.effect_text("ECHO DUP SHELL", Color(1.0, 0.0, 0.0, 0.0))
		elif Effect == "SR-MIRROR" and Shell1 != null:
			Shell1.Type = randi_range(1,12)
			Shell1.effect_text("MIRROR CHANGED", Color(0.75, 0.75, 0.75, 0.0))
			Shell1.update_shell_frame()
		elif Effect == "SR-MIRROR" and Shell1 == null:
			Type = randi_range(1,12)
			effect_text("MIRROR SHATTERED", Color(0.75, 0.75, 0.75, 0.0))
			update_shell_frame()
		elif Effect == "DROP-MIRROR" and Shell1 != null:
			if Shell2 != null:
				Shell2.Type = Shell1.Type
				Shell2.effect_text("MIRROR COPIED", Color(0.75, 0.75, 0.75, 0.0))
				Shell2.update_shell_frame()
			else:
				Type = Shell1.Type
				self.effect_text("MIRROR SHATTERED", Color(0.75, 0.75, 0.75, 0.0))
				self.update_shell_frame()
		elif Effect == "ER-FLAME" and Shell1 != null:
			self.effect_text("FLAME +" + str(count), Color(1.0, 0.65, 0.0, 0.0))
		elif Effect == "DROP-CHAIN" and Shell1 != null:
			if rng == 1:
				Shell1.shell_endround()
				self.effect_text("CHAIN S-ROUND", Color(0.0, 0.8, 0.8, 0.0))
			elif rng == 2:
				Shell1.shell_endround()
				self.effect_text("CHAIN E-ROUND", Color(0.0, 0.8, 0.8, 0.0))	
			elif rng == 3:
				Shell1.shell_drop()
				self.effect_text("CHAIN DROP", Color(0.0, 0.8, 0.8, 0.0))	
		elif Effect == "ER-ICE" and Shell1 != null:
			self.effect_text("ICE +" + str(count), Color(0.0, 1.0, 1.0, 0.0))
	else:
		return 

func set_pit():
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
	if gamemode == "Campaign":
		pass
	elif gamemode == "Pvp":
		var closest_pit: Node2D = null
		var shortest_distance: = INF

		for child in pvp.get_children():
			if child.is_in_group("pits"):
				var dist : = self.global_position.distance_to(child.global_position)
				if dist < shortest_distance:
					shortest_distance = dist
					closest_pit = child
		if closest_pit:
			var name := closest_pit.name
			var pit_number = name.replace("Pit", "")
			Pit = int(pit_number) if pit_number.is_valid_int() else 1
			print("Shell assigned to pit: ", Pit)
		return closest_pit

func set_shell_type(new_type: int) -> void:
	# Fix: Ensure the type is within valid range (0-11 for 12 frames)
	if new_type >= 1 and new_type <= 12:
		Type = new_type
		update_shell_frame()
		set_score()  # Recalculate score for new type
		print("Shell type set to: ", Type)
	else:
		print("Invalid shell type:", new_type)

func update_shell_frame() -> void:
	# Safety check: Make sure shellsprite exists before trying to use it
	if not shellsprite:
		await get_tree().process_frame  # Wait for shell to be ready
		if shell_sprite:
			shellsprite = shell_sprite
		else:
			print("Warning: shellsprite is still null")
			return
	
	# Fix: Ensure frame index is within bounds (0-11 for 12 frames)
	var frame_index = Type - 1 if Type >= 1 else 0
	frame_index = clamp(frame_index, 0, 11)
	
	shellsprite.frame = frame_index

func assign_move(amount: int, player: int):
	Move += amount
	Player = player  # Store the player
	print("Shell at pit ", Pit, " assigned " + str(Move) + " moves for player " + str(player))
	move_shell(player)

func move_shell(player: int):
	# CRITICAL FIX: Proper movement logic that follows the standard Mancala path
	if Move <= 0:
		# No more moves, finalize shell position
		call_deferred("_finalize_movement")
		return
	
	var target: Vector2
	var gamemode: String = ""
	var pvp = get_tree().root.get_node_or_null("Gameplay")
	var campaign = get_tree().root.get_node_or_null("Campaign")
	
	if campaign:
		gamemode = "Campaign"
	elif pvp:
		gamemode = "Pvp"
	else:
		print("No valid game mode found")
		return
	
	# FIXED: Proper pit progression logic using corrected path
	var next_pit = calculate_next_position(Pit, player)
	
	if gamemode == "Pvp":
		if next_pit <= 14 and next_pit >= 1:
			# Regular pit
			PitNode = pvp.get_node_or_null("Pit" + str(next_pit))
			if PitNode:
				target = PitNode.global_position
			else:
				print("ERROR: Could not find Pit", next_pit)
				return
		elif next_pit == 15:
			# Player 1's main house
			var house_node = pvp.get_node_or_null("MainHouse1")
			if house_node:
				target = house_node.global_position
			else:
				print("ERROR: Could not find MainHouse1")
				return
		elif next_pit == 16:
			# Player 2's main house  
			var house_node = pvp.get_node_or_null("MainHouse2")
			if house_node:
				target = house_node.global_position
			else:
				print("ERROR: Could not find MainHouse2")
				return
		else:
			print("ERROR: Invalid next_pit value: ", next_pit)
			return
	
	# Start the movement using deferred calls
	if Moving == false and waiting_for_timer == false:
		call_deferred("_start_movement", target, next_pit)

func _start_movement(target: Vector2, next_pit: int):
	remove_from_group("Shells")
	add_to_group("MoveShells")
	
	collision_layer = 0
	collision_mask = 0
	gravity_scale = 0
	freeze = true
	
	Move -= 1
	Pit = next_pit
	Moving = true
	move_target = target
	
	print("Shell moving from pit ", (next_pit - 1), " to pit ", next_pit, " (", Move, " moves remaining)")
	
func _finalize_movement():
	linear_velocity = Vector2.ZERO
	Moving = false
	collision_layer = 2
	collision_mask = 2 | 3
	gravity_scale = 1
	freeze = false
	remove_from_group("MoveShells")
	add_to_group("Shells")
	shell_drop()
	print("Shell movement complete at pit ", Pit)

func calculate_next_position(current_pit: int, player: int) -> int:
	# Use the exact same logic as GameManager.get_next_position()
	# Convert shell numbering (1-14, 15-16) to GameManager numbering (0-13, 14-15)
	var gm_position = current_pit - 1 if current_pit <= 14 else current_pit - 1
	
	# Get GameManager reference
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() == 0:
		print("ERROR: No GameManager found!")
		return current_pit
	
	var gm = game_manager[0]
	
	# Set the current_turn in GameManager to match our player (convert 1,2 to 0,1)
	var original_turn = gm.current_turn
	gm.current_turn = player - 1
	
	# Use GameManager's get_next_position logic
	var next_gm_position = gm.get_next_position(gm_position)
	
	# Restore original turn
	gm.current_turn = original_turn
	
	# Convert back to shell numbering (0-13, 14-15) to (1-14, 15-16)
	var next_shell_position = next_gm_position + 1 if next_gm_position <= 13 else next_gm_position + 1
	
	print("Shell path: pit ", current_pit, " -> pit ", next_shell_position, " (via GameManager logic)")
	return next_shell_position

func _physics_process(delta):
	if Moving and Move >= 0:
		var total_moveshells = get_tree().get_nodes_in_group("MoveShells").size()
		if total_moveshells <= 5:
			move_speed = 200.0
		elif total_moveshells >= 6 and total_moveshells <= 10:
			move_speed = 300.0
		elif total_moveshells >= 11 and total_moveshells <= 15:
			if move_speed <= 300.0:
				move_speed = 300.0
			else:
				move_speed = 400.0
		elif total_moveshells >= 16 and total_moveshells <= 20:
			if move_speed <= 300.0:
				move_speed = 300.0
			elif move_speed <= 400.0:
				move_speed = 400.0
			else:
				move_speed = 500.0
		elif total_moveshells >= 21 and total_moveshells <= 25:
			if move_speed <= 400.0:
				move_speed = 400.0
			elif move_speed <= 500.0:
				move_speed = 500.0
			else:
				move_speed = 600.0
		elif total_moveshells >= 26 and total_moveshells <= 30:
			if move_speed <= 500.0:
				move_speed = 500.0
			elif move_speed <= 600.0:
				move_speed = 600.0
			else:
				move_speed = 700.0
		elif total_moveshells >= 31 and total_moveshells <= 35:
			if move_speed <= 600.0:
				move_speed = 600.0
			elif move_speed <= 700.0:
				move_speed = 700.0
			else:
				move_speed = 800.0
		elif total_moveshells >= 36 and total_moveshells <= 40:
			if move_speed <= 700.0:
				move_speed = 700.0
			elif move_speed <= 800.0:
				move_speed = 800.0
			else:
				move_speed = 900.0
		elif total_moveshells >= 41 and total_moveshells <= 50 :
			if move_speed <= 800.0:
				move_speed = 800.0
			elif move_speed <= 900.0:
				move_speed = 900.0
			elif move_speed >= 1750.0:
				move_speed = 1750.0
			elif move_speed >= 1500.0:
				move_speed = 1500.0
			elif move_speed >= 1250.0:
				move_speed = 1250.0
			else:
				move_speed = 1000.0
		elif total_moveshells >= 51:
			if move_speed <= 1000.0:
				move_speed = 1000.0
			elif move_speed <= 1250.0:
				move_speed = 1250.0
			elif move_speed <= 1500.0:
				move_speed = 1500.0
			elif move_speed <= 1750.0:
				move_speed = 1750.0
			else:
				move_speed = 2000.0
		var distance_to_target = global_position.distance_to(move_target)
		
		if distance_to_target > arrival_threshold:
			# Move toward target by directly setting position (since body is frozen)
			var direction = (move_target - global_position).normalized()
			var movement_distance = move_speed * delta
			global_position = global_position + (direction * movement_distance)
		else:
			# Arrived at target
			global_position = move_target  # Snap to exact position
			Moving = false
			
			# Check if there are more moves
			if Move > 0:
				# Wait for timer before next move
				waiting_for_timer = true
				movetimer.start()
				print("Arrived at pit ", Pit, " - waiting for timer (", Move, " moves remaining)")
			else:
				# All moves complete - use deferred call to re-enable physics
				call_deferred("_complete_all_movements")

func _complete_all_movements():
	collision_layer = 2
	collision_mask = 2 | 3
	gravity_scale = 1
	freeze = false
	linear_velocity = Vector2.ZERO
	if PitNode != null and PitNode.PitType == 9 and get_tree().get_nodes_in_group("MoveShells").size() == 1:
		assign_move(1,Player)
		var pvp = get_tree().root.get_node_or_null("Gameplay")
		var PitEffect = pvp.get_node_or_null("Pit"+ str(Pit))
		if PitEffect != null:
			PitEffect.effect_text("Skiped Pit", Color(0.0, 0.0, 0.0, 0.0))
	else:
		remove_from_group("MoveShells")
		add_to_group("Shells")
		shell_drop()
	if PitNode != null:
		PitNode.pit_drop()
	print("All movements complete - final position: pit ", Pit)

func _on_move_timer_timeout() -> void:
	movetimer.stop()  # Stop the timer
	if waiting_for_timer and Move > 0:
		waiting_for_timer = false
		print("Timer finished - continuing movement from pit ", Pit)
		move_shell(Player)  # Continue with next move

func _on_score_timer_timeout() -> void:
	shell_status()
	update_shell_frame()
	labelscore.text = str(TotalScore)  # Fixed: was labelscore.Text (capital T)
	scoretimer.start()
