extends Node3D

@onready var player = $player
@onready var inventory_interface = $UI/InventoryInterface

func _ready():
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)

func toggle_inventory_interface():
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
