extends Trees

func _ready():
	pass

func die():
	$TreeShape.disabled = true
	#remove_child($TreeShape)
	$StumpShape.disabled = false
	$FullTree.visible = false
	#remove_child($FullTree)
	$stump.visible = true
	
	#print(self.name)
	
	#call inherited function
	super.die()
