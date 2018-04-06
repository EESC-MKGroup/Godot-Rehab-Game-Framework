extends Area

export(float, 5) var angular_speed = 0

export(PackedScene) var destroy_effect = null

var rotation_axis = Vector3( rand_range( -1, 1 ), rand_range( -1, 1 ), rand_range( -1, 1 ) )

func set_multi_object( meshes, diffuse_maps, normal_maps ):
	var object_index = randi() % meshes.size()
	$MeshInstance.mesh = meshes[ object_index ]
	var material = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = diffuse_maps[ object_index ]
	material.normal_texture = normal_maps[ object_index ]
	$MeshInstance.set_surface_material( 0, material )

func _physics_process( delta ):
	rotate( rotation_axis.normalized(), angular_speed * delta )

func _on_body_entered( body ):
	if destroy_effect != null:
		var effect = destroy_effect.instance()
		effect.translation = translation
		get_parent().add_child( effect )
	queue_free()

func get_width():
	return 2 * $CollisionShape.shape.radius
	