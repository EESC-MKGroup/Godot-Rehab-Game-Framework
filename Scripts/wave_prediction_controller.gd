extends "res://Scripts/network_controller.gd"

# Wave variables control algorithm with wave filtering
# Please refer to section 7 of 2004 paper by Niemeyer and Slotine for more details

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var wave_observer = kalman_filter.new()

var wave_impedance = 1.0
var local_impedance = 1.0

var output_wave_integral = Vector3.ZERO

var input_energy = 0.0
var output_energy = 0.0

func _ready():
	wave_observer.error_covariance_noise[ 0 ] = 4.0
	wave_observer.error_covariance_noise[ 1 ] = 2.0
	wave_observer.error_covariance_noise[ 2 ] = 1.0
	wave_observer.state_predictor[ 1 ][ 0 ] = time_step
	wave_observer.state_predictor[ 2 ][ 0 ] = pow( time_step, 2 ) / 2
	wave_observer.state_predictor[ 2 ][ 1 ] = time_step

# Receive delayed u_in (u_in_old) and U_in (U_in_old)
func process_input_wave( input_wave, input_wave_integral, input_wave_energy, time_delay ):
	# Wave corretion via Kalman filter
	time_delay = int( time_delay / time_step ) * time_step
	input_wave_integral = input_wave_integral + input_wave * time_delay
	var wave_state = wave_observer.update( [ input_wave_integral, input_wave, Vector3.ZERO ] )
	var filtered_wave = input_wave#wave_state[ 1 ]
	# Check energy balance to keep stability under variable delay
	input_energy += 0.5 * filtered_wave.dot( filtered_wave ) * time_step
	#if input_energy - input_wave_energy[ 0 ] < 0: filtered_wave = Vector3.ZERO
	
	return filtered_wave

# Send u_out and U_out
func process_output_wave( output_wave ): 
	# Integrate output wave and power signals
	output_wave_integral += output_wave * time_step
	output_energy += 0.5 * output_wave.dot( output_wave ) * time_step
	return [ output_wave_integral, Vector3( output_energy, 0, 0 ) ] 

remote func update_server( input_wave, input_wave_integral, input_wave_energy, client_time, last_server_time ):
	print( "input wave: ", input_wave, ", integral: ", input_wave_integral )
	var filtered_wave = process_input_wave( input_wave, input_wave_integral, input_wave_energy, network_delay )
	# Extract remote force from received wave variable: -F_m = b * xdot_m - sqrt( 2 * b ) * v_m
	feedback_force = -( wave_impedance * local_velocity - sqrt( 2.0 * wave_impedance ) * filtered_wave )
	print( "input wave: ", filtered_wave, ", feedback: ", feedback_force )
	# Encode and send output wave variable (velocity data): u_m = ( b * xdot_m + (-F_m) ) / sqrt( 2 * b )
	var output_wave = ( wave_impedance * local_velocity + external_force ) / sqrt( 2.0 * wave_impedance )
	# var output_wave = ( wave_impedance * local_velocity - feedback_force ) / sqrt( 2.0 * wave_impedance )
	var extra_outputs = process_output_wave( output_wave )
	print( "output wave: ", output_wave, ", velocity: ", local_velocity )
	.update_server( output_wave, extra_outputs[ 0 ], extra_outputs[ 1 ], client_time, last_server_time )

remote func update_client( input_wave, input_wave_integral, input_wave_energy, server_time, last_client_time ):
	var filtered_wave = process_input_wave( input_wave, input_wave_integral, input_wave_energy, network_delay )
	# Extract remote force from wave variable: F_s = -b * xdot_s + sqrt( 2 * b ) * u_s
	feedback_force = -( wave_impedance * local_velocity - sqrt( 2.0 * wave_impedance ) * filtered_wave )
	# Encode and send output wave variable (velocity data): v_s = ( b * xdot_s - F_s ) / sqrt( 2 * b )
	var output_wave = ( wave_impedance * local_velocity + external_force ) / sqrt( 2.0 * wave_impedance )
	#var output_wave = ( wave_impedance * local_velocity - feedback_force ) / sqrt( 2.0 * wave_impedance )
	var extra_outputs = process_output_wave( output_wave )
	.update_client( output_wave, extra_outputs[ 0 ], extra_outputs[ 1 ], server_time, last_client_time )

remote func set_impedance( remote_impedance ):
	wave_impedance = ( wave_impedance + max( local_impedance, remote_impedance ) ) / 2

func set_system( inertia, damping, stiffness ):
	local_impedance = inertia + damping + stiffness
	if local_impedance < 1.0: local_impedance = 1.0
	rpc_unreliable( "set_impedance", local_impedance )
