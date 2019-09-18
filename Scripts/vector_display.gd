extends MeshInstance

onready var initial_scale = scale

func update( vector_input ):
	scale = vector_input.length() * initial_scale
