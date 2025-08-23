extends CenterContainer

func center_shells():
	var shells := []
	var spacing := 10  # Adjust spacing between shells
	var total_width := 0

	# Collect Shell1 to Shell20
	for i in range(1, 21):
		var shell_name = "Shell%d" % i
		var shell = get_node(shell_name)
		if shell and shell is Sprite2D:
			shells.append(shell)
			total_width += shell.texture.get_size().x + spacing

	total_width -= spacing  # Remove extra spacing after last shell

	# Start x position to center the group
	var start_x := -total_width / 2

	# Position each shell
	for shell in shells:
		var width = shell.texture.get_size().x
		shell.position = Vector2(start_x + width / 2, 0)
		start_x += width + spacing
