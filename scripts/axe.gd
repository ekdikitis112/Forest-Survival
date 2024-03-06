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
	$Hit.play()

func _physics_process(delta):
	position = get_parent().position + Vector3(1,-1,-0.8)
