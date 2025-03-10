extends Control

@onready var resume = %Resume
@onready var settings = %Settings
@onready var exit = %Exit


func _on_resume_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	get_parent().remove_child(self)

func _on_settings_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	get_tree().quit()
