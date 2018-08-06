extends Node

enum Variable { POSITION, VELOCITY, ACCELERATION, FORCE, INERTIA, STIFFNESS, DAMPING, TOTAL_NUMBER }

const SERVER_PORT = 50001

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

var is_calibrating = false

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
						input_limits[ axis_index ] = _check_limits( input_limits[ axis_index ], axis_value )
					elif input_limits[ axis_index ] != null:
						axis_value = _normalize( axis_value, input_limits[ axis_index ] )
					axis_value /= max_effort
					InputAxis.set_value( axis_value )

func _process( delta ):
	output_buffer.seek( 0 )
	var axes_number = InfoStateClient.remote_axis_list.size()
	var feedbacks_list = InputAxis.get_feedbacks()
	output_buffer.put_u8( axes_number )
	for axis_index in range( axes_number ):
		output_buffer.put_u8( axis_index )
		for variable in range( Variable.TOTAL_NUMBER ):
			var output = feedbacks_list[ axis_index ] if variable == Variable.POSITION else 0
			output_buffer.put_float( output )
	connection.put_data( output_buffer.data_array )

func connect_client( host ):
	connection.set_dest_address( host, SERVER_PORT )

func start_processing():
	if not is_receiving: receive_thread.start( self, "receive_data" )
	set_process( true )

func stop_processing():
	set_process( false )
	if is_receiving:
		is_receiving = false
		receive_thread.wait_to_finish()

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

func set_calibration( value ):
	if value: 
		for axis_index in range( Variable.TOTAL_NUMBER ):
			input_limits[ axis_index ] = null
			output_limits[ axis_index ] = null
	is_calibrating = value

func get_calibration():
	return is_calibrating

func set_max_effort( value ):
	max_effort = value / 100.0

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		connection.close()