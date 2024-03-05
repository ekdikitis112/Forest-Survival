extends Node

@export var next_scene: PackedScene = preload("res://scenes/treetrunk.tscn")
@export var health: int = 4
@export var impulse_force: float = 150.0
@export var impulse_direction: Vector3 = Vector3(0.0,1.0,0.0)
@export var origin_offset: Vector3

func take_damage(damage):
	if health <= 0: return
	print("health: ",health)
	health -= damage
	print("Taken 1 damage! health: ",health)
	if health <= 0:
		die()

func die():
	print("died")
	var instance = next_scene.instantiate()
	get_parent().add_child(instance)
	instance.global_transform.origin = $SpawnPoint.global_transform.origin + origin_offset
	instance.apply_central_impulse(
		(instance.global_transform.basis * impulse_direction) * impulse_force
	)
