extends RigidBody2D

var shell_type: int = 0
var shellsprite: Sprite2D  # Or AnimatedSprite2D depending on your setup

func _ready() -> void:
	shellsprite = get_node("ShellSprite")
	update_shell_frame()

func set_shell_type(new_type: int) -> void:
	if new_type >= 0 and new_type < 12:
		shell_type = new_type
		update_shell_frame()
	else:
		print("Invalid shell type:", new_type)

func update_shell_frame() -> void:
	shellsprite.frame = shell_type
