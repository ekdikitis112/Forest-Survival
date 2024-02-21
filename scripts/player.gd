extends CharacterBody3D

# signal to toggle inventory

signal toggle_inventory()

# player inventory

@export var inventory_data : InventoryData

# interact ray to know what you are looking at and interacting with

@onready var interact_ray = $neck/head/InteractRay


# Player nodes

@onready var eyes = $neck/head/eyes
@onready var camera_3d = $neck/head/eyes/Camera3D
@onready var neck = $neck
@onready var head = $neck/head
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var animation_player = $neck/head/eyes/AnimationPlayer

# Speed

var current_speed = 10.0

@export var walking_speed = 8.0
@export var sprinting_speed = 12.0
@export var crouching_speed = 4.0

# States

var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# Slide

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

# Head Bobbing
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# Movement

const jump_velocity = 4.5

var crouching_depth = -0.5

var lerp_speed = 10.0

var air_lerp_speed = 3.0

var free_look_tilt_amount = 5

var last_velocity = Vector3.ZERO

# Input

const mouse_sensitivity = 0.25

var direction = Vector3.ZERO


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	
	# interact with objects in the world
	if  Input.is_action_just_pressed("interact"):
		interact()
	
	# open and close inventory
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
	
	# Mouse looking logic
	
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-80),deg_to_rad(80))

func _physics_process(delta):
	# Get movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	#Handling movement state
	
	# Crouching
	if Input.is_action_pressed("crouch") || sliding:
		current_speed = lerp(current_speed,crouching_speed,delta*lerp_speed)
		head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		# Slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
		
		walking = false
		sprinting = false
		crouching = true
	elif !ray_cast_3d.is_colliding():
		
		# Standing
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = lerp(current_speed,sprinting_speed,delta*lerp_speed)
			
			walking = false
			sprinting = true
			crouching = false
		else:
			# Walking
			current_speed = lerp(current_speed,walking_speed,delta*lerp_speed)
			
			walking = true
			sprinting = false
			crouching = false

	# Handle free looking
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		eyes.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt_amount)
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(7.0),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		eyes.rotation.z =  lerp(eyes.rotation.y,0.0,delta*lerp_speed)
	
	# Handle sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
	
	# Hande headbob
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed*delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed*delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed*delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
		
		eyes.position.y = lerp(eyes.position.y,head_bobbing_vector.y*(head_bobbing_current_intensity/2.0),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobbing_vector.x*head_bobbing_current_intensity,delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		animation_player.play("jump")
	
	# Handle landing
	if is_on_floor():
		if last_velocity.y < -1.0:
			animation_player.play("landing")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x,0,slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	last_velocity = velocity
	move_and_slide()


func interact():
	if interact_ray.is_colliding():
		interact_ray.get_collider().player_interact()
