extends MeshInstance

onready var initial_scale = scale

func _process( delta ):
	var vector_input = get_parent().external_force
	scale.z = vector_input.length() * initial_scale.z
