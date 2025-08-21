extends Control



func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/Board.tscn")


func _on_options_pressed():
	get_tree().change_scene_to_file("Options")



func _on_quit_pressed():
	get_tree().quit()


func _on_versus_pressed():
	get_tree().change_scene_to_file("res://scenes/Board.tscn")
