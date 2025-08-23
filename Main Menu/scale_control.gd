extends OptionButton

func _on_item_selected(index: int) -> void:
	var options = [1, 0.5, 0.25]
	var value = options[index]
	print(value)
	get_tree().root.scaling_2d_scale = value
