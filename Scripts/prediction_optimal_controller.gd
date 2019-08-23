extends "res://Scripts/network_controller.gd"

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var position_observer = kalman_filter.new()
onready var force_observer = kalman_filter.new()

var position_state = [ Vector3.ZERO, Vector3.ZERO, Vector3.ZERO ]
var force_state = [ Vector3.ZERO, Vector3.ZERO, Vector3.ZERO ]

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
	var time_delay = calculate_delay( last_server_time )
	var remote_state = predict_input_signal( remote_position, remote_velocity, remote_force, time_delay )
	remote_position = remote_state[ 0 ]
	remote_force = remote_state[ 1 ]
	
	.update_server( remote_position, remote_velocity, remote_force, last_server_time, client_time )

master func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time ):
	var time_delay = calculate_delay( last_client_time )
	var remote_state = predict_input_signal( remote_position, remote_velocity, remote_force, time_delay )
	remote_position = remote_state[ 0 ]
	remote_force = remote_state[ 1 ]
	
	.update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var time_delay = calculate_delay( last_client_time )