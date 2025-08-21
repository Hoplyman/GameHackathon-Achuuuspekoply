class_name Shell
extends Resource

@export var shell_type: String = "basic"
@export var shell_name: String = "Basic Shell"
@export var effect: String = "none"
@export var rarity: String = "common"
@export var description: String = "A regular shell with no special effects"
@export var cost: int = 0

# Effect-specific properties
@export var bonus_points: int = 0
@export var duplicate_chance: int = 0
@export var effect_data: Dictionary = {}

func _init(type: String = "basic"):
	shell_type = type
	setup_shell_data()

func setup_shell_data():
	match shell_type:
		"basic":
			shell_name = "Basic Shell"
			effect = "none"
			rarity = "common"
			description = "A regular shell with no special effects"
			cost = 0
		
		"gold":
			shell_name = "Gold Shell"
			effect = "bonus_points"
			rarity = "uncommon"
			description = "+2 bonus points when reaching big house"
			cost = 50
			bonus_points = 2
		
		"echo":
			shell_name = "Echo Shell"
			effect = "double_trigger"
			rarity = "uncommon"
			description = "Triggers house effect twice"
			cost = 75
		
		"spirit":
			shell_name = "Spirit Shell"
			effect = "teleport"
			rarity = "rare"
			description = "Teleports to opposite house and activates it"
			cost = 100
		
		"lucky":
			shell_name = "Lucky Shell"
			effect = "duplicate_chance"
			rarity = "uncommon"
			description = "20% chance to duplicate when placed"
			cost = 80
			duplicate_chance = 20
		
		"anchor":
			shell_name = "Anchor Shell"
			effect = "seek_big_house"
			rarity = "rare"
			description = "Always stops in the nearest big house"
			cost = 120

func get_rarity_color() -> Color:
	match rarity:
		"common":
			return Color.WHITE
		"uncommon":
			return Color.CYAN
		"rare":
			return Color.PURPLE
		"epic":
			return Color.ORANGE
		"legendary":
			return Color.GOLD
		_:
			return Color.WHITE

func apply_effect(target_house: Node2D, game_manager: Node) -> int:
	var bonus = 0
	
	match effect:
		"bonus_points":
			bonus = bonus_points
			print(shell_name, " bonus: +", bonus, " points!")
		
		"duplicate_chance":
			if randi() % 100 < duplicate_chance:
				bonus = 1
				print(shell_name, " duplicated!")
		
		"seek_big_house":
			bonus = 1
			print(shell_name, " seeks the big house!")
		
		"double_trigger":
			# This would need to be handled by the house system
			print(shell_name, ": double trigger effect!")
		
		"teleport":
			print(shell_name, ": teleport effect!")
			bonus = 1
	
	return bonus
