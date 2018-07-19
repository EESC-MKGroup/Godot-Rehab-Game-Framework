extends Node

enum Variable { POSITION, VELOCITY, ACCELERATION, FORCE, INERTIA, STIFFNESS, DAMPING, TOTAL_NUMBER }

const DEVICE_ID = "ff"

const BUFFER_SIZE = 512
const FLOAT_SIZE = 4
const AXIS_DATA_SIZE = 1 + Variable.TOTAL_NUMBER * FLOAT_SIZE
var MAX_AXES_NUMBER = int( BUFFER_SIZE / AXIS_DATA_SIZE )

var input_buffer = StreamPeerBuffer.new()
var output_buffer = StreamPeerBuffer.new()

var input_limits = []
var output_limits = []
var input_values = []
var output_values = []

var max_effort = 1.0

var connection = PacketPeerUDP.new()

var receive_thread = Thread.new()
var is_receiving = false

func _ready():
	#connection.set_no_delay( true )
	set_calibration( true )
	set_process( false )
	input_buffer.resize( BUFFER_SIZE )
	output_buffer.resize( BUFFER_SIZE )
	for axis_index in range( Variable.TOTAL_NUMBER ):
		input_values.append( 0 )
		output_values.append( 0 )
		input_limits.append( null )
		output_limits.append( null )

func receive_data():
	is_receiving = true
	while( is_receiving ):
		input_buffer.set_position( 0 )
		input_buffer.put_data( connection.get_packet() )
		var inputs_number = input_buffer.get_u8()
		for input_index in range( inputs_number ):
			var axis_index = input_buffer.get_u8()
			for variable in range( Variable.TOTAL_NUMBER ):
				var axis_value = input_buffer.get_float()
				if variable == Variable.FORCE:
					if is_calibrating:
						input_limits[ axis_index ] = _check_limits( input_limits[ axis_index ], variable )
					elif position_limits[ axis_index ] != null:
						variable = _normalize( variable, input_limits[ axis_index ] )
					variable /= max_effort
					var input_event = InputEventJoypadMotion()
					input_event.device = 1
					input_event.axis = axis_index
					input_event.axis_value = axis_value
					Input.parse_input_event( input_event )

func _process( delta ):
	var xy_feedback = Input.get_joy_vibration_strength( 1 )
	var z_feedback = Input.get_joy_vibration_duration( 1 )
#	var feedback_values = [ xy_feedback.x >> 16 & 0xFFFF
	output_buffer.seek( 0 )
	output_buffer.put_u8( 6 )
	for axis_index in range( 6 ):
		output_buffer.put_u8( axis_index )
		for variable in range( Variable.TOTAL_NUMBER ):
			output_buffer.put_float(  )
	connection.put_data( output_buffer.data_array )

func connect_client( host, port ):
	connection.set_dest_address( host, port )
	if not is_receiving: receive_thread.start( self, "receive_data" )
	set_process( true )

func set_axis_values( setpoint, stiffness ):
	var axis_limits = position_limits[ direction_axis ]
	if not is_calibrating:
		setpoint = _denormalize( setpoint, axis_limits )
		output_values[ direction_axis ][ SETPOINT ] = setpoint * max_effort
		output_values[ direction_axis ][ STIFFNESS ] = stiffness

func get_axis_values():
	return input_values[ direction_axis ]

func _check_limits( limits, value ):
	if limits == null: limits = [ value - 0.001, value + 0.001 ]
	limits[ 0 ] = min( value, limits[ 0 ] ) 
	limits[ 1 ] = max( value, limits[ 1 ] )
	return limits

func _normalize( value, limits ):
	var value_range = limits[ 1 ] - limits[ 0 ]
	return ( 2 * ( value - limits[ 0 ] ) / value_range ) - 1.0

func _denormalize( value, limits ):
	if limits == null: return value
	var value_range = limits[ 1 ] - limits[ 0 ]
	return ( ( value + 1.0 ) * value_range / 2 ) + limits[ 0 ]

func _scale( value, limits ):
	if value < 0.0 and limits[ 0 ] < 0.0: return -value / limits[ 0 ]
	elif value > 0.0 and limits[ 1 ] > 0.0: return value / limits[ 1 ]
	return 0.0

func _unscale( value, limits ):
	if value < 0.0 and limits[ 0 ] < 0.0: return -value * limits[ 0 ]
	elif value > 0.0 and limits[ 1 ] > 0.0: return value * limits[ 1 ]
	return 0.0

func set_calibration( value ):
	if value: 
		position_limits = [ null, null ]
		force_limits = [ null, null ]
	is_calibrating = value

func get_calibration():
	return is_calibrating

func set_direction( value ):
	if value == VERTICAL or value == HORIZONTAL:
		direction_axis = value

func get_direction():
	return direction_axis

func set_identifier( user_name, time_stamp ):
	var user_id = 0x00000000
	var user_string = user_name.to_ascii()
	print( user_name )
	for byte_index in user_string.size():
		print( "%d %x" % [ user_string[ byte_index ], user_string[ byte_index ] ] )
		var byte_offset = ( user_string.size() - 1 - byte_index ) * 8
		user_id |= ( user_string[ byte_index ] << byte_offset )
	output_values[ 0 ][ USER ] = user_id
	print( "user: %d %x" % [ output_values[ 0 ][ USER ], output_values[ 0 ][ USER ] ] )
	output_values[ 0 ][ TIME ] = time_stamp

func set_time_window( value ):
	output_values[ 1 ][ TIME ] = value * 1000

func set_max_effort( value ):
	max_effort = value / 100.0

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		output_status = 0
		send_data()
		connection.disconnect_from_host()