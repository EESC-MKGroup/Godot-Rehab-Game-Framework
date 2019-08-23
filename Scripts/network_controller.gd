extends RigidBody

const LAMBDA = 0.5

var initial_position = Vector3.ZERO
var feedback_force = Vector3.ZERO
var external_force = Vector3.ZERO setget _set_external_force

var local_position = Vector3.ZERO
var local_velocity = Vector3.ZERO

var last_filtered_velocity = Vector3.ZERO
var last_input_velocity = Vector3.ZERO

var was_reset = false

func _set_external_force( value ):
	external_force = value

sync func enable():
	rpc( "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec(), OS.get_ticks_msec() )
	was_reset = true

sync func reset():
	local_position = initial_position
	local_velocity = Vector3.ZERO
	was_reset = false

remote func update_server( remote_position, remote_velocity, remote_force, last_server_time, client_time ):
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_player", local_position, local_velocity, external_force, client_time, server_time )
	# Send position and velocity values directly
	rpc_unreliable( "update_slave", local_position, local_velocity, client_time, server_time )

master func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time ):
	var client_time = OS.get_ticks_msec()
	rpc_unreliable( "update_server", local_position, local_velocity, external_force, server_time, client_time )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var delay = calculate_delay( last_client_time )
	master_position += master_velocity * delay
	local_velocity = filter_tracking_velocity( master_velocity, master_position, local_position )

# Half round-trip time calculation
func calculate_delay( dispatch_time_ms ):
	 return ( OS.get_ticks_msec() - dispatch_time_ms ) / 2000

func filter_tracking_velocity( input_velocity, tracked_position, current_position ):
	input_velocity += ( tracked_position - current_position )
	# Filter delayed input to ensure stability: x_out / x_in = l / ( s + l ) => discrete form (s = 2/T * (z-1)/(z+1))
	# x_out = ( (2-lambda) * x_out_old + lambda * (x_in+u_in_old) ) / (2+lambda), where lambda is fiter's bandwidth
	var result = ( ( 2 - LAMBDA ) * last_filtered_velocity + LAMBDA * ( input_velocity + last_input_velocity ) ) / ( 2 + LAMBDA )
	last_filtered_velocity = result
	last_input_velocity = input_velocity
	
	return result