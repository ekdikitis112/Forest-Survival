extends Node3D

const PickUp = preload("res://item/pick_up/pick_up.tscn")


@onready var player = $player
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

###
#Threaded version of terrain generation
#WARNING Threading is bad with generating collisions
###

@export var chunkSize = 400
@export var terrain_height = 40
@export var view_distance = 1000
@export var viewer :CharacterBody3D
@export var chunk_mesh_scene : PackedScene
var viewer_position = Vector2()
var terrain_chunks = {}
var chunksvisible=0
@export var thread_count = 10
@export var render_wireframe = false
#array of threads to generate terrain
var threads = []
var active_threads = 0
var last_visible_chunks = []
@export var noise:FastNoiseLite

var Chunks:Node3D = Node3D.new()
var Trees:Node3D = Node3D.new()

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var pause_menu = load("res://scenes/pause_menu.tscn").instantiate()
		add_child(pause_menu)
		get_tree().paused = true


func _ready():
	Chunks.name = "Chunks"
	add_child(Chunks)
	
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
	
	noise.seed = Globals.game_seed.seed
	#create threads and add to array
	for i in thread_count:
		threads.append(Thread.new())
	#set the total chunks to be visible
	chunksvisible = roundi(view_distance/chunkSize)
	RenderingServer.set_debug_generate_wireframes(true)
	set_wireframe(render_wireframe)
	updateVisibleChunk()

func _process(delta):
	set_wireframe(render_wireframe)
	viewer_position.x = viewer.global_position.x
	viewer_position.y = viewer.global_position.z
	updateVisibleChunk()
	for chunk in last_visible_chunks:
		if not chunk.getChunkVisible():
			get_node(chunk).free()

func set_wireframe(draw_wireframe:bool):
	if draw_wireframe:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	else:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED

func updateVisibleChunk():
	#hide chunks that were are out of view
	for chunk in last_visible_chunks:
		chunk.setChunkVisible(false)
	
	last_visible_chunks.clear()
	#get grid position
	var currentX = roundi(viewer_position.x/chunkSize)
	var currentY = roundi(viewer_position.y/chunkSize)
	#get all the chunks within visiblity range
	for yOffset in range(-chunksvisible,chunksvisible):
		for xOffset in range(-chunksvisible,chunksvisible):
			#create a new chunk coordinate 
			var view_chunk_coord = Vector2(currentX-xOffset,currentY-yOffset)
			#check if chunk was already created
			if terrain_chunks.has(view_chunk_coord):
				#if chunk exist update the chunk passing viewer_position and view_distance
				terrain_chunks[view_chunk_coord].update_chunk(viewer_position,view_distance)
				
				if terrain_chunks[view_chunk_coord].update_lod(viewer_position):
					terrain_chunks[view_chunk_coord].generate_terrain(noise,view_chunk_coord,chunkSize,false)
				#if chunk is visible add it to last visible chunks
				if terrain_chunks[view_chunk_coord].getChunkVisible():
					last_visible_chunks.append(terrain_chunks[view_chunk_coord])
			else:
				
				#if chunk doesnt exist, create chunk
				var chunk := chunk_mesh_scene.instantiate()
				Chunks.add_child(chunk)
				
				#set chunk parameters
				chunk.Terrain_Max_Height = terrain_height
				#set chunk world position
				var pos = view_chunk_coord*chunkSize
				var world_position = Vector3(pos.x,0,pos.y)
				chunk.global_position = world_position
				terrain_chunks[view_chunk_coord] = chunk
				
				#use array of threads to generate chunk mesh
				#loop through all threads
				for thread in threads:
					#if thread is not started
					#use it to start generating the chunk
					#then break out of loop to prevent using other inactive threads
					if thread.is_started() == false:
						thread.start(chunk.generate_terrain.bind(thread,noise,view_chunk_coord,chunkSize,true,thread))
						break


#clear all the threads before exiting
func _exit_tree():
	for thread in threads:
		if thread.is_alive():
			thread.wait_to_finish()

func get_active_threads():
	active_threads = 0
	for i in threads:
		if i.is_alive():
			active_threads += 1
	return active_threads

func toggle_inventory_interface(external_inventory_owner = null):
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		hot_bar_inventory.hide() 
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		hot_bar_inventory.show()
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()

func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_drop_position()+Vector3(1,0,1)
	add_child(pick_up)
