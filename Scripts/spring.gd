extends MeshInstance

export(float, 0.0, 20.0) var stiffness = 10.0
export(float, 0.0, 5.0) var damping = 0.0

#export(NodePath) var body_1
#export(NodePath) var body_2

onready var body_1 = $"../Box1"
onready var body_2 = $"../Box2"

onready var initial_length = _get_length()
onready var initial_scale = scale

func _get_length():
	return ( body_1.translation - body_2.translation ).length()

func _get_relative_velocity():
	return body_1.linear_velocity.length() - body_2.linear_velocity.length()

func _process( delta ):
	var relative_length = _get_length() / initial_length
	scale.z = initial_scale.z * relative_length

func get_force():
	return stiffness * ( _get_length() - initial_length ) + damping * _get_relative_velocity()