extends Node

enum AXIS { VERTICAL, HORIZONTAL }
enum INPUT { POSITION, VELOCITY, ACCELERATION, FORCE }
enum OUTPUT { SETPOINT, STIFFNESS, USER, TIME }

var position_limits = [ null, null ]
var force_limits = [ null, null ]
var input_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var output_values = [ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
var input_status = 0
var output_status = 0

var is_calibrating = true setget set_calibration, get_calibration
var direction_axis = VERTICAL setget set_direction, get_direction

var max_effort = 1.0

var connection = StreamPeerTCP.new()

func _ready():
	#connection.set_no_delay( true )
	set_calibration( true )
	set_process( false )

func receive_data():
	input_status = connection.get_u16()
	for axis_index in range( input_values.size() ):
		var axis_values = input_values[ axis_index ]
		for value_index in axis_values.size():
			axis_values[ value_index ] = -connection.get_float()
		if is_calibrating: 
			position_limits[ axis_index ] = _check_limits( position_limits[ axis_index ], axis_values[ POSITION ] )
			force_limits[ axis_index ] = _check_limits( force_limits[ axis_index ], axis_values[ FORCE ] )
		elif position_limits[ axis_index ] != null:
			axis_values[ POSITION ] = _normalize( axis_values[ POSITION ], position_limits[ axis_index ] )
			axis_values[ FORCE ] = _scale( axis_values[ FORCE ], force_limits[ axis_index ] )
		for value_index in axis_values.size():
			axis_values[ value_index ] /= max_effort

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

func set_axis_values( setpoint, stiffness ):
	var axis_limits = position_limits[ direction_axis ]
	if not is_calibrating:
		setpoint = _denormalize( setpoint, axis_limits )
		output_values[ direction_axis ][ SETPOINT ] = -setpoint * max_effort
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
		var byte_offset = ( 3 - byte_index ) * 8
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