extends "res://Scripts/force_controller.gd"

# Wave variables control algorithm with wave filtering
# Please refer to section 7 of 2004 paper by Niemeyer and Slotline for more details
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
	#GameManager.GetConnection().SetLocalValue( (byte) elementID, Z, IMPEDANCE, waveImpedance );
	#GameManager.GetConnection().SetLocalValue( (byte) elementID, Z, FILTER, filterStrength )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var tracking_error = master_position - translation
	
	print( "master: pos={0}, vel={1}, err={2}".format( [ master_position, master_velocity, tracking_error ] ) )
	
	master_velocity += tracking_error;
	linear_velocity = master_velocity;
	
	angular_velocity = linear_velocity.rotated( Vector3.UP, 90 ) / $Collider.shape.margin / 2