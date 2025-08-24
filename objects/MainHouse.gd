extends Node2D

# Holds how many shells are in this main house
var shells: int = 0

@onready var shell_label: Label = $StoneLabel

func _ready():
	update_label()
	add_to_group("main_houses")
	
	# Connect shell area signals
	var shell_area = get_node_or_null("ShellArea")
	if shell_area:
		if not shell_area.is_connected("body_entered", _on_shell_area_body_entered):
			shell_area.connect("body_entered", _on_shell_area_body_entered)
		if not shell_area.is_connected("body_exited", _on_shell_area_body_exited):
			shell_area.connect("body_exited", _on_shell_area_body_exited)
		print("MainHouse shell detection connected")
	else:
		print("Warning: ShellArea not found in MainHouse")

# Add shells
func add_shells(amount: int):
	shells += amount
	update_label()
	print("MainHouse now has ", shells, " shells")

# Take all shells (used at end of game to collect remaining pits)
func take_all_shells() -> int:
	var temp = shells
	shells = 0
	update_label()
	print("MainHouse cleared: ", temp, " shells removed")
	return temp

# Update the number display
func update_label():
	if shell_label:
		shell_label.text = str(shells)

# Handle shells entering main house
func _on_shell_area_body_entered(body):
	if body.is_in_group("Shells") and not body.Moving:
		print("Shell entered MainHouse, moves remaining: ", body.Move if body.has_method("get") else "unknown")
		
		# Always capture at least 1 shell in the MainHouse
		add_shells(1)
		
		# Notify campaign manager for scoring
		var campaign_manager = get_tree().get_first_node_in_group("campaign_manager")
		if campaign_manager:
			campaign_manager.add_score(1)  # 1 point per shell in main house
		
		# If shell has more moves, let it continue after a brief stop
		if body.has_method("get") and body.Move > 0:
			print("Shell has ", body.Move, " moves left - continuing journey")
			# Let the shell continue its movement after a short delay
			await get_tree().create_timer(0.2).timeout
			if is_instance_valid(body) and body.has_method("move_shell"):
				body.move_shell(body.Player)
		else:
			# No more moves - shell stays in MainHouse
			print("Shell journey complete - staying in MainHouse")
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(body):
				body.queue_free()

# Handle shells leaving main house (for excess shells)
func _on_shell_area_body_exited(body):
	if body.is_in_group("Shells"):
		print("Shell exited MainHouse")

# Method to release excess shells back to the board
func release_excess_shells(max_shells: int = 10):
	if shells > max_shells:
		var excess = shells - max_shells
		shells = max_shells
		update_label()
		
		# Create excess shells back on the board
		var shell_scene = preload("res://objects/ShellC.tscn")
		var campaign = get_tree().root.get_node_or_null("Campaign")
		
		if campaign:
			for i in range(excess):
				var shell = shell_scene.instantiate()
				# Position shells around the main house
				var angle = (i * 2.0 * PI) / excess
				var radius = 80  # Outside the house area
				var offset = Vector2(cos(angle) * radius, sin(angle) * radius)
				shell.position = global_position + offset
				campaign.add_child(shell)
				await get_tree().process_frame
		
		print("Released ", excess, " excess shells from MainHouse")
