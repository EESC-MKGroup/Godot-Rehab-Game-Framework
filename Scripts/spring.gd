extends MeshInstance

export(float, 0.0, 20.0) var stiffness = 10.0

export(NodePath) var connector_1 = null
export(NodePath) var connector_2 = null

onready var initial_length = _get_length()
onready var initial_scale = scale

func _get_length():
	return abs( connector_1.translation.z - connector_2.translation.z )

func _process( delta ):
	print( get_owner().get_name() )
	var relative_length = _get_length() / initial_length
	scale.z = initial_scale.z * relative_length
	var spring_force = stiffness * ( _get_length() - initial_length )

func get_force():
	return stiffness * ( _get_length() - initial_length )