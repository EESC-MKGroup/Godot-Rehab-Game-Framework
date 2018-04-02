extends Area

export var angular_speed = 2

var explosion = preload( "res://Actors/Explosion.tscn" )

var rotation_axis = Vector3( rand_range( -1, 1 ), rand_range( -1, 1 ), rand_range( -1, 1 ) )

func set_object( object_name ):
	$MeshInstance.mesh = load( "res://Meshes/" + object_name + ".obj" )
	var material = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = load( "res://Textures/" + object_name + "_diffuse.png" )
	material.normal_texture = load( "res://Textures/" + object_name + "_normal.png" )
	$MeshInstance.set_surface_material( 0, material )

func _physics_process( delta ):
	rotate( rotation_axis.normalized(), angular_speed * delta )

func _on_body_entered( body ):
	var destroy_explosion = explosion.instance()
	destroy_explosion.translation = translation
	get_parent().add_child( destroy_explosion )
	queue_free()

func get_width():
	return 2 * $CollisionShape.shape.radius