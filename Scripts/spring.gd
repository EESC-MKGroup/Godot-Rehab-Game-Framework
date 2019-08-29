extends MeshInstance

export(float, 0.0, 20.0) var stiffness = 10.0

#export(NodePath) var connector_1
#export(NodePath) var connector_2

onready var connector_1 = $"../Box1/Connector"
onready var connector_2 = $"../Box2/Connector"

onready var initial_length = _get_length()
onready var initial_scale = scale

func _get_length():
	var connector_position_1 = connector_1.global_transform.origin
	var connector_position_2 = connector_2.global_transform.origin
	return abs( connector_position_1.z - connector_position_2.z )

func _process( delta ):
	var relative_length = _get_length() / initial_length
	scale.z = initial_scale.z * relative_length
	var spring_force = stiffness * ( _get_length() - initial_length )

func get_force():
	return stiffness * ( _get_length() - initial_length )