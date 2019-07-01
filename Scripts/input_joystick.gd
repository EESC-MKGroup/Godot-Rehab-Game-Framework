extends Node

const JOY_AXES = [ "Left X", "Left Y", "Left Trigger", "Right X", "Right Y", "Right Trigger" ]  

var device_id = 0
var state = 0

func _ready():
	pass

func connect_socket( string_id ):
	var device_index = int(string_id)
	var device_ids_list = Input.get_connected_joypads()
	if device_index >= 0 and device_index < device_ids_list.size():
		device_id = device_ids_list[ device_index ]
	return true

func disconnect_socket():
	pass

func read_device():
	pass

func set_request( new_state, info = "" ):
	state = new_state
	print( "set state " + str(state) )

func get_reply():
	return state

func get_available_devices():
	var available_devices = []
	available_devices.append( Input.get_joy_name( device_id ) )
	return available_devices

func get_device_info():
	var device_info = {}
	device_info[ "id" ] = Input.get_joy_name( device_id )
	device_info[ "axes" ] = JOY_AXES
	return device_info

func get_axis_position( axis ):
	return Input.get_joy_axis( device_id, axis )

func get_axis_force( axis ):
	return Input.get_joy_axis( device_id, axis )

func set_setpoints( position_setpoints, force_setpoints ):
	if force_setpoints.size() > 6:
		var x_feedback = force_setpoints[ 0 ] | ( force_setpoints[ 1 ] << 16 )
		var y_feedback = force_setpoints[ 2 ] | ( force_setpoints[ 3 ] << 16 )
		var z_feedback = force_setpoints[ 4 ] | ( force_setpoints[ 5 ] << 16 )
		#z_feedback += device_setpoints[ 6 ] | ( device_setpoints[ 7 ] << 16 )
		Input.start_joy_vibration( device_id, x_feedback, y_feedback, z_feedback )