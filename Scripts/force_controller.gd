extends "res://Scripts/network_controller.gd"

enum Variable { IMPEDANCE, FILTER, WAVE, WAVE_INTEGRAL }

var wave_impedance = 1.0

# Wave variables control algorithm with wave filtering
# Please refer to section 7 of 2004 paper by Niemeyer and Slotline for more details

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
	
	return [ remote_force, remote_momentum ]

# Send u_out and U_out
func process_output_wave( force, momentum ): 
	# Encode output wave variable (velocity data): u_out = ( b * xdot_out - F_in ) / sqrt( 2 * b )
	var wave = ( wave_impedance * linear_velocity - force ) / sqrt( 2 * wave_impedance )
	# Encode output wave integral (position data): U_out = ( b * x_out - p_in ) / sqrt( 2 * b )
	var wave_integral = ( wave_impedance * translation - momentum ) / sqrt( 2 * wave_impedance )
	
	# Send u_out and U_out
	return [ wave, wave_integral ]