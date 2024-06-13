extends Node3D

const PickUp = preload("res://item/pick_up/pick_up.tscn")

@onready var player = $player
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

@export var chunkSize = 400
@export var terrain_height = 40
@export var view_distance = 1000
@export var viewer: CharacterBody3D
@export var chunk_mesh_scene: PackedScene

var viewer_position = Vector2()
var terrain_chunks = {}
var chunksvisible = 0

@export var thread_count = 10
@export var render_wireframe = false

var threads = []
var active_threads = 0
var last_visible_chunks = []


var Chunks: Node3D = Node3D.new()

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var pause_menu = load("res://scenes/pause_menu.tscn").instance()
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
	
	
	for i in range(thread_count):
		threads.append(Thread.new())
	
	chunksvisible = roundi(view_distance / chunkSize)
	RenderingServer.set_debug_generate_wireframes(true)
	set_wireframe(render_wireframe)
	updateVisibleChunk()

func _process(_delta):
	set_wireframe(render_wireframe)
	viewer_position.x = viewer.global_position.x
	viewer_position.y = viewer.global_position.z
	updateVisibleChunk()
	
	for chunk in last_visible_chunks:
		if not chunk.getChunkVisible():
			chunk.free()


func updateVisibleChunk():
	for chunk in last_visible_chunks:
		chunk.setChunkVisible(false)
	
	last_visible_chunks.clear()
	
	var currentX = roundi(viewer_position.x / chunkSize)
	var currentY = roundi(viewer_position.y / chunkSize)
	
	for yOffset in range(-chunksvisible, chunksvisible):
		for xOffset in range(-chunksvisible, chunksvisible):
			var view_chunk_coord = Vector2(currentX - xOffset, currentY - yOffset)
			
			if terrain_chunks.has(view_chunk_coord):
				var chunk = terrain_chunks[view_chunk_coord]
				chunk.update_chunk(viewer_position, view_distance)
				
				if chunk.update_lod(viewer_position):
					chunk.generate_terrain( view_chunk_coord, chunkSize, false)
				
				if chunk.getChunkVisible():
					last_visible_chunks.append(chunk)
			else:
				var chunk = chunk_mesh_scene.instantiate()
				Chunks.add_child(chunk)
				
				chunk.Terrain_Max_Height = terrain_height
				
				var pos = view_chunk_coord * chunkSize
				chunk.global_transform.origin = Vector3(pos.x, 0, pos.y)
				
				terrain_chunks[view_chunk_coord] = chunk
				
				for thread in threads:
					if not thread.is_started():
						thread.start(chunk.generate_terrain.bind(chunk, view_chunk_coord, chunkSize, true))
						break

func _exit_tree():
	for thread in threads:
		if thread.is_alive():
			thread.wait_to_finish()

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
	var pick_up = PickUp.instance()
	pick_up.slot_data = slot_data
	pick_up.global_transform.origin = player.get_drop_position() + Vector3(1, 0, 1)
	add_child(pick_up)


func set_wireframe(draw_wireframe: bool):
	if draw_wireframe:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	else:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED

func get_active_threads():
	active_threads = 0
	for thread in threads:
		if thread.is_alive():
			active_threads += 1
	return active_threads
