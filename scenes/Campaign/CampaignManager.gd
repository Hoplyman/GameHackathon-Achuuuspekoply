extends Node

# Campaign progression
var current_stage: int = 1
var max_stages: int = 20
var player_score: int = 0
var target_score: int = 300
var currency: int = 100  # Gold for buying shells and upgrades

# Player's collection
var owned_shells: Array = []
var owned_house_upgrades: Array = []
var big_house_level: int = 0

# Game state
enum GameState {
	PLAYING,
	SHOP,
	VICTORY,
	DEFEAT,
	BOSS_PREP
}

var current_state: GameState = GameState.PLAYING

# UI Elements
var campaign_ui: Control
var score_label: Label
var target_label: Label
var currency_label: Label
var stage_label: Label

# Shell types data
var shell_types = {
	"basic": {
		"name": "Basic Shell",
		"cost": 0,
		"effect": "none",
		"description": "A regular shell with no special effects",
		"rarity": "common"
	},
	"gold": {
		"name": "Gold Shell",
		"cost": 50,
		"effect": "bonus_points",
		"bonus": 2,
		"description": "+2 bonus points when reaching big house",
		"rarity": "uncommon"
	},
	"echo": {
		"name": "Echo Shell",
		"cost": 75,
		"effect": "double_trigger",
		"description": "Triggers house effect twice",
		"rarity": "uncommon"
	},
	"spirit": {
		"name": "Spirit Shell",
		"cost": 100,
		"effect": "teleport",
		"description": "Teleports to opposite house and activates it",
		"rarity": "rare"
	},
	"lucky": {
		"name": "Lucky Shell",
		"cost": 80,
		"effect": "duplicate_chance",
		"chance": 20,
		"description": "20% chance to duplicate when placed",
		"rarity": "uncommon"
	},
	"anchor": {
		"name": "Anchor Shell",
		"cost": 120,
		"effect": "seek_big_house",
		"description": "Always stops in the nearest big house",
		"rarity": "rare"
	}
}

# House upgrade types
var house_upgrades = {
	"harvest": {
		"name": "Harvest House",
		"cost": 100,
		"effect": "bonus_per_shells",
		"bonus": 1,
		"threshold": 5,
		"description": "+1 point per 5 shells landed here"
	},
	"echo_house": {
		"name": "Echo House",
		"cost": 150,
		"effect": "copy_last_effect",
		"description": "Copies effect of last shell placed here"
	},
	"sticky": {
		"name": "Sticky House",
		"cost": 120,
		"effect": "delay_release",
		"description": "Holds shells for 1 turn before releasing"
	}
}

# Big house upgrades
var big_house_upgrades = {
	1: {
		"name": "Wealthy Pot",
		"cost": 200,
		"effect": "double_special_scoring",
		"description": "Doubles scoring from special shells"
	},
	2: {
		"name": "Magnet Pot",
		"cost": 300,
		"effect": "attract_shells",
		"chance": 25,
		"description": "25% chance shells land directly here"
	}
}

signal stage_completed
signal game_over
signal shop_entered

func _ready():
	add_to_group("campaign_manager")
	create_campaign_ui()
	start_stage(current_stage)

func create_campaign_ui():
	# Create UI container
	campaign_ui = Control.new()
	campaign_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(campaign_ui)
	
	# Stage label
	stage_label = Label.new()
	stage_label.text = "Stage 1"
	stage_label.position = Vector2(50, 100)
	stage_label.add_theme_font_size_override("font_size", 24)
	stage_label.add_theme_color_override("font_color", Color.WHITE)
	stage_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stage_label.add_theme_constant_override("shadow_offset_x", 2)
	stage_label.add_theme_constant_override("shadow_offset_y", 2)
	campaign_ui.add_child(stage_label)
	
	# Score label
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.position = Vector2(50, 130)
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color.CYAN)
	score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	campaign_ui.add_child(score_label)
	
	# Target score label
	target_label = Label.new()
	target_label.text = "Target: " + str(target_score)
	target_label.position = Vector2(50, 160)
	target_label.add_theme_font_size_override("font_size", 20)
	target_label.add_theme_color_override("font_color", Color.YELLOW)
	target_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	target_label.add_theme_constant_override("shadow_offset_x", 2)
	target_label.add_theme_constant_override("shadow_offset_y", 2)
	campaign_ui.add_child(target_label)
	
	# Currency label
	currency_label = Label.new()
	currency_label.text = "Gold: " + str(currency)
	currency_label.position = Vector2(50, 190)
	currency_label.add_theme_font_size_override("font_size", 20)
	currency_label.add_theme_color_override("font_color", Color.GOLD)
	currency_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	currency_label.add_theme_constant_override("shadow_offset_x", 2)
	currency_label.add_theme_constant_override("shadow_offset_y", 2)
	campaign_ui.add_child(currency_label)

func start_stage(stage_number: int):
	current_stage = stage_number
	player_score = 0
	
	# Calculate target score based on stage
	target_score = 200 + (stage_number * 50)  # Increases each stage
	
	# Reset game state
	current_state = GameState.PLAYING
	
	# Initialize player's shell collection if empty
	if owned_shells.is_empty():
		# Start with basic shells
		for i in range(14):  # 14 pits
			owned_shells.append(create_shell("basic"))
	
	update_ui()
	print("Stage ", stage_number, " started! Target score: ", target_score)

