extends Node

enum State { GET_INFO = 1, DISABLED, ENABLED, ERROR, PASSIVE, OPERATION, OFFSET, CALIBRATION, PREPROCESS, SET_USER, SET_CONFIG }

signal state_changed
signal client_connected

const DEVICE_GUID = "ff"

onready var interface = preload( "res://Scripts/input_device.gdns" ).new()

var device_ids_list = []
var devices_list = [ 0 ]

var input_limits = []
var output_limits = []

var positions = []
var forces = []
var feedbacks = []

var device_state = State.DISABLED setget _set_state, _get_state

var read_thread = Thread.new()
var is_reading = false

var string_id = "" setget ,_get_string_id
var id = -1 setget ,_get_id
var axes_list = [] setget ,_get_axes_list

func _ready():
	set_process( false )
	_reset_limits()

func get_devices_list():
	devices_list = []
	device_ids_list = Input.get_connected_joypads()
	for device_id in device_ids_list:
		devices_list.append( Input.get_joy_name( device_id ) )
	return devices_list

func _get_id():
	return id

func _get_string_id():
	return string_id

func _get_axes_list():
	return axes_list

func get_axis_position( axis ):
	return positions[ axis ]

func get_axis_force( axis ):
	return forces[ axis ]

func set_axis_

func _get_device_state():
	var reply_code = interface.get_state()
	if device_state != reply_code:
		if reply_code == State.GET_INFO:
			#var device_info_string = interface.get_info()
			#var device_info = parse_json( device_info_string )
			var device_info = interface.get_info()
			string_id = device_info[ "id" ]
			axes_list = device_info[ "axes" ]
			positions = [].resize( axes_list.size() )
			forces = [].resize( axes_list.size() )
			feedbacks = [].resize( axes_list.size() )
			#_add_remote_device_input()
			#_update_remote_device()
		elif reply_code == State.CALIBRATION:
			_reset_limits()
		emit_signal( "state_changed", reply_code )
	device_state = reply_code

func _get_device_data():
	for axis in range( axes_list.size() ):
		positions[ axis ] = interface.get_axis_position( axis )
		forces[ axis ] = interface.get_axis_force( axis )
#		if device_state == State.CALIBRATION:
#			input_limits[ axis ] = _check_limits( input_limits[ axis ], force )
#			output_limits[ axis ] = _check_limits( output_limits[ axis ], position )
#		elif input_limits[ axis ] != null:
#			force = _normalize( force, input_limits[ axis ] )
#		#	position = _normalize( position, output_limits[ axis ] )
#		InputAxis.set_value( force )

func _run_read_loop():
	is_reading = true
	while( is_reading ):
		interface.read_device()
		_get_device_state()
		_get_device_data()

func _process( delta ):
	var feedbacks_list = InputAxis.get_feedbacks()
	for axis in range( axes_list.size() ):
		interface.set_axis_position( axis, feedbacks_list[ axis ] )

func connect_socket( host ):
	if interface.connect_socket( host ):
		if not is_reading: read_thread.start( self, "_run_read_loop" )
		set_process( true )

func disconnect_socket():
	set_process( false )
	if is_reading:
		is_reading = false
		read_thread.wait_to_finish()
	interface.disconnect_socket()

#func start_processing():
#	if not is_reading: read_thread.start( self, "_run_read_loop" )
#	set_process( true )

#func stop_processing():
#	set_process( false )
#	if is_reading:
#		is_reading = false
#		read_thread.wait_to_finish()
#	interface.disconnect_socket()

func _set_state( new_state ):
	interface.set_state( new_state )

func _get_state():
	return device_state

#func _add_remote_device_input():
#	var controller_mapping = DEVICE_GUID + "," + string_id
#	if axes_list.size() > 0:
#		for axis in range( axes_list.size() ):
#			controller_mapping += "," + axes_list[ axis ] + ":a" + str(axis)
#		Input.add_joy_mapping( controller_mapping, true )
#
#func _update_remote_device():
#	var devices_list = Input.get_connected_joypads()
#	for device in devices_list:
#		if Input.get_joy_guid( device ) == DEVICE_GUID: id = device

#func _set_device_index( index ):
#	if index < devices_list.size(): device_index = device_ids_list[ index ]
#	if device_index == RemoteInfoState.remote_device_id:
#		RemoteDevice.start_processing()
#	else:
#		RemoteDevice.stop_processing()

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

func _reset_limits():
	input_limits = []
	output_limits = []
	for axis_index in range( axes_list.size() ):
		input_limits.append( null )
		output_limits.append( null )

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		disconnect_socket()