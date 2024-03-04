extends "res://scenes/Tree.gd"

func _ready():
	pass

func die():
	$TreeShape.disabled = true
	$StumpShape.disabled = false
	$FullTree.visible = true
	$stump.visible = true
	
	#call inherited function
	super.die()
