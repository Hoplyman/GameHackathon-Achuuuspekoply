extends Control

@onready var button_container: VBoxContainer = $Button_Container
@onready var settings_panel: Panel = $"Settings Panel"

func _ready():
	button_container.visible = true
	settings_panel.visible = false
	
func _on_start_pressed(): 
	get_tree().change_scene_to_file("res://scenes/TutorialScreen.tscn")

func _on_settings_pressed(): 
	button_container.visible = false 
	settings_panel.visible = true

func _on_quit_pressed(): 
	get_tree().quit(0)

func _on_back_pressed():
	button_container.visible = true 
	settings_panel.visible = false


func _on_versus_pressed():
	get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")
