extends RigidBody

const BANDWIDTH = 0.5

var initial_position = Vector3.ZERO
var feedback_force = Vector3.ZERO
var external_force = Vector3.ZERO

var local_position = Vector3.ZERO
var local_velocity = Vector3.ZERO

var target_position = Vector3.ZERO
var target_velocity = Vector3.ZERO
var last_input_velocity = Vector3.ZERO

var was_reset = false

onready var game = get_tree().get_root()

sync func enable():
	rpc( "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec(), OS.get_ticks_msec() )
	was_reset = true

sync func reset():
	target_position = initial_position
	target_velocity = Vector3.ZERO
	was_reset = true

remote func update_server( remote_position, remote_velocity, remote_force, last_server_time, client_time=0.0 ):
	external_force = game.get_environment_force( self )
	
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_player", local_position, local_velocity, external_force, client_time, server_time )
	# Send position and velocity values directly
	rpc_unreliable( "update_slave", local_position, local_velocity, client_time, server_time )

master func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time=0.0 ):
	external_force = game.get_environment_force( self ) + game.get_player_force( self )
	
	var client_time = OS.get_ticks_msec()
	rpc_unreliable( "update_server", local_position, local_velocity, external_force, server_time, client_time )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var time_delay = calculate_delay( last_client_time )
	print( "delay= " + str(time_delay) )
	target_position = master_position + master_velocity * time_delay
	var input_velocity = master_velocity + ( target_position - local_position )
	print( "master: pos={0}, vel={1}, err={2}".format( [ master_position, master_velocity, tracking_error ] ) )
	target_position = local_position
	target_velocity = _filter_signal( target_velocity, input_velocity, last_input_velocity )
	last_input_velocity = input_velocity
	was_reset = true

func set_system( inertia, damping, stiffness ):
	pass

func _filter_signal( last_filterd_value, input_value, last_input_value ):
	return ( ( 2 - BANDWIDTH ) * last_filterd_value + BANDWIDTH * ( input_value + last_input_value ) ) / ( 2 + BANDWIDTH )

# Half round-trip time calculation
func calculate_delay( dispatch_time_ms ):
	 return ( OS.get_ticks_msec() - dispatch_time_ms ) / 2000