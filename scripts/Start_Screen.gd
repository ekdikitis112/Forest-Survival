extends Control

@onready var play = %Play
@onready var settings = %Settings
@onready var exit = %Exit

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/game_creator.tscn")



func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_exit_pressed():
	get_tree().quit()
