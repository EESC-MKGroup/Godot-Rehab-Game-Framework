extends MeshInstance

onready var initial_scale = scale

func update( vector_input ):
	scale.z = vector_input.length() * initial_scale.z
