extends "res://Scripts/network_controller.gd"

# Wave variables control algorithm with wave filtering
# Please refer to section 7 of 2004 paper by Niemeyer and Slotline for more details

var wave_impedance = 1.0
var local_impedance = 1.0

var last_filtered_wave = Vector3.ZERO
var last_input_wave = Vector3.ZERO

# Receive delayed u_in (u_in_old) and U_in (U_in_old)
func process_input_wave( input_wave, remote_position, wave_impedance ):
	# Filter delayed input to ensure stability: x_out / x_in = l / ( s + l ) => discrete form (s = 2/T * (z-1)/(z+1))
	# x_out = ( (2-lambda) * x_out_old + lambda * (x_in+u_in_old) ) / (2+lambda), where lambda is fiter's bandwidth
	var filtered_wave = _filter_signal( last_filtered_wave, input_wave, last_input_wave )
	last_filtered_wave = filtered_wave
	last_input_wave = input_wave
	# Wave corretion based on position drift
	var position_error = local_position - remote_position
	var wave_correction = -sqrt( 2.0 * wave_impedance ) * BANDWIDTH * position_error
	if position_error.dot( filtered_wave ) < 0: wave_correction = Vector3.ZERO
	elif wave_correction.length() > filtered_wave.length(): wave_correction = -filtered_wave
	filtered_wave += wave_correction
	# Extract remote force from received wave variable: -F_in = b * xdot_out - sqrt( 2 * b ) * u_in
	return -( wave_impedance * local_velocity - sqrt( 2.0 * wave_impedance ) * filtered_wave )

# Send u_out and U_out
func process_output_wave( force, wave_impedance ): 
	# Encode output wave variable (velocity data): u_out = ( b * xdot_out + (-F_in) ) / sqrt( 2 * b )
	return ( wave_impedance * local_velocity - force ) / sqrt( 2.0 * wave_impedance )  

remote func update_server( input_wave, remote_position, remote_force, client_time, last_server_time=0.0 ):
	# Extract remote force from received wave variable: -F_m = b * xdot_m - sqrt( 2 * b ) * v_m
	feedback_force = process_input_wave( input_wave, remote_position, wave_impedance )
	# Encode and send output wave variable (velocity data): u_m = ( b * xdot_m + (-F_m) ) / sqrt( 2 * b )
	var output_wave = process_output_wave( feedback_force, wave_impedance )
	
	.update_server( output_wave, local_position, remote_force, client_time )

remote func update_client( input_wave, remote_position, remote_force, server_time, last_client_time=0.0 ):
	# Extract remote force from wave variable: F_s = -b * xdot_s + sqrt( 2 * b ) * u_s
	feedback_force = process_input_wave( input_wave, remote_position, wave_impedance )
	# Encode and send output wave variable (velocity data): v_s = ( b * xdot_s - F_s ) / sqrt( 2 * b )
	var output_wave = process_output_wave( feedback_force, wave_impedance )
	
	.update_client( output_wave, local_position, remote_force, server_time )

remote func set_impedance( remote_impedance ):
	wave_impedance = max( local_impedance, remote_impedance )

func set_system( inertia, damping, stiffness ):
	local_impedance = inertia + damping + stiffness
	if local_impedance < 1.0: local_impedance = 1.0
	rpc_unreliable( "set_impedance", local_impedance )