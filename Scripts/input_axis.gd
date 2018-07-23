extends Node

const LOCAL_DEVICE_AXES = [ 0, 1, 2, 3, 6, 7 ]

var device_index = 0 setget _set_device_index
var axis_index = 0 setget _set_axis_index

func 

func get_value():
	return Input.get_joy_axis( device_index, axis_index )

func set_feedback( setpoint_value ):
	var device_setpoints = [ [ 0, 0 ], [ 0, 0 ], [ 0, 0 ] ]
	device_setpoints[ device_index ][ axis_index ] = setpoint_value 
	var x_feedback = device_setpoints[ 0 ][ 0 ] | ( device_setpoints[ 0 ][ 1 ] << 16 )
	var y_feedback = device_setpoints[ 1 ][ 0 ] | ( device_setpoints[ 1 ][ 1 ] << 16 )
	var z_feedback = device_setpoints[ 2 ][ 0 ] | ( device_setpoints[ 2 ][ 1 ] << 16 )
	Input.start_joy_vibration( device_index, x_feedback, y_feedback, z_feedback )

func get_feedbacks( feedback_device_index ):
	var xy_feedback = Input.get_joy_vibration_strength( feedback_device_index )
	var z_feedback = Input.get_joy_vibration_duration( feedback_device_index )
	var feedback_values = [ xy_feedback.x & 0xFFFF, xy_feedback.x >> 16 & 0xFFFF,
							xy_feedback.y & 0xFFFF, xy_feedback.y >> 16 & 0xFFFF,
							z_feedback & 0xFFFF, z_feedback >> 16 & 0xFFFF ]
	return feedback_values

