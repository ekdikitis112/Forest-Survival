extends Node3D

const PickUp = preload("res://item/pick_up/pick_up.tscn")


@onready var player = $player
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

@export var chunkSize = 400
@export var terrain_height = 20
@export var view_distance = 4000
@export var player_viewer : CharacterBody3D
@export var chunk_mesh_scene : PackedScene
var player_position = Vector2()
var terrain_chunks = {}
var chunksvisible = 0
var last_visible_chunks = []

@export var noise: FastNoiseLite

func _ready():
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
	
	# chunk system
	noise.seed = Globals.game_seed
	chunksvisible = roundi(view_distance/chunkSize)
	#set_wireframe()
	updateVisibleChunk()

func _process(delta):
	player_position.x = player_viewer.global_position.x
	player_position.y = player_viewer.global_position.z
	updateVisibleChunk()

func updateVisibleChunk():
	for chunk in last_visible_chunks:
		chunk.setChunkVisible(false)
	last_visible_chunks.clear()
	
	var currentX = roundi(player_position.x/chunkSize)
	var currentY = roundi(player_position.y/chunkSize)
	
	for yOffset in range(-chunksvisible,chunksvisible):
		for xOffset in range(-chunksvisible,chunksvisible):
			var view_chunk_coord = Vector2(currentX-xOffset,currentY-yOffset)
			if terrain_chunks.has(view_chunk_coord):
				terrain_chunks[view_chunk_coord].update_chunk(player_position,view_distance)
				if terrain_chunks[view_chunk_coord].update_lod(player_position):
					terrain_chunks[view_chunk_coord].generate_terrain(noise,view_chunk_coord,chunkSize,true)
				if terrain_chunks[view_chunk_coord].getChunkVisible():
					last_visible_chunks.append(terrain_chunks[view_chunk_coord])
			else:
				var chunk: TerrainChunk = chunk_mesh_scene.instantiate()
				add_child(chunk)
				chunk.Terrain_Max_Height = terrain_height
				var pos = view_chunk_coord * chunkSize
				var world_position = Vector3(pos.x,0,pos.y)
				chunk.global_position = world_position
				chunk.generate_terrain(noise,view_chunk_coord,chunkSize,false)
				terrain_chunks[view_chunk_coord] = chunk

func set_wireframe():
	RenderingServer.set_debug_generate_wireframes(true)
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

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
	pick_up.position = player.get_drop_position()
	add_child(pick_up)