func create_shell(shell_type: String) -> Dictionary:
	if shell_type in shell_types:
		var shell_data = shell_types[shell_type].duplicate()
		shell_data["id"] = generate_shell_id()
		return shell_data
	return {}

func generate_shell_id() -> String:
	return "shell_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func add_score(points: int):
	player_score += points
	update_ui()
	
	# Check if target reached
	if player_score >= target_score:
		complete_stage()

func complete_stage():
	current_state = GameState.VICTORY
	print("Stage ", current_stage, " completed!")
	
	# Award currency based on performance
	var bonus_currency = 50 + (current_stage * 10)
	if player_score > target_score * 1.5:  # Bonus for exceeding target
		bonus_currency *= 2
	
	currency += bonus_currency
	print("Earned ", bonus_currency, " gold!")
	
	stage_completed.emit()
	
	# Check if final stage
	if current_stage >= max_stages:
		win_campaign()
	else:
		enter_shop()

func enter_shop():
	current_state = GameState.SHOP
	print("Entering shop...")
	shop_entered.emit()
	create_shop_ui()

func create_shop_ui():
	# Create shop panel
	var shop_panel = Panel.new()
	shop_panel.position = Vector2(400, 200)
	shop_panel.size = Vector2(600, 400)
	shop_panel.add_theme_color_override("bg_color", Color(0, 0, 0, 0.8))
	campaign_ui.add_child(shop_panel)
	
	# Shop title
	var shop_title = Label.new()
	shop_title.text = "SHELL MASTERS SHOP"
	shop_title.position = Vector2(200, 20)
	shop_title.add_theme_font_size_override("font_size", 24)
	shop_title.add_theme_color_override("font_color", Color.GOLD)
	shop_panel.add_child(shop_title)
	
	# Create shell shop items
	create_shell_shop_items(shop_panel)
	
	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "Continue to Next Stage"
	continue_btn.position = Vector2(200, 350)
	continue_btn.size = Vector2(200, 40)
	continue_btn.pressed.connect(continue_to_next_stage)
	shop_panel.add_child(continue_btn)

func create_shell_shop_items(parent: Panel):
	var y_offset = 60
	var available_shells = ["gold", "echo", "spirit", "lucky", "anchor"]
	
	for i in range(min(3, available_shells.size())):  # Show 3 random shells
		var shell_key = available_shells[randi() % available_shells.size()]
		var shell_data = shell_types[shell_key]
		
		# Shell item container
		var item_container = Control.new()
		item_container.position = Vector2(20, y_offset)
		item_container.size = Vector2(560, 60)
		parent.add_child(item_container)
		
		# Shell name and description
		var shell_info = Label.new()
		shell_info.text = shell_data.name + " - " + shell_data.description
		shell_info.position = Vector2(10, 10)
		shell_info.add_theme_font_size_override("font_size", 16)
		shell_info.add_theme_color_override("font_color", Color.WHITE)
		item_container.add_child(shell_info)
		
		# Cost and buy button
		var buy_btn = Button.new()
		buy_btn.text = "Buy (" + str(shell_data.cost) + " gold)"
		buy_btn.position = Vector2(400, 10)
		buy_btn.size = Vector2(140, 30)
		buy_btn.disabled = currency < shell_data.cost
		buy_btn.pressed.connect(func(): buy_shell(shell_key))
		item_container.add_child(buy_btn)
		
		y_offset += 80

func buy_shell(shell_type: String):
	var shell_data = shell_types[shell_type]
	if currency >= shell_data.cost:
		currency -= shell_data.cost
		owned_shells.append(create_shell(shell_type))
		print("Bought ", shell_data.name, "!")
		update_ui()
		# Refresh shop
		for child in campaign_ui.get_children():
			if child is Panel and child.get_child_count() > 0:
				var first_child = child.get_child(0)
				if first_child is Label and first_child.text == "SHELL MASTERS SHOP":
					child.queue_free()
					break
		create_shop_ui()

func continue_to_next_stage():
	# Clean up shop UI
	for child in campaign_ui.get_children():
		if child is Panel:
			child.queue_free()
	
	# Start next stage
	start_stage(current_stage + 1)

func update_ui():
	if stage_label:
		stage_label.text = "Stage " + str(current_stage)
	if score_label:
		score_label.text = "Score: " + str(player_score)
	if target_label:
		target_label.text = "Target: " + str(target_score)
	if currency_label:
		currency_label.text = "Gold: " + str(currency)

func get_player_shells() -> Array:
	return owned_shells

func apply_shell_effect(shell_data: Dictionary, target_house: Node2D) -> int:
	var bonus_points = 0
	
	match shell_data.effect:
		"bonus_points":
			if "bonus" in shell_data:
				bonus_points = shell_data.bonus
				print("Gold shell bonus: +", bonus_points, " points!")
		
		"double_trigger":
			# This would need to be handled by the house system
			print("Echo shell: triggering house effect twice!")
		
		"duplicate_chance":
			if "chance" in shell_data:
				if randi() % 100 < shell_data.chance:
					print("Lucky shell duplicated!")
					bonus_points = 1  # Small bonus for duplication
		
		"seek_big_house":
			print("Anchor shell seeking big house!")
			bonus_points = 1  # Always gets to big house
	
	return bonus_points

func win_campaign():
	print("CAMPAIGN COMPLETED! Congratulations!")
	game_over.emit()

func lose_stage():
	print("Stage failed! Try again or return to shop.")
	current_state = GameState.DEFEAT
