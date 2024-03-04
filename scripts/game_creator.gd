extends Control

@onready var start = $PanelContainer/VBoxContainer/StartContainer/start
@onready var line_edit = $PanelContainer/VBoxContainer/LineEditContainer/LineEdit

var regex = RegEx.new()
var text = ""

func _ready():
	regex.compile("^[a-zA-Z0-9]+$")

func _on_start_pressed():
	if regex.search(text):
		Globals.game_seed.seed = hash(text)
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_line_edit_text_changed(input):
	self.text = input
	if regex.search(text):
		start.disabled = false
	else:
		start.disabled = true



func _on_randomize_pressed():
	#15 length integer number
	Globals.game_seed.seed = hash(randi_range(0,9999999999))
	self.text = str(Globals.game_seed.seed)
	line_edit.text = self.text
