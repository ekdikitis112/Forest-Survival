extends Node


var game_world:Node3D
const WORLD = preload("res://scenes/world.tscn")
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	set_world()



func set_world():
	if not game_world:
		game_world = WORLD.instantiate()
		add_child(game_world)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
