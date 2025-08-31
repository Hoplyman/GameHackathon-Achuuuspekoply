extends Camera2D

# Tween for smooth movement
var camera_tween: Tween

func _ready():
	# Initialize tween (Godot 4 style, will fallback to Godot 3 if needed)
	camera_tween = create_tween()

func move_to_position(Move: String):
	var target_position: Vector2
	
	if Move == "Bottom":
		target_position = Vector2(1000, 875)  # Adjust these values as needed
	elif Move == "Center":
		target_position = Vector2(1000, 675)     # Adjust these values as needed
	else:
		print("Unknown camera position: " + Move)
		return
	
	# Create new tween each time (Godot 4 style)
	camera_tween = create_tween()
	camera_tween.tween_property(self, "position", target_position, 1.0)

# Alternative function for instant movement
func move_to_position_instant(Move: String):
	if Move == "Bottom":
		position = Vector2(1000, 875)
	elif Move == "Center":
		position = Vector2(1000, 675)
	else:
		print("Unknown camera position: " + Move)

# Optional: Add custom positions
func move_to_custom_position(pos: Vector2, duration: float = 1.0):
	camera_tween.tween_property(self, "position", pos, duration)
