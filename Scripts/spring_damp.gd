extends MeshInstance

export(float, 0.0, 20.0) var stiffness = 10.0
export(float, 0.0, 5.0) var damping = 0.0

export(NodePath) var body_1
export(NodePath) var body_2

onready var initial_length = 0.0#_get_length()
onready var initial_scale = scale

var last_length = 0.0
var relative_velocity = 0.0

func _physics_process( delta ):
	var current_length = ( body_1.global_transform.origin - body_2.global_transform.origin ).length()
	if initial_length == 0.0: initial_length = current_length
	scale.y = initial_scale.y * ( current_length / initial_length )
	if last_length == 0.0: last_length = current_length
	relative_velocity = ( current_length - last_length ) / get_physics_process_delta_time()
	last_length = current_length
	global_transform.origin = ( body_1.global_transform.origin + body_2.global_transform.origin ) / 2

func get_force():
	return stiffness * ( last_length - initial_length ) + damping * relative_velocity