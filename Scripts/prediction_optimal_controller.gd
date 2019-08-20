extends "res://Scripts/network_controller.gd"

onready var game = get_tree().get_root()

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var position_observer = kalman_filter.new()
onready var force_observer = kalman_filter.new()

var external_force = Vector3.ZERO setget _set_external_force

func _set_external_force( value ):
	external_force = value

func predict_input_signal( remote_position, remote_force, time_delay ): 	
	time_delay = int( time_delay / get_physics_process_delta_time() ) * get_physics_process_delta_time()
	remote_position[ 0 ] += remote_position[ 1 ] * time_delay + remote_position[ 2 ] * 0.5 * time_delay * time_delay
	remote_position[ 1 ] += remote_position[ 2 ] * time_delay
	remote_position = position_observer.process( remote_position )
	var force_state = force_observer.predict()
	force_state = self.remoteInputObserver.Update( [ remote_force, 0.0, 0.0 ], force_state )
	remote_force = force_state[ 0 ] + force_state[ 1 ] * time_delay + force_state[ 2 ] * 0.5 * time_delay * time_delay
	
	return [ remote_position, remote_force ]

remote func update_server( remote_position, remote_force, last_server_time, client_time ):
	var time_delay = ( OS.get_ticks_msec() - last_server_time ) / 1000
	var remote_state = predict_input_signal( remote_position, remote_force, time_delay )
	remote_position = remote_state[ 0 ]
	remote_force = remote_state[ 1 ]
	# Apply resulting force F_m to rigid body
	add_central_force( remote_force + game.get_environment_force( self ) )
	
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_player", translation, external_force, client_time, server_time )
	# Send position and velocity values directly
	rpc_unreliable( "update_slave", translation, linear_velocity, client_time, server_time )

master func update_player( remote_position, remote_force, last_client_time, server_time ):
	var time_delay = ( OS.get_ticks_msec() - last_client_time ) / 1000
	var remote_state = predict_input_signal( remote_position, remote_force, time_delay )
	remote_position = remote_state[ 0 ]
	remote_force = remote_state[ 1 ]
	# Apply player input force F_h to rigid body
	add_central_force( remote_force[ 0 ] + game.get_player_force( self ) )
	
	var client_time = OS.get_ticks_msec()
	rpc_unreliable( "update_server", translation, external_force, server_time, client_time )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var delay = ( OS.get_ticks_msec() - last_client_time ) / 2000
	print( "delay= " + str(delay) )
	var tracking_error = master_position + master_velocity * delay - translation
	print( "master: pos={0}, vel={1}, err={2}".format( [ master_position, master_velocity, tracking_error ] ) )
	master_velocity = filter_delayed_input( master_velocity, tracking_error, last_client_time )
	linear_velocity = master_velocity
	angular_velocity = linear_velocity.rotated( Vector3.UP, 90 ) / $Collider.shape.margin / 2