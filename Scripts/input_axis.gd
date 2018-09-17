extends Node

var device_index = 0 setget _set_device_index
var axis_index = 0 setget _set_axis_index

var device_ids_list = []
var devices_list = [ 0 ]
var axes_list = [ "Dummy" ]

#var max_effort = 1.0 setget _set_max_effort

func get_devices_list():
	devices_list = []
	device_ids_list = Input.get_connected_joypads()
	for device_id in device_ids_list:
		devices_list.append( Input.get_joy_name( device_index ) )
	return devices_list

func get_axes_list():
	axes_list = []
	if device_index == RemoteInfoState.remote_device_id:
		axes_list = RemoteInfoState.remote_axes_list
	else:
		for axis_index in [ 0, 1, 2, 3, 4, 5 ]:
			#axes_list.append( Input.get_joy_axis_string( axis_index ) )
			axes_list.append( str( axis_index ) )
	return axes_list

func get_value():
	return Input.get_joy_axis( device_index, axis_index )

func set_value( value ):
	var input_event = InputEventJoypadMotion.new()
	input_event.device = device_index
	input_event.axis = axis_index
	input_event.axis_value = value
	Input.parse_input_event( input_event )

func set_feedback( setpoint_value ):
	var device_setpoints = [ 0, 0, 0, 0, 0, 0, 0, 0 ]
	device_setpoints[ axis_index ] = setpoint_value 
	var x_feedback = 0#device_setpoints[ 0 ] | ( device_setpoints[ 1 ] << 16 )
	var y_feedback = 0#device_setpoints[ 2 ] | ( device_setpoints[ 3 ] << 16 )
	var z_feedback = 0#device_setpoints[ 4 ] | ( device_setpoints[ 5 ] << 16 )
	#z_feedback += device_setpoints[ 6 ] | ( device_setpoints[ 7 ] << 16 )
	Input.start_joy_vibration( device_index, x_feedback, y_feedback, z_feedback )

func get_feedbacks():
	var xy_feedback = Input.get_joy_vibration_strength( device_index )
	var z_feedback = Input.get_joy_vibration_duration( device_index )
	var feedback_values = [ xy_feedback.x & 0xFFFF, xy_feedback.x >> 16 & 0xFFFF,
							xy_feedback.y & 0xFFFF, xy_feedback.y >> 16 & 0xFFFF,
							z_feedback & 0xFFFF, z_feedback >> 16 & 0xFFFF ]
	return feedback_values

func _set_device_index( index ):
	if index < devices_list.size(): device_index = device_ids_list[ index ]
	if device_index == RemoteInfoState.remote_device_id:
		RemoteDevice.start_processing()
	else:
		RemoteDevice.stop_processing()

func _set_axis_index( index ):
	if index < axes_list.size(): axis_index = index
	print( "axis index " + str(axis_index) + " set" )

#func _set_max_effort( value ):
#	max_effort = value / 100.0