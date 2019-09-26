extends RigidBody

const BANDWIDTH = 0.5

onready var initial_position = translation

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
	rpc( "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec() )

func update_remote():
	if get_tree().get_network_unique_id() == 1 or get_tree().get_network_unique_id() != get_network_master(): return
	rpc_unreliable_id( 1, "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec() )

remotesync func reset():
	target_position = initial_position
	target_velocity = Vector3.ZERO
	was_reset = true

remote func update_server( remote_position, remote_velocity, remote_force, client_time ):
	if get_tree().get_network_unique_id() != 1: return
	var server_time = OS.get_ticks_msec()
	# Send position and velocity values directly
	for peer_id in get_tree().get_network_connected_peers():
		if peer_id == get_network_master():
			rpc_unreliable_id( peer_id, "update_player", local_position, local_velocity, external_force, client_time, server_time )
		elif peer_id != 1:
			rpc_unreliable_id( peer_id, "update_player", local_position, local_velocity, external_force, client_time, server_time )
			#rpc_unreliable_id( peer_id, "update_puppet", local_position, local_velocity, client_time, server_time )
	print( "update server: p=%.3f, pd=%.3f, v=%.3f, vd=%.3f, ef=%.3f, ff=%.3f, rf=%.3f" % [ local_position.z, target_position.z, local_velocity.z, target_velocity.z, external_force.z, feedback_force.z, remote_force.z ] )

remote func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time=0.0 ):
	var client_time = OS.get_ticks_msec()
#	rpc_unreliable( "update_server", local_position, local_velocity, external_force, server_time, client_time )
	print( "update player: p=%.3f, pd=%.3f, v=%.3f, vd=%.3f, ef=%.3f, ff=%.3f, rf=%.3f" % [ local_position.z, target_position.z, local_velocity.z, target_velocity.z, external_force.z, feedback_force.z, remote_force.z ] )

#puppet func update_puppet( master_position, master_velocity, last_client_time, server_time ):
#	print( "called update puppet on ", get_tree().get_network_unique_id(), " (master:", get_network_master(), ")" )
#	if get_tree().get_network_unique_id() == 1: return
#	var time_delay = calculate_delay( last_client_time )
#	var last_target_velocity = target_velocity
#	target_position = master_position + master_velocity * time_delay
#	target_velocity = ( target_position - local_position ) / get_physics_process_delta_time()
#	target_velocity = _filter_signal( local_velocity, target_velocity, last_target_velocity )
#	target_position = local_position
#	feedback_force = mass * ( target_velocity - local_velocity ) / get_physics_process_delta_time()
#	#was_reset = true

remote func update_puppet( master_position, master_velocity, last_client_time, server_time ):
	if get_tree().get_network_unique_id() == 1: return
	target_position = master_position
	target_velocity = master_velocity
	var position_error = target_position - local_position
	var velocity_error = target_velocity - local_velocity
	feedback_force = 2.0 * position_error + 1.0 * velocity_error
	print( "update puppet: p=%.3f, pd=%.3f, v=%.3f, vd=%.3f, ef=%.3f, ff=%.3f" % [ local_position.z, target_position.z, local_velocity.z, target_velocity.z, external_force.z, feedback_force.z ] )
	# s = s0 + v0t + at²/2 -> a = 2 ( s - s0 - v0t ) / t² 

func set_system( inertia, damping, stiffness ):
	pass

func _filter_signal( last_filtered_value, input_value, last_input_value ):
	return ( ( 2 - BANDWIDTH ) * last_filtered_value + BANDWIDTH * ( input_value + last_input_value ) ) / ( 2 + BANDWIDTH )

# Half round-trip time calculation
func calculate_delay( dispatch_time_ms ):
	 return ( OS.get_ticks_msec() - dispatch_time_ms ) / 2000