extends Node

const JOY_AXES = [ "Left X", "Left Y", "Left Trigger", "Right X", "Right Y", "Right Trigger" ]  
const JOY_AUX_AXIS = 7

var available_devices = {}

var device_id = 0
var state = 0

static func get_id():
	return "JS"

static func get_default_address():
	return "0"

func _ready():
	pass

func connect_socket( string_id ):
	if Input.get_connected_joypads().size() > 0: return true
	return false

func disconnect_socket():
	pass

func get_update( positions, forces, impedances ):
	for axis_index in range( min( positions.size(), JOY_AXES.size() ) ):
		positions[ axis_index ][ 0 ] = Input.get_joy_axis( device_id, axis_index )
		positions[ axis_index ][ 1 ] = Input.get_joy_axis( device_id, axis_index )
		positions[ axis_index ][ 2 ] = Input.get_joy_axis( device_id, axis_index )
		impedances[ axis_index ][ 0 ] = 0.1
		impedances[ axis_index ][ 1 ] -= 0.1 * Input.get_joy_axis( device_id, JOY_AUX_AXIS )
		impedances[ axis_index ][ 1 ] = max( impedances[ axis_index ][ 1 ], 0.0 )
		impedances[ axis_index ][ 2 ] = 0.0
		forces[ axis_index ] = Input.get_joy_axis( device_id, axis_index )
	return state

func set_request( new_state, info = "" ):
	state = new_state
	if state == InputManager.Request.SET_CONFIG:
		device_id = available_devices.get( info )
	print( "set state " + str(state) )

func get_available_devices():
	var device_ids_list = Input.get_connected_joypads()
	print( device_ids_list.size() )
	for device_id in device_ids_list:
		available_devices[ Input.get_joy_name( device_id ) ] = device_id
		print( Input.get_joy_name( device_id ) )
	print( available_devices )
	return available_devices.keys()

func get_device_info():
	var device_info = {}
	device_info[ "id" ] = Input.get_joy_name( device_id )
	device_info[ "axes" ] = JOY_AXES
	return device_info

func set_setpoints( position_setpoints, force_setpoints ):
	if force_setpoints.size() > 6:
		var x_feedback = force_setpoints[ 0 ] | ( force_setpoints[ 1 ] << 16 )
		var y_feedback = force_setpoints[ 2 ] | ( force_setpoints[ 3 ] << 16 )
		var z_feedback = force_setpoints[ 4 ] | ( force_setpoints[ 5 ] << 16 )
		Input.start_joy_vibration( device_id, x_feedback, y_feedback, z_feedback )
