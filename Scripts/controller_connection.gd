extends Node

enum AXIS { VERTICAL, HORIZONTAL }
enum INPUT { POSITION, VELOCITY, ACCELERATION, FORCE }
enum OUTPUT { SETPOINT, STIFFNESS, USER, TIME }

var input_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var input_limits = [ [ -0.001, 0001 ], [ -0.001, 0001 ] ]
var output_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var input_status = 0
var output_status = 0

const BUFFER_SIZE = 512
const BUFFER_PADDING = BUFFER_SIZE - ( 2 + 2 * 4 * 4 )
var output_buffer = PoolByteArray()

var connection = StreamPeerTCP.new()

func _ready():
	output_buffer.resize( BUFFER_PADDING )
	connection.set_no_delay( true )
	set_process( false )

func _process( delta ):
	if connection.get_available_bytes() >= BUFFER_SIZE:
		input_status = connection.get_u16()
		for axis_values in input_values:
			for index in axis_values.len():
				axis_values[ index ] = connection.get_float()
		connection.get_data( BUFFER_PADDING )
		connection.put_u16( output_status )
		for axis_values in output_values:
			for value in axis_values:
				connection.put_float( value )
		connection.put_data( output_buffer )

func connect_client( host, port ):
	if not connection.is_connected_to_host():
		connection.connect_to_host( host, port )
		if connection.is_connected_to_host(): set_process( true )

func set_status( status ):
	output_status = status

func get_status():
	return input_status

func set_axis_values( axis, setpoint, stiffness ):
	output_values[ axis ][ SETPOINT ] = setpoint
	output_values[ axis ][ STIFFNESS ] = stiffness

func get_axis_values( axis ):
	return input_values[ axis ]

func set_user( user_name ):
	output_values[ USER ] = user_name.hash()

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: connection.disconnect_from_host()