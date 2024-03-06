extends RigidBody3D

@export var slot_data: SlotData
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_area_3d_body_entered(body):
	if body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
