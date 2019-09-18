extends MeshInstance

onready var initial_scale = scale

func update( new_scale ):
	scale = new_scale * initial_scale
