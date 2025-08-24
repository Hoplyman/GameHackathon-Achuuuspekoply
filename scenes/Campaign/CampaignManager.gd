extends Node

# Campaign progression
var current_stage: int = 1
var max_stages: int = 20
var player_score: int = 0
var target_score: int = 300
var currency: int = 150  # Start with more gold

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

# Achievements and unlocks
var achievements = {
	"first_win": false,
	"perfect_score": false,
	"shell_collector": false,
	"boss_slayer": false,
	"efficiency_master": false
}

var unlocked_content = {
	"shells": ["basic", "gold"],
	"houses": ["harvest"],
	"big_house_upgrades": []
}

# UI Elements
var campaign_ui: Control
var score_label: Label
var target_label: Label
var currency_label: Label
var stage_label: Label

# Enhanced shell types
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
	},
	"memory": {
		"name": "Memory Shell",
		"cost": 150,
		"effect": "evolving",
		"description": "Gets +1 bonus point each time it's used",
		"rarity": "epic"
	},
	"phoenix": {
		"name": "Phoenix Shell",
		"cost": 200,
		"effect": "sacrifice",
		"description": "Destroys itself for +10 points",
		"rarity": "legendary"
	}
}

# House upgrades
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
	},
	"magnet": {
		"name": "Magnet House",
		"cost": 180,
		"effect": "attract_shells",
		"chance": 30,
		"description": "30% chance to pull shells from adjacent pits"
	}
}

signal stage_completed
signal game_over
signal shop_entered
signal achievement_unlocked(achievement_name: String, title: String, description: String)

func _ready():
	add_to_group("campaign_manager")
	create_campaign_ui()
	load_campaign_progress()
	start_stage(current_stage)

func create_campaign_ui():
	campaign_ui = Control.new()
	campaign_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.call_deferred("add_child", campaign_ui)
	
	# Create UI labels with better positioning
	create_ui_labels()

func create_ui_labels():
	# Stage label
	stage_label = Label.new()
	stage_label.text = "Stage 1"
	stage_label.position = Vector2(50, 100)
	stage_label.add_theme_font_size_override("font_size", 28)
	stage_label.add_theme_color_override("font_color", Color.GOLD)
	add_label_shadow(stage_label)
	campaign_ui.add_child(stage_label)
	
	# Score label
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.position = Vector2(50, 135)
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color.CYAN)
	add_label_shadow(score_label)
	campaign_ui.add_child(score_label)
	
	# Target score label
	target_label = Label.new()
	target_label.text = "Target: " + str(target_score)
	target_label.position = Vector2(50, 170)
	target_label.add_theme_font_size_override("font_size", 22)
	target_label.add_theme_color_override("font_color", Color.YELLOW)
	add_label_shadow(target_label)
	campaign_ui.add_child(target_label)
	
	# Currency label
	currency_label = Label.new()
	currency_label.text = "Gold: " + str(currency)
	currency_label.position = Vector2(50, 205)
	currency_label.add_theme_font_size_override("font_size", 22)
	currency_label.add_theme_color_override("font_color", Color.GOLD)
	add_label_shadow(currency_label)
	campaign_ui.add_child(currency_label)

func add_label_shadow(label: Label):
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

func is_boss_stage() -> bool:
	return current_stage % 5 == 0

func start_stage(stage_number: int):
	current_stage = stage_number
	player_score = 0
	
	# Calculate target score
	target_score = 0 + (stage_number * 5)
	
	# Boss stage modifications
	if is_boss_stage():
		target_score = int(target_score * 1.5)  # 50% higher target
		print("BOSS BATTLE - Stage ", stage_number, "!")
		show_boss_warning()
	
	current_state = GameState.PLAYING
	
	# Initialize shells if empty
	if owned_shells.is_empty():
		for i in range(14):
			owned_shells.append(create_shell("basic"))
	
	check_unlocks()
	update_ui()
	print("Stage ", stage_number, " started! Target score: ", target_score)

