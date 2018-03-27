extends Node

enum AXIS { VERTICAL, HORIZONTAL }
enum INPUT { POSITION, VELOCITY, ACCELERATION, FORCE }
enum OUTPUT { SETPOINT, STIFFNESS, USER, TIME }

const NULL_LIMITS = [ null, null ]

var input_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var position_limits = NULL_LIMITS
var output_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var input_status = 0
var output_status = 0

var is_calibrating = true setget set_calibration, get_calibration

var connection = StreamPeerTCP.new()

func _ready():
	#connection.set_no_delay( true )
	set_process( false )

func receive_data():
	input_status = connection.get_u16()
	for axis_index in range(input_values.size()):
		var axis_values = input_values[ axis_index ]
		for value_index in axis_values.size():
			axis_values[ value_index ] = connection.get_float()
		var axis_limits = position_limits[ axis_index ]
		if is_calibrating: 
			axis_limits = _check_limits( axis_limits, axis_values[ POSITION ] )
			position_limits[ axis_index ] = axis_limits
		elif axis_limits != null:
			axis_values[ POSITION ] = _normalize( axis_values[ POSITION ], axis_limits )

func send_data():
	var output_buffer = StreamPeerBuffer.new()
	output_buffer.put_u16( output_status )
	for axis_values in output_values:
		for value in axis_values:
			output_buffer.put_float( value )
	connection.put_data( output_buffer.data_array )

func _process( delta ):
	send_data()
	receive_data()

func connect_client( host, port ):
	if not connection.is_connected_to_host():
		connection.connect_to_host( host, port )
		while connection.get_status() == connection.STATUS_CONNECTING: 
			print( "connecting to %s:%d" % [ host, port ] )
			continue
		if connection.is_connected_to_host(): 
			output_status = 1
			set_process( true )

func set_status( value ):
	output_status = value

func get_status():
	return input_status

func set_axis_values( axis_index, setpoint, stiffness ):
	var axis_limits = position_limits[ axis_index ]
	if not is_calibrating:
		setpoint = _denormalize( setpoint, axis_limits )
		output_values[ axis_index ][ SETPOINT ] = setpoint
		output_values[ axis_index ][ STIFFNESS ] = stiffness

func get_axis_values( axis_index ):
	return input_values[ axis_index ]

func _check_limits( limits, value ):
	if limits == null: limits = [ value - 0.001, value + 0.001 ]
	limits[ 0 ] = min( value, limits[ 0 ] ) 
	limits[ 1 ] = max( value, limits[ 1 ] )
	return limits

func _normalize( value, limits ):
	var value_range = limits[ 1 ] - limits[ 0 ]
	return ( 2 * ( value - limits[ 0 ] ) / value_range ) - 1.0

func _denormalize( value, limits ):
	var value_range = limits[ 1 ] - limits[ 0 ]
	return ( ( value + 1.0 ) * value_range / 2 ) + limits[ 0 ]

func set_calibration( value ):
	if value: position_limits = NULL_LIMITS
	is_calibrating = value

func get_calibration():
	return is_calibrating

func set_identifier( user_name, time_stamp ):
	output_values[ 0 ][ USER ] = hash( user_name )
	output_values[ 0 ][ TIME ] = time_stamp

func set_time_window( value ):
	output_values[ 1 ][ TIME ] = value * 1000

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		output_status = 0
		send_data()
		connection.disconnect_from_host()