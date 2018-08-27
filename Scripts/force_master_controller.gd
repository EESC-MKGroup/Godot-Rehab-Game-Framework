extends "res://Scripts/force_controller.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

remote func update_server( wave, wave_integral, last_server_time, client_time ):
	# Extract remote force from received wave variable: -F_m = b * xdot_m - sqrt( 2 * b ) * v_m
	# Extract remote moment from received wave integral: -p_m = b * x_m - sqrt( 2 * b ) * V_m
	var remote_force = process_input_wave( wave, wave_integral )
	
	var delay = ( OS.get_system_time_secs() - last_server_time ) / 2
	print( "server delay=" + str(delay) )
	#remote_force[ 0 ] = filter_delayed_input( remote_force[ 0 ], delay )
	
	# Apply resulting force F_m to rigid body
	add_central_force( remote_force[ 0 ] )
	
	# Lock local body if no messages are being received
	#if( inputWaveVariable == 0.0 ) body.constraints |= RigidbodyConstraints.FreezePositionZ;
	#else body.constraints &= (~RigidbodyConstraints.FreezePositionZ);
	#if( inputWaveVariable != 0.0f ) body.constraints &= (~RigidbodyConstraints.FreezePositionZ);
	
	# Encode and send output wave variable (velocity data): u_m = ( b * xdot_m + (-F_m) ) / sqrt( 2 * b )
	# Encode and send output wave integral (position data): U_m = ( b * x_m + (-p_m) ) / sqrt( 2 * b )
	var output_wave = process_output_wave( remote_force[ 0 ], remote_force[ 1 ] )
	
	# Send position and velocity values directly
	var server_time = OS.get_system_time_secs()
	rpc_unreliable( "update_player", output_wave[ 0 ], output_wave[ 1 ], client_time, server_time )
	rpc_unreliable( "update_slave", translation, linear_velocity, client_time, server_time )