extends CheckButton

func _ready():
	# Ensure the signal is connected in case it's not hooked up in the editor
	self.toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
