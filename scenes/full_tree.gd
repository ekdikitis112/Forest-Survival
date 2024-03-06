extends Trees

func _ready():
	pass

func die():
	$TreeShape.disabled = true
	$StumpShape.disabled = false
	$FullTree.visible = false
	$stump.visible = true
	
	#call inherited function
	super.die()