func show_boss_warning():
	var boss_warning = Label.new()
	boss_warning.text = "BOSS BATTLE!"
	boss_warning.position = Vector2(400, 300)
	boss_warning.add_theme_font_size_override("font_size", 36)
	boss_warning.add_theme_color_override("font_color", Color.RED)
	add_label_shadow(boss_warning)
	campaign_ui.add_child(boss_warning)
	
	# Remove after 3 seconds
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(boss_warning.queue_free)

func check_unlocks():
	match current_stage:
		3:
			unlock_content("shells", "echo")
		5:
			unlock_content("shells", "spirit")
			unlock_content("houses", "echo_house")
		8:
			unlock_content("shells", "lucky")
		10:
			unlock_content("houses", "sticky")
			unlock_content("big_house_upgrades", "wealthy_pot")
		12:
			unlock_content("shells", "anchor")
		15:
			unlock_content("shells", "memory")
			unlock_content("houses", "magnet")
		18:
			unlock_content("shells", "phoenix")

func unlock_content(category: String, item: String):
	if not item in unlocked_content[category]:
		unlocked_content[category].append(item)
		show_unlock_notification(category, item)

func show_unlock_notification(category: String, item: String):
	var notification = Label.new()
	notification.text = "UNLOCKED: " + item.replace("_", " ").capitalize()
	notification.position = Vector2(400, 200)
	notification.add_theme_font_size_override("font_size", 24)
	notification.add_theme_color_override("font_color", Color.LIME_GREEN)
	add_label_shadow(notification)
	campaign_ui.add_child(notification)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(notification, "position:y", 150, 0.5)
	tween.tween_property(notification, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification.queue_free)

func create_shell(shell_type: String) -> Dictionary:
	if shell_type in shell_types:
		var shell_data = shell_types[shell_type].duplicate()
		shell_data["id"] = generate_shell_id()
		shell_data["usage_count"] = 0  # For memory shells
		return shell_data
	return {}

func generate_shell_id() -> String:
	return "shell_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func add_score(points: int):
	player_score += points
	update_ui()
	
	if player_score >= target_score:
		complete_stage()

func complete_stage():
	current_state = GameState.VICTORY
	print("Stage ", current_stage, " completed!")
	
	# Check achievements
	check_achievements()
	
	# Award currency
	var bonus_currency = 75 + (current_stage * 15)
	if player_score > target_score * 1.5:
		bonus_currency *= 2
		print("PERFECT SCORE BONUS!")
	
	currency += bonus_currency
	print("Earned ", bonus_currency, " gold!")
	
	stage_completed.emit()
	
	if current_stage >= max_stages:
		win_campaign()
	else:
		enter_shop()

func check_achievements():
	if current_stage == 1 and not achievements["first_win"]:
		unlock_achievement("first_win", "First Victory!", "Complete your first stage")
	
	if player_score >= target_score * 1.5 and not achievements["perfect_score"]:
		unlock_achievement("perfect_score", "Perfect Score!", "Exceed target by 50%")
	
	if owned_shells.size() >= 20 and not achievements["shell_collector"]:
		unlock_achievement("shell_collector", "Shell Collector", "Collect 20+ shells")
	
	if current_stage % 5 == 0 and current_stage >= 5 and not achievements["boss_slayer"]:
		unlock_achievement("boss_slayer", "Boss Slayer", "Defeat your first boss")

func unlock_achievement(key: String, title: String, description: String):
	achievements[key] = true
	achievement_unlocked.emit(key, title, description)
	show_achievement_popup(title, description)
	
	# Achievement rewards
	currency += 50
	print("Achievement unlocked: ", title, " (+50 gold)")

func show_achievement_popup(title: String, description: String):
	var popup = Panel.new()
	popup.position = Vector2(300, 150)
	popup.size = Vector2(400, 100)
	popup.add_theme_color_override("bg_color", Color(0.2, 0.1, 0.4, 0.9))
	campaign_ui.add_child(popup)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	popup.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.position = Vector2(20, 45)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	popup.add_child(desc_label)
	
	# Auto-remove after 4 seconds
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(popup.queue_free)

