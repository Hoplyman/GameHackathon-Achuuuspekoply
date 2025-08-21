extends Sprite2D

# Integer shell type (0 to 11)
var shell_type: int = 0

func _ready() -> void:
	update_shell_frame()

func set_shell_type(new_type: int) -> void:
	if new_type >= 0 and new_type < 12:
		shell_type = new_type
		update_shell_frame()
	else:
		print("Invalid shell type:", new_type)

func update_shell_frame() -> void:
	frame = shell_type
