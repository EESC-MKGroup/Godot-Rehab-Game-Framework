const DEVICE_ID = "Device-Null"
const AXES = [ "Axis-Null" ]

var reply = 0

static func get_id():
	return "Null"

static func get_default_address():
	return "Address-Null"

func connect_socket( string_id ):
	return true

func disconnect_socket():
	pass

func get_update( positions, forces, impedances ):
	for axis_index in range( positions.size() ):
		for var_index in range( 3 ):
			positions[ axis_index ][ var_index ] = 0.0
			impedances[ axis_index ][ var_index ] = 0.1
		forces[ axis_index ] = 0.0
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