func enter_shop():
	current_state = GameState.SHOP
	shop_entered.emit()
	create_enhanced_shop_ui()

func create_enhanced_shop_ui():
	var shop_panel = Panel.new()
	shop_panel.position = Vector2(200, 100)
	shop_panel.size = Vector2(800, 600)
	shop_panel.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.2, 0.95))
	campaign_ui.add_child(shop_panel)
	
	# Shop title
	var shop_title = Label.new()
	shop_title.text = "SHELL MASTERS SHOP - Stage " + str(current_stage)
	shop_title.position = Vector2(200, 20)
	shop_title.add_theme_font_size_override("font_size", 24)
	shop_title.add_theme_color_override("font_color", Color.GOLD)
	shop_panel.add_child(shop_title)
	
	# Create tabs or sections
	create_shell_shop_section(shop_panel)
	create_house_upgrade_section(shop_panel)
	
	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "Continue to Next Stage"
	continue_btn.position = Vector2(300, 540)
	continue_btn.size = Vector2(200, 40)
	continue_btn.add_theme_font_size_override("font_size", 16)
	shop_panel.add_child(continue_btn)

func create_shell_shop_section(parent: Panel):
	var section_title = Label.new()
	section_title.text = "SHELLS"
	section_title.position = Vector2(50, 60)
	section_title.add_theme_font_size_override("font_size", 20)
	section_title.add_theme_color_override("font_color", Color.CYAN)
	parent.add_child(section_title)
	
	var y_offset = 90
	var available_shells = get_available_shells_for_shop()
	
	for i in range(min(4, available_shells.size())):
		var shell_key = available_shells[i]
		var shell_data = shell_types[shell_key]
		
		create_shell_shop_item(parent, shell_key, shell_data, y_offset)
		y_offset += 70

func get_available_shells_for_shop() -> Array:
	var available = []
	for shell_key in shell_types.keys():
		if shell_key in unlocked_content["shells"] and shell_key != "basic":
			available.append(shell_key)
	available.shuffle()
	return available

func create_shell_shop_item(parent: Panel, shell_key: String, shell_data: Dictionary, y_pos: int):
	var container = Control.new()
	container.position = Vector2(50, y_pos)
	container.size = Vector2(700, 60)
	parent.add_child(container)
	
	# Rarity color indicator
	var rarity_rect = ColorRect.new()
	rarity_rect.position = Vector2(0, 0)
	rarity_rect.size = Vector2(5, 60)
	rarity_rect.color = get_rarity_color(shell_data.get("rarity", "common"))
	container.add_child(rarity_rect)
	
	# Shell info
	var shell_info = Label.new()
	shell_info.text = shell_data.name + " - " + shell_data.description
	shell_info.position = Vector2(15, 10)
	shell_info.add_theme_font_size_override("font_size", 16)
	shell_info.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(shell_info)
	
	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Buy (" + str(shell_data.cost) + "g)"
	buy_btn.position = Vector2(580, 15)
	buy_btn.size = Vector2(100, 30)
	buy_btn.disabled = currency < shell_data.cost
	buy_btn.pressed.connect(func(): buy_shell(shell_key))
	container.add_child(buy_btn)

func create_house_upgrade_section(parent: Panel):
	var section_title = Label.new()
	section_title.text = "HOUSE UPGRADES"
	section_title.position = Vector2(50, 320)
	section_title.add_theme_font_size_override("font_size", 20)
	section_title.add_theme_color_override("font_color", Color.ORANGE)
	parent.add_child(section_title)
	
	var y_offset = 350
	var available_upgrades = get_available_house_upgrades()
	
	for i in range(min(2, available_upgrades.size())):
		var upgrade_key = available_upgrades[i]
		var upgrade_data = house_upgrades[upgrade_key]
		
		create_house_upgrade_item(parent, upgrade_key, upgrade_data, y_offset)
		y_offset += 70

