extends Node

const LOCAL_DEVICE_AXES = [ 0, 1, 2, 3, 6, 7 ]

var device_index = 0 setget _set_device_index
var axis_index = 0 setget _set_axis_index

var device_ids_list = []
var devices_list = []
var axes_list = []

func get_devices_list():
	devices_list = []
	device_ids_list = Input.get_connected_joypads()
	for device_id in device_ids_list:
		devices_list.append( Input.get_joy_name( device_id ) )
	return devices_list

func get_axes_list():
	axes_list = []
	var device_id = device_ids_list[ device_index ]
	if device_id == InfoStateClient.remote_device_id:
		axes_list = InfoStateClient.remote_axes_list
	else:
		for axis_index in LOCAL_DEVICE_AXES:
			axes_list.append( Input.get_joy_axis_string( axis_index ) )
	return axes_list

func get_value():
	return Input.get_joy_axis( device_index, axis_index )

func set_value( value ):
	var input_event = InputEventJoypadMotion()
	input_event.device = device_ids_list[ device_index ]
	input_event.axis = axis_index
	input_event.axis_value = value
	Input.parse_input_event( input_event )

func set_feedback( setpoint_value ):
	var device_setpoints = [ 0, 0, 0, 0, 0, 0 ]
	var device_id = device_ids_list[ device_index ]
	device_setpoints[ axis_index ] = setpoint_value 
	var x_feedback = device_setpoints[ 0 ] | ( device_setpoints[ 1 ] << 16 )
	var y_feedback = device_setpoints[ 2 ] | ( device_setpoints[ 3 ] << 16 )
	var z_feedback = device_setpoints[ 4 ] | ( device_setpoints[ 5 ] << 16 )
	Input.start_joy_vibration( device_id, x_feedback, y_feedback, z_feedback )

func get_feedbacks():
	var device_id = device_ids_list[ device_index ]
	var xy_feedback = Input.get_joy_vibration_strength( device_id )
	var z_feedback = Input.get_joy_vibration_duration( device_id )
	var feedback_values = [ xy_feedback.x & 0xFFFF, xy_feedback.x >> 16 & 0xFFFF,
							xy_feedback.y & 0xFFFF, xy_feedback.y >> 16 & 0xFFFF,
							z_feedback & 0xFFFF, z_feedback >> 16 & 0xFFFF ]
	return feedback_values

func _set_device_index( value ):
	if value < devices_list.size(): device_index = value
	if device_ids_list[ device_index ] == InfoStateClient.remote_device_id:
		RemoteDeviceClient.start_processing()
	else:
		RemoteDeviceClient.stop_processing()

func _set_axis_index( value ):
	if value < axes_list.size(): axis_index = value