extends RigidBody

const BANDWIDTH = 0.5

onready var initial_position = translation

var server_dispatch_time = OS.get_ticks_msec()

var feedback_force = Vector3.ZERO setget ,_get_feedback_force
var external_force = Vector3.ZERO setget _set_external_force

var local_position = Vector3.ZERO setget ,_get_local_position
var local_velocity = Vector3.ZERO setget ,_get_local_velocity

var target_position = Vector3.ZERO setget ,_get_target_position
var target_velocity = Vector3.ZERO setget ,_get_target_velocity

var was_reset = false

func _get_feedback_force(): return transform.basis.xform_inv( feedback_force )
func _set_external_force( value ): external_force = transform.basis.xform( value )
func _get_local_position(): return transform.basis.xform_inv( local_position )
func _get_local_velocity(): return transform.basis.xform_inv( local_velocity )
func _get_target_position(): return transform.basis.xform_inv( target_position )
func _get_target_velocity(): return transform.basis.xform_inv( target_velocity )

func enable():
	rpc( "reset" )
	server_dispatch_time = OS.get_ticks_msec()

func update_remote():
	if get_tree().get_network_unique_id() != get_network_master(): return
	rpc_unreliable( "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec(), server_dispatch_time )

remotesync func reset():
	target_position = initial_position
	target_velocity = Vector3.ZERO
	was_reset = true

remote func update_server( remote_position, remote_velocity, remote_force, client_time, last_server_time=0.0 ):
	if get_tree().get_network_unique_id() != 1: return
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_client", local_position, local_velocity, external_force, client_time, server_time )
	print( "update server: p=%.3f, pd=%.3f, v=%.3f, vd=%.3f, ef=%.3f, ff=%.3f, rf=%.3f" % [ local_position.z, target_position.z, local_velocity.z, target_velocity.z, external_force.z, feedback_force.z, remote_force.z ] )

remote func update_client( remote_position, remote_velocity, remote_force, server_time, last_client_time=0.0 ):
	server_dispatch_time = server_time
	print( "update client: p=%.3f, pd=%.3f, v=%.3f, vd=%.3f, ef=%.3f, ff=%.3f, rf=%.3f" % [ local_position.z, target_position.z, local_velocity.z, target_velocity.z, external_force.z, feedback_force.z, remote_force.z ] )

func set_system( inertia, damping, stiffness ):
	pass

func _filter_signal( last_filtered_value, input_value, last_input_value ):
	return ( ( 2 - BANDWIDTH ) * last_filtered_value + BANDWIDTH * ( input_value + last_input_value ) ) / ( 2 + BANDWIDTH )

# Half round-trip time calculation
func calculate_delay( dispatch_time_ms ):
	 return ( OS.get_ticks_msec() - dispatch_time_ms ) / 2000