func get_available_house_upgrades() -> Array:
	var available = []
	for upgrade_key in house_upgrades.keys():
		if upgrade_key in unlocked_content["houses"] and not upgrade_key in owned_house_upgrades:
			available.append(upgrade_key)
	return available

func create_house_upgrade_item(parent: Panel, upgrade_key: String, upgrade_data: Dictionary, y_pos: int):
	var container = Control.new()
	container.position = Vector2(50, y_pos)
	container.size = Vector2(700, 60)
	parent.add_child(container)
	
	var upgrade_info = Label.new()
	upgrade_info.text = upgrade_data.name + " - " + upgrade_data.description
	upgrade_info.position = Vector2(15, 10)
	upgrade_info.add_theme_font_size_override("font_size", 16)
	upgrade_info.add_theme_color_override("font_color", Color.ORANGE)
	container.add_child(upgrade_info)
	
	var buy_btn = Button.new()
	buy_btn.text = "Buy (" + str(upgrade_data.cost) + "g)"
	buy_btn.position = Vector2(580, 15)
	buy_btn.size = Vector2(100, 30)
	buy_btn.disabled = currency < upgrade_data.cost
	buy_btn.pressed.connect(func(): buy_house_upgrade(upgrade_key))
	container.add_child(buy_btn)

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"uncommon": return Color.CYAN
		"rare": return Color.PURPLE
		"epic": return Color.ORANGE
		"legendary": return Color.GOLD
		_: return Color.WHITE

func buy_shell(shell_type: String):
	var shell_data = shell_types[shell_type]
	if currency >= shell_data.cost:
		currency -= shell_data.cost
		owned_shells.append(create_shell(shell_type))
		print("Bought ", shell_data.name, "!")
		update_ui()
		refresh_shop()

func buy_house_upgrade(upgrade_key: String):
	var upgrade_data = house_upgrades[upgrade_key]
	if currency >= upgrade_data.cost:
		currency -= upgrade_data.cost
		owned_house_upgrades.append(upgrade_key)
		print("Bought ", upgrade_data.name, "!")
		update_ui()
		refresh_shop()

func refresh_shop():
	# Remove existing shop panel
	for child in campaign_ui.get_children():
		if child is Panel and child.size.x > 400:  # Shop panel is larger
			child.queue_free()
			break
	
	# Recreate shop
	await get_tree().process_frame
	create_enhanced_shop_ui()

func update_ui():
	if stage_label:
		var stage_text = "Stage " + str(current_stage)
		if is_boss_stage():
			stage_text += " BOSS"
		stage_label.text = stage_text
	
	if score_label:
		score_label.text = "Score: " + str(player_score)
	
	if target_label:
		target_label.text = "Target: " + str(target_score)
		# Change color based on progress
		var progress = float(player_score) / float(target_score)
		if progress >= 1.0:
			target_label.add_theme_color_override("font_color", Color.LIME_GREEN)
		elif progress >= 0.8:
			target_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			target_label.add_theme_color_override("font_color", Color.WHITE)
	
	if currency_label:
		currency_label.text = "Gold: " + str(currency)

func get_player_shells() -> Array:
	return owned_shells

func get_owned_house_upgrades() -> Array:
	return owned_house_upgrades

func apply_shell_effect(shell_data: Dictionary, target_house: Node2D) -> int:
	var bonus_points = 0
	
	match shell_data.effect:
		"bonus_points":
			bonus_points = shell_data.get("bonus", 0)
			print("Gold shell bonus: +", bonus_points, " points!")
		
		"duplicate_chance":
			var chance = shell_data.get("chance", 0)
			if randi() % 100 < chance:
				bonus_points = 2
				print("Lucky shell duplicated! +2 points!")
		
		"seek_big_house":
			bonus_points = 3
			print("Anchor shell seeks big house! +3 points!")
		
		"evolving":
			# Memory shell gets stronger each use
			shell_data["usage_count"] = shell_data.get("usage_count", 0) + 1
			bonus_points = shell_data["usage_count"]
			print("Memory shell evolves! Usage: ", shell_data["usage_count"], " (+", bonus_points, " points)")
		
		"sacrifice":
			# Phoenix shell destroys itself for big bonus
			bonus_points = 10
			owned_shells.erase(shell_data)
			print("Phoenix shell sacrifices itself! +10 points!")
			show_sacrifice_effect(target_house)
		
		"double_trigger":
			print("Echo shell triggers house effect twice!")
			bonus_points = apply_house_upgrade_effects(target_house) * 2
		
		"teleport":
			print("Spirit shell teleports!")
			bonus_points = 2
	
	return bonus_points

