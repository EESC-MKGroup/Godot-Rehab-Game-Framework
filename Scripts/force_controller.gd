extends RigidBody

enum Variable { IMPEDANCE, FILTER, WAVE, WAVE_INTEGRAL }

var wave_impedance = 1.0
var filter_strength = 1.0

var remote_force = 0.0
var remote_force_integral = 0.0

var input_wave_variable = 0.0
var input_wave_integral = 0.0
var last_input_wave_variable = 0.0
var last_delayed_wave_variable = 0.0

var initial_position = 0.0

func _ready():
	initial_position = get_position_in_parent()

func process_input_wave(): 
	# Receive delayed u_in (u_in_old) and U_in (U_in_old)
	var delayed_wave_variable = GameManager.GetConnection().GetRemoteValue( (byte) elementID, Z, WAVE );
	#float delayedWaveIntegral = GameManager.GetConnection().GetRemoteValue( (byte) elementID, Z, WAVE_INTEGRAL );
	
	# Filter delayed input wave to ensure stability: u_in / u_in_old = 1 / ( s + 1 ) => discrete form (s = 2/T * (z-1)/(z+1))
	var delta_time = Time.fixedDeltaTime / filter_strength;
	input_wave_variable = ( ( 2 - delta_time ) * last_input_wave_variable + delta_time * ( delayed_wave_variable + last_delayed_wave_variable ) ) / ( 2 + delta_time );
	last_input_wave_variable = input_wave_variable;
	last_delayed_wave_variable = delayed_wave_variable;
	
	# Extract remote force from wave variable: F_in = sqrt( 2 * b ) * u_in - b * xdot_out
	remote_force = sqrt( 2 * wave_impedance ) * input_wave_variable - wave_impedance * body.velocity.z;
	# Extract remote moment from wave integral: p_in = sqrt( 2 * b ) * U_in - b * x_out
	remote_force_integral = sqrt( 2 * wave_impedance ) * input_wave_integral - wave_impedance * body.position.z;

func process_output_wave(): 
	# Encode output wave variable (velocity data): u_out = ( b * xdot_out - F_in ) / sqrt( 2 * b )
	float outputWaveVariable = ( wave_impedance * body.velocity.z - remote_force ) / Mathf.Sqrt( 2.0f * wave_impedance );
	# Encode output wave integral (position data): U_out = ( b * x_out - p_in ) / sqrt( 2 * b )
	#float outputWaveIntegral = ( wave_impedance * body.position.z - remote_force_integral ) / Mathf.Sqrt( 2.0f * wave_impedance );
	
	# Send u_out and U_out
	GameManager.GetConnection().SetLocalValue( (byte) elementID, Z, WAVE, outputWaveVariable );
	#GameManager.GetConnection().SetLocalValue( (byte) elementID, Z, WAVE_INTEGRAL, outputWaveIntegral );