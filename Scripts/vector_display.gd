extends MeshInstance

onready var initial_scale = scale
onready var initial_rotation = rotation

func update( vector ):
	print( initial_scale )
	scale = vector.length() * initial_scale
	look_at( global_transform.origin + vector, Vector3.DOWN )
	#var reference_vector = get_parent().transform.basis * Vector3.BACK
	#var angle = reference_vector.angle_to( vector )
	#rotation = initial_rotation + get_parent().transform.basis * Vector3.UP * angle
	#print( vector, reference_vector, angle, rotation )