func apply_house_upgrade_effects(house: Node2D) -> int:
	var bonus = 0
	
	for upgrade_key in owned_house_upgrades:
		var upgrade_data = house_upgrades[upgrade_key]
		
		match upgrade_data.effect:
			"bonus_per_shells":
				var shells_in_house = house.shells if house.has_method("get_shells") else 0
				if shells_in_house >= upgrade_data.get("threshold", 5):
					bonus += upgrade_data.get("bonus", 1)
					print("Harvest bonus: +", upgrade_data.get("bonus", 1))
			
			"attract_shells":
				var chance = upgrade_data.get("chance", 30)
				if randi() % 100 < chance:
					bonus += 1
					print("Magnet house attracts shell! +1")
			
			"copy_last_effect":
				bonus += 1
				print("Echo house copies effect! +1")
	
	return bonus

func show_sacrifice_effect(target_house: Node2D):
	if not target_house:
		return
	
	# Create fire particles effect
	var fire_effect = ColorRect.new()
	fire_effect.size = Vector2(20, 20)
	fire_effect.color = Color.ORANGE_RED
	fire_effect.position = target_house.global_position
	get_tree().current_scene.add_child(fire_effect)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(fire_effect, "scale", Vector2(3, 3), 0.5)
	tween.parallel().tween_property(fire_effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(fire_effect.queue_free)

func save_campaign_progress():
	var save_data = {
		"current_stage": current_stage,
		"currency": currency,
		"owned_shells": owned_shells,
		"owned_house_upgrades": owned_house_upgrades,
		"big_house_level": big_house_level,
		"achievements": achievements,
		"unlocked_content": unlocked_content
	}
	
	var file = FileAccess.open("user://campaign_save.dat", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Campaign progress saved")

func load_campaign_progress():
	if FileAccess.file_exists("user://campaign_save.dat"):
		var file = FileAccess.open("user://campaign_save.dat", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var save_data = json.get_data()
				current_stage = save_data.get("current_stage", 1)
				currency = save_data.get("currency", 150)
				owned_shells = save_data.get("owned_shells", [])
				owned_house_upgrades = save_data.get("owned_house_upgrades", [])
				big_house_level = save_data.get("big_house_level", 0)
				achievements = save_data.get("achievements", achievements)
				unlocked_content = save_data.get("unlocked_content", unlocked_content)
				print("Campaign progress loaded!")

func win_campaign():
	print("CAMPAIGN COMPLETED! Congratulations, Shell Master!")
	
	if not achievements.get("campaign_complete", false):
		achievements["campaign_complete"] = true
		show_achievement_popup("Campaign Master!", "Completed all 20 stages!")
	
	show_victory_screen()
	game_over.emit()

func show_victory_screen():
	var victory_panel = Panel.new()
	victory_panel.position = Vector2(200, 150)
	victory_panel.size = Vector2(600, 400)
	victory_panel.add_theme_color_override("bg_color", Color(0.1, 0.2, 0.1, 0.95))
	campaign_ui.add_child(victory_panel)
	
	var title = Label.new()
	title.text = "VICTORY!"
	title.position = Vector2(200, 50)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.GOLD)
	victory_panel.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "You are the ultimate Shell Master!"
	subtitle.position = Vector2(150, 120)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	victory_panel.add_child(subtitle)
