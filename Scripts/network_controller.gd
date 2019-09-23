extends RigidBody

const BANDWIDTH = 0.5

onready var initial_position = translation

var feedback_force = Vector3.ZERO
var external_force = Vector3.ZERO

var local_position = Vector3.ZERO
var local_velocity = Vector3.ZERO

var target_position = Vector3.ZERO
var target_velocity = Vector3.ZERO

var was_reset = false

func enable():
	rpc( "reset" )
	rpc( "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec(), OS.get_ticks_msec() )

remotesync func reset():
	target_position = initial_position
	target_velocity = Vector3.ZERO
	was_reset = true

remote func update_server( remote_position, remote_velocity, remote_force, last_server_time, client_time=0.0 ):
	print( "called update server on ", get_tree().get_network_unique_id(), " (master:", get_network_master(), ")" )
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_player", local_position, local_velocity, external_force, client_time, server_time )
	# Send position and velocity values directly
	rpc_unreliable( "update_puppet", local_position, local_velocity, client_time, server_time )

master func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time=0.0 ):
	print( "called update player on ", get_tree().get_network_unique_id(), " (master:", get_network_master(), ")" )
	var client_time = OS.get_ticks_msec()
	rpc_unreliable( "update_server", local_position, local_velocity, external_force, server_time, client_time )

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

puppet func update_puppet( master_position, master_velocity, last_client_time, server_time ):
	if get_tree().get_network_unique_id() == 1: return
	print( "called update puppet on ", get_tree().get_network_unique_id(), " (master:", get_network_master(), ")" )
	var position_error = master_position - local_position
	var velocity_error = master_velocity - local_velocity
	feedback_force = 10.0 * position_error + 5.0 * velocity_error

func set_system( inertia, damping, stiffness ):
	pass

func _filter_signal( last_filtered_value, input_value, last_input_value ):
	return ( ( 2 - BANDWIDTH ) * last_filtered_value + BANDWIDTH * ( input_value + last_input_value ) ) / ( 2 + BANDWIDTH )

# Half round-trip time calculation
func calculate_delay( dispatch_time_ms ):
	 return ( OS.get_ticks_msec() - dispatch_time_ms ) / 2000