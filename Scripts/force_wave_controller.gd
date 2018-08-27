extends "res://Scripts/network_controller.gd"

# Wave variables control algorithm with wave filtering
# Please refer to section 7 of 2004 paper by Niemeyer and Slotline for more details

var wave_impedance = 1.0

sync func set_wave_impedance( value ):
	if value > 0.1: wave_impedance = value

# Receive delayed u_in (u_in_old) and U_in (U_in_old)
func process_input_wave( wave, wave_integral ): 	
	# Extract remote force from wave variable: F_in = sqrt( 2 * b ) * u_in - b * xdot_out
	var remote_force = sqrt( 2 * wave_impedance ) * wave - wave_impedance * linear_velocity
	# Extract remote momentum from wave integral: p_in = sqrt( 2 * b ) * U_in - b * x_out
	var remote_momentum = sqrt( 2 * wave_impedance ) * wave_integral - wave_impedance * translation
	
	var momentum = mass * linear_velocity
	print( "momentum: remote={0}, actual={1}".format( [ remote_momentum, momentum ] ) )  
	#remote_force += ( remote_momentum - momentum )
	# Send F_out and p_out
	return [ remote_force, remote_momentum ]

# Send u_out and U_out
func process_output_wave( force, momentum ): 
	# Encode output wave variable (velocity data): u_out = ( b * xdot_out - F_in ) / sqrt( 2 * b )
	var wave = ( wave_impedance * linear_velocity - force ) / sqrt( 2 * wave_impedance )
	# Encode output wave integral (position data): U_out = ( b * x_out - p_in ) / sqrt( 2 * b )
	var wave_integral = ( wave_impedance * translation - momentum ) / sqrt( 2 * wave_impedance )
	# Send u_out and U_out
	return [ wave, wave_integral ]

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

master func update_player( wave, wave_integral, last_client_time, server_time ):
	# Extract remote force from wave variable: F_s = -b * xdot_s + sqrt( 2 * b ) * u_s
	# Extract remote moment from received wave integral: p_m = -b * x_s + sqrt( 2 * b ) * U_s
	var remote_force = process_input_wave( wave, wave_integral )
	
	var delay = ( OS.get_system_time_secs() - last_client_time ) / 2
	#remote_force[ 0 ] = filter_delayed_input( remote_force[ 0 ], delay )
	# Read scaled player position (x_s) and velocity (xdot_s)
	var player_force = InputAxis.get_value() #* rangeLimits.z;
	remote_force[ 0 ] += Vector3.FORWARD * player_force
	# Apply resulting force to user device
	add_central_force( remote_force[ 0 ] )
	#float feedbackScalingFactor = 1.0f;//0.005f;// controlAxis.GetValue( AxisVariable.INERTIA ) / body.mass;
	#controlAxis.SetValue( AxisVariable.FORCE, transform.forward.z * remoteForce * feedbackScalingFactor );
	# Encode and send output wave variable (velocity data): v_s = ( b * xdot_s - F_s ) / sqrt( 2 * b )
	# Encode and send output wave integral (position data): V_s = ( b * x_s - p_s ) / sqrt( 2 * b )
	var output_wave = process_output_wave( remote_force[ 0 ], remote_force[ 1 ] )
	rpc_unreliable( "update_server", output_wave[ 0 ], output_wave[ 1 ], wave_impedance )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var tracking_error = master_position - translation
	print( "master: pos={0}, vel={1}, err={2}".format( [ master_position, master_velocity, tracking_error ] ) )
	master_velocity += tracking_error;
	linear_velocity = master_velocity;
	angular_velocity = linear_velocity.rotated( Vector3.UP, 90 ) / $Collider.shape.margin / 2