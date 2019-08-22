extends "res://Scripts/network_controller.gd"

onready var game = get_tree().get_root()

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var position_observer = kalman_filter.new()
onready var force_observer = kalman_filter.new()

var feedback_force = Vector3.ZERO
var external_force = Vector3.ZERO setget _set_external_force

var local_position = Vector3.ZERO setget _set_local_position
var local_velocity = Vector3.ZERO setget _set_local_velocity

var position_state = [ Vector3.ZERO, Vector3.ZERO, Vector3.ZERO ]
var force_state = [ Vector3.ZERO, Vector3.ZERO, Vector3.ZERO ]

func _set_external_force( value ):
	external_force = value

func _set_local_position( value ):
	local_position = value

func _set_local_velocity( value ):
	local_velocity = value

func enable():
	.enable()
	rpc( "update_server", local_position, local_velocity, external_force, OS.get_ticks_msec(), OS.get_ticks_msec() )

func predict_input_signal( remote_position, remote_velocity, remote_force, time_delay ): 	
	time_delay = int( time_delay / get_physics_process_delta_time() ) * get_physics_process_delta_time()
	force_state = force_observer.predict()
	force_state = force_observer.update( [ remote_force, force_state[ 1 ], force_state[ 2 ] ], force_state )
	remote_force = force_state[ 0 ] + force_state[ 1 ] * time_delay + force_state[ 2 ] * 0.5 * time_delay * time_delay
	position_state[ 0 ] = remote_position + remote_velocity * time_delay
	position_state[ 1 ] = remote_velocity
	position_state = position_observer.process( position_state, remote_force )
	
	return [ position_state, remote_force ]

remote func update_server( remote_position, remote_velocity, remote_force, last_server_time, client_time ):
	var time_delay = ( OS.get_ticks_msec() - last_server_time ) / 1000
	var remote_state = predict_input_signal( remote_position, remote_velocity, remote_force, time_delay )
	remote_position = remote_state[ 0 ]
	remote_force = remote_state[ 1 ]
	
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_player", local_position, local_velocity, external_force, client_time, server_time )
	# Send position and velocity values directly
	rpc_unreliable( "update_slave", local_position, local_velocity, client_time, server_time )

master func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time ):
	var time_delay = ( OS.get_ticks_msec() - last_client_time ) / 1000
	var remote_state = predict_input_signal( remote_position, remote_velocity, remote_force, time_delay )
	remote_position = remote_state[ 0 ]
	remote_force = remote_state[ 1 ]
	
	var client_time = OS.get_ticks_msec()
	rpc_unreliable( "update_server", local_position, local_velocity, external_force, server_time, client_time )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var delay = ( OS.get_ticks_msec() - last_client_time ) / 2000
	print( "delay= " + str(delay) )
	var tracking_error = master_position + master_velocity * delay - translation
	print( "master: pos={0}, vel={1}, err={2}".format( [ master_position, master_velocity, tracking_error ] ) )
	master_velocity = filter_delayed_input( master_velocity, tracking_error, last_client_time )
	linear_velocity = master_velocity
	angular_velocity = linear_velocity.rotated( Vector3.UP, 90 ) / $Collider.shape.margin / 2