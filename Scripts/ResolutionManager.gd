extends Node

# Base resolution that your game was designed for
const BASE_WIDTH = 1920
const BASE_HEIGHT = 1080

var scale_factor: float = 1.0

func _ready():
	# Connect to screen size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("adjust_for_resolution")

func _on_viewport_size_changed():
	adjust_for_resolution()

func adjust_for_resolution():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate scale factor based on the smaller ratio to maintain aspect ratio
	var width_ratio = viewport_size.x / BASE_WIDTH
	var height_ratio = viewport_size.y / BASE_HEIGHT
	scale_factor = min(width_ratio, height_ratio)
	
	# Apply scaling to the main scene
	var root = get_tree().current_scene
	if root:
		root.scale = Vector2(scale_factor, scale_factor)
		
		# Center the scaled content
		var scaled_size = Vector2(BASE_WIDTH * scale_factor, BASE_HEIGHT * scale_factor)
		var offset = (viewport_size - scaled_size) / 2
		root.position = offset
	
	print("Screen resolution: ", viewport_size)
	print("Scale factor: ", scale_factor)
	print("Applied scaling and centering")

func get_scale_factor() -> float:
	return scale_factor

# Function to convert screen coordinates to game coordinates
func screen_to_game_coords(screen_pos: Vector2) -> Vector2:
	var root = get_tree().current_scene
	if root:
		return (screen_pos - root.position) / scale_factor
	return screen_pos

# Function to convert game coordinates to screen coordinates  
func game_to_screen_coords(game_pos: Vector2) -> Vector2:
	var root = get_tree().current_scene
	if root:
		return game_pos * scale_factor + root.position
	return game_pos
