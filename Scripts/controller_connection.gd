extends Node

enum AXIS { VERTICAL, HORIZONTAL }
enum INPUT { POSITION, VELOCITY, ACCELERATION, FORCE }
enum OUTPUT { SETPOINT, STIFFNESS, USER, TIME }

var input_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var position_limits = [ [ -0.001, 0001 ], [ -0.001, 0001 ] ]
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
		for axis_index in range(input_values.size()):
			var axis_values = input_values[ axis_index ]
			for value_index in axis_values.size():
				axis_values[ value_index ] = connection.get_float()
			var axis_limits = position_limits[ axis_index ]
			axis_limits[ 0 ] = min( axis_values[ POSITION ], axis_limits[ 0 ] ) 
			axis_limits[ 1 ] = max( axis_values[ POSITION ], axis_limits[ 1 ] ) 
			var axis_range = axis_limits[ 1 ] - axis_limits[ 0 ]
			axis_values[ POSITION ] -= axis_limits[ 0 ]
			axis_values[ POSITION ] *= ( 2 / axis_range )
			axis_values[ VELOCITY ] *= ( 2 / axis_range )
			axis_values[ POSITION ] -= 1.0
		connection.get_data( BUFFER_PADDING )
		
		connection.put_u16( output_status )
		for axis_values in output_values:
			connection.put_float( axis_values[ POSITION ] )
			connection.put_float( axis_values[ VELOCITY ] )
			connection.put_u32( axis_values[ USER ] )
			connection.put_u32( axis_values[ TIME ] )
		connection.put_data( output_buffer )

func connect_client( host, port ):
	if not connection.is_connected_to_host():
		connection.connect_to_host( host, port )
		while connection.get_status() == connection.STATUS_CONNECTING: continue
		if connection.is_connected_to_host(): set_process( true )

func set_status( status ):
	output_status = status

func get_status():
	return input_status

func set_axis_values( axis_index, setpoint, stiffness ):
	var axis_limits = position_limits[ axis_index ]
	var axis_range = axis_limits[ 1 ] - axis_limits[ 0 ]
	setpoint = ( setpoint + 1 ) * axis_range / 2
	setpoint += axis_limits[ 0 ]
	output_values[ axis_index ][ SETPOINT ] = setpoint
	output_values[ axis_index ][ STIFFNESS ] = stiffness

func get_axis_values( axis_index ):
	return input_values[ axis_index ]

func set_user( user_name ):
	output_values[ USER ] = user_name.hash()
	output_values[ TIME ] = OS.get_system_time_secs()

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: connection.disconnect_from_host()