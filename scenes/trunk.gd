extends "res://scenes/Tree.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func die():
	$CollisionShape3D.disabled = true
	super.die()
	
	call_deferred("queue_free")


func _on_area_3d_body_entered(body):
	if !body.is_in_group("Tree") || body == self: return
	body.take_damage(4)
