extends "res://Scripts/network_controller.gd"

# Wave variables control algorithm with wave filtering
# Please refer to section 7 of 2004 paper by Niemeyer and Slotline for more details

onready var game = get_tree().get_root()

var wave_impedance = 1.0

var external_force = Vector3.ZERO setget set_external_force

sync func set_wave_impedance( value ):
	if value > 0.1: wave_impedance = value

func set_external_force( value ):
	external_force = value

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
	
	#remote_force[ 0 ] = filter_delayed_input( remote_force[ 0 ], remote_force[ 1 ], last_server_time )
	# Apply resulting force F_m to rigid body
	add_central_force( remote_force[ 0 ] + game.get_environment_force( self ) )
	# Encode and send output wave variable (velocity data): u_m = ( b * xdot_m + (-F_m) ) / sqrt( 2 * b )
	# Encode and send output wave integral (position data): U_m = ( b * x_m + (-p_m) ) / sqrt( 2 * b )
	var output_wave = process_output_wave( remote_force[ 0 ], remote_force[ 1 ] )
	var server_time = OS.get_ticks_msec()
	rpc_unreliable( "update_player", output_wave[ 0 ], output_wave[ 1 ], client_time, server_time )
	# Send position and velocity values directly
	rpc_unreliable( "update_slave", translation, linear_velocity, client_time, server_time )

master func update_player( wave, wave_integral, last_client_time, server_time ):
	# Extract remote force from wave variable: F_s = -b * xdot_s + sqrt( 2 * b ) * u_s
	# Extract remote moment from received wave integral: p_m = -b * x_s + sqrt( 2 * b ) * U_s
	var remote_force = process_input_wave( wave, wave_integral )
	
	#remote_force[ 0 ] = filter_delayed_input( remote_force[ 0 ], remote_force[ 1 ], last_client_time )
	# Apply player input force F_h to rigid body
	add_central_force( remote_force[ 0 ] + game.get_player_force( self ) )
	# Encode and send output wave variable (velocity data): v_s = ( b * xdot_s - F_s ) / sqrt( 2 * b )
	# Encode and send output wave integral (position data): V_s = ( b * x_s - p_s ) / sqrt( 2 * b )
	var output_wave = process_output_wave( remote_force[ 0 ], remote_force[ 1 ] )
	var client_time = OS.get_ticks_msec()
	rpc_unreliable( "update_server", output_wave[ 0 ], output_wave[ 1 ], server_time, client_time )

slave func update_slave( master_position, master_velocity, last_client_time, server_time ):
	var delay = ( OS.get_ticks_msec() - last_client_time ) / 2000
	print( "delay= " + str(delay) )
	var tracking_error = master_position + master_velocity * delay - translation
	print( "master: pos={0}, vel={1}, err={2}".format( [ master_position, master_velocity, tracking_error ] ) )
	master_velocity = filter_delayed_input( master_velocity, tracking_error, last_client_time )
	linear_velocity = master_velocity
	angular_velocity = linear_velocity.rotated( Vector3.UP, 90 ) / $Collider.shape.margin / 2