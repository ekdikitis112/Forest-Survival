extends  Node3D

var axe_damage = 1
var can_chop = false

func chop():
	$AnimationPlayer.play("chop")

func set_can_chop(val):
	can_chop = val


func _on_body_entered(body):
	if !body.is_in_group("Tree") || !can_chop: return
	body.take_damage(axe_damage)
	$Hit.pitch_scale = randf_range(0.8,1.2)
	$Hit.play()
