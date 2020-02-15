extends "res://Scripts/network_controller.gd"

# Wave variables control algorithm with kalman filtering
# Please refer to 2015 paper by Rodrigez-Seda for more details

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var wave_observer = kalman_filter.new()

var wave_impedance = 1.0
var local_impedance = 1.0

var input_energy = 0.0
var output_energy = 0.0

func _ready():
	wave_observer.error_covariance_noise[ 0 ] = 2.0
	wave_observer.error_covariance_noise[ 1 ] = 1.0
	wave_observer.error_covariance_noise[ 2 ] = 2.0
	wave_observer.state_predictor[ 1 ][ 0 ] = time_step
	wave_observer.state_predictor[ 2 ][ 0 ] = pow( time_step, 2 ) / 2
	wave_observer.state_predictor[ 2 ][ 1 ] = time_step

# Receive delayed u_in (u_in_old) and U_in (U_in_old)
func process_input_wave( input_wave, input_wave_integral, input_wave_energy ):
	# Wave corretion via Kalman filter
	var time_delay = int( network_delay / time_step ) * time_step
	input_wave_integral = input_wave_integral + input_wave * time_delay
	var wave_state = wave_observer.process( [ input_wave_integral, input_wave, Vector3.ZERO ] )
	var filtered_integral = wave_state[ 0 ]
	var filtered_wave = wave_state[ 1 ]
	# Check energy balance to keep stability under variable delay
	#var input_energy_delta = 0.5 * filtered_wave.dot( filtered_wave ) * time_step
	if input_wave_energy[ 0 ] - input_energy < 0: filtered_wave = Vector3.ZERO
	input_energy += 0.5 * filtered_wave.dot( filtered_wave ) * time_step
	# Extract remote force from received wave variable: -F_in = b * xdot_out - sqrt( 2 * b ) * u_in
	var input_force = -( wave_impedance * local_velocity - sqrt( 2.0 * wave_impedance ) * filtered_wave )
	
	var local_momentum = mass * linear_velocity
	target_position = ( sqrt( 2.0 * wave_impedance ) * filtered_integral - local_momentum ) / wave_impedance
	
	return [ input_force, wave_state[ 0 ], wave_state[ 1 ] ]

# Send u_out and U_out
func process_output_wave( input_wave_integral ): 
	# Encode and send output wave variable (velocity data): u_out = ( b * xdot_out + (-F_in) ) / sqrt( 2 * b )
	# var output_wave = ( wave_impedance * local_velocity - feedback_force ) / sqrt( 2.0 * wave_impedance )
	# Encode and send output wave variable (velocity data): u_out = ( b * xdot_out + F_out ) / sqrt( 2 * b )
	var output_wave = ( wave_impedance * local_velocity + external_force ) / sqrt( 2.0 * wave_impedance )
	# Encode and send output wave integral (position data): U_out = sqrt( 2 * b ) * x_out - u_in
	var output_wave_integral = sqrt( 2.0 * wave_impedance ) * local_position - input_wave_integral
	# Integrate output wave power signal
	output_energy += 0.5 * output_wave.dot( output_wave ) * time_step
	
	return [ output_wave, output_wave_integral, Vector3( output_energy, 0, 0 ) ] 

remote func update_server( input_wave, input_wave_integral, input_wave_energy, client_time, last_server_time ):
	# Wave corretion via Kalman filter
	# Check energy balance to keep stability under variable delay
	# Extract remote force from received wave variable: -F_m = b * xdot_m - sqrt( 2 * b ) * v_m
	var wave_inputs = process_input_wave( input_wave, input_wave_integral, input_wave_energy )
	feedback_force = wave_inputs[ 0 ]
	# Encode and send output wave variable (velocity data): u_m = ( b * xdot_m + (-F_m) ) / sqrt( 2 * b )
	# Encode and send output wave variable (velocity data): u_m = ( b * xdot_m + F_ext ) / sqrt( 2 * b )
	var wave_outputs = process_output_wave( wave_inputs[ 1 ] )
	
	.update_server( wave_outputs[ 0 ], wave_outputs[ 1 ], wave_outputs[ 2 ], client_time, last_server_time )

remote func update_client( input_wave, input_wave_integral, input_wave_energy, server_time, last_client_time ):
	# Wave corretion via Kalman filter
	# Check energy balance to keep stability under variable delay
	# Extract remote force from wave variable: F_s = -b * xdot_s + sqrt( 2 * b ) * u_s
	var wave_inputs = process_input_wave( input_wave, input_wave_integral, input_wave_energy )
	feedback_force = wave_inputs[ 0 ]
	# Encode and send output wave variable (velocity data): v_s = ( b * xdot_s - F_s ) / sqrt( 2 * b )
	# Encode and send output wave variable (velocity data): v_s = ( b * xdot_s + F_ext ) / sqrt( 2 * b )
	var wave_outputs = process_output_wave( wave_inputs[ 1 ] )
	
	.update_client( wave_outputs[ 0 ], wave_outputs[ 1 ], wave_outputs[ 2 ], server_time, last_client_time )

remote func set_remote_impedance( inertia, damping, stiffness ):
	var remote_impedance = inertia + damping + stiffness
	wave_impedance = ( wave_impedance + max( local_impedance, remote_impedance ) ) / 2

func set_local_impedance( inertia, damping ):
	local_impedance = inertia + damping
	if local_impedance < 1.0: local_impedance = 1.0
	rpc_unreliable( "set_remote_impedance", inertia, damping, 0.0 )
	return wave_impedance
