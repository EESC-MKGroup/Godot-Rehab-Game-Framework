extends Node

var axis_index = 0 setget _set_axis

var input_limits = null
var output_limits = null

var is_calibrating = false setget _set_calibration,_get_calibration

#var max_effort = 1.0 setget _set_max_effort

func get_value():
	
	return InputDevice.get_axis_value( axis_index )

func set_feedback( value ):
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

func _set_axis( index ):
	if index < axes_list.size(): axis_index = index
	print( "axis index " + str(axis_index) + " set" )

func _set_calibration( enabled ):
	is_calibrating = enabled

func _get_calibration():
	return is_calibrating

#func _set_max_effort( value ):
#	max_effort = value / 100.0