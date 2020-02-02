extends Node

const DEVICE_ID = "Keyboard"
const AXES = [ "Up-Down", "Left-Right" ]  

var states = [ [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ] ]
var reply = 0

onready var input_time = OS.get_ticks_msec() / 1000

static func get_id():
	return "Key"

static func get_default_address():
	return "Keyboard"

func connect_socket( string_id ):
	return true

func disconnect_socket():
	pass

func get_update( positions, forces, impedances ):
	for axis_index in range( min( positions.size(), AXES.size() ) ):
		positions[ axis_index ][ 0 ] = states[ axis_index ][ 0 ]
		positions[ axis_index ][ 1 ] = states[ axis_index ][ 1 ]
		positions[ axis_index ][ 2 ] = states[ axis_index ][ 2 ]
		impedances[ axis_index ][ 0 ] = 0.0
		impedances[ axis_index ][ 1 ] = 0.0
		impedances[ axis_index ][ 2 ] = 0.0
	if forces.size() >= 2:
		forces[ 0 ] = -1.0 if Input.is_key_pressed( KEY_UP ) else ( +1.0 if Input.is_key_pressed( KEY_DOWN ) else 0 )
		forces[ 1 ] = -1.0 if Input.is_key_pressed( KEY_LEFT ) else ( +1.0 if Input.is_key_pressed( KEY_RIGHT ) else 0 )
	return reply

func set_request( request, info = "" ):
	reply = request

func get_available_devices():
	return [ DEVICE_ID ]

func get_device_info():
	var device_info = {}
	device_info[ "id" ] = DEVICE_ID
	device_info[ "axes" ] = AXES
	return device_info

func set_setpoints( setpoints, feedbacks ):
	pass
#	var time_delta = OS.get_ticks_msec() / 1000 - input_time
#	input_time = OS.get_ticks_msec() / 1000
#	for axis_index in range( min( setpoints.size(), AXES.size() ) ):
#		var position_delta = setpoints[ axis_index ] - states[ axis_index ][ 0 ]
#		var velocity_delta = position_delta / time_delta - states[ axis_index ][ 1 ]
#		states[ axis_index ][ 2 ] = velocity_delta / time_delta
#		states[ axis_index ][ 1 ] = position_delta / time_delta
#		states[ axis_index ][ 0 ] = setpoints[ axis_index ][ 0 ]
