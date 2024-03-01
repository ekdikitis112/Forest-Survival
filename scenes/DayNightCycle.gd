extends Node3D

var time : float
@export var day_length : float = 600.0
@export var start_time : float = 0.3
var time_rate : float

# sun 
@onready var sun = $Sun
@export var sun_color : Gradient
@export var sun_intensity : Curve

# moon
@onready var moon = $Moon
@export var moon_color : Gradient
@export var moon_intensity : Curve

# environment
@onready var environment = $WorldEnvironment
@export var sky_top_color: Gradient
@export var sky_horizon_color: Gradient

# Called when the node enters the scene tree for the first time.
func _ready():
	time_rate = 1.0 / day_length
	time = start_time
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += time_rate * delta
	
	if time >= 1.0:
		time = 0.0
	
	# sun
	sun.rotation_degrees.x = time * 360 + 90
	sun.light_color = sun_color.sample(time)
	sun.light_energy = sun_intensity.sample(time)
	
	# moon
	moon.rotation_degrees.x = time * 360 + 270
	moon.light_color = moon_color.sample(time)
	moon.light_energy = moon_intensity.sample(time)
	
	# enable/disable sun and moon 
	sun.visible = sun.light_energy > 0
	moon.visible = moon.light_energy > 0
	
	# setting sky color
	environment.environment.sky.sky_material.set("sky_top_color", sky_top_color.sample(time))
	environment.environment.sky.sky_material.set("sky_horizon_color", sky_horizon_color.sample(time))
	environment.environment.sky.sky_material.set("ground_bottom_color", sky_top_color.sample(time))
	environment.environment.sky.sky_material.set("ground_horizon_color", sky_horizon_color.sample(time))
