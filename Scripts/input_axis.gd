extends Node

var axis_index = 0 setget _set_axis

var input_limits = null
var output_limits = null

var is_calibrating = false setget _set_calibration,_get_calibration

var max_effort = 1.0 setget _set_max_effort

func get_value():
	var position = InputDevice.get_axis_position( axis_index )
	var force = InputDevice.get_axis_force( axis_index )
	if is_calibrating:
		input_limits = _check_limits( input_limits, force )
		output_limits = _check_limits( output_limits, position )
	elif input_limits != null:
		force = _normalize( force, input_limits[ axis_index ] )
	return force * max_effort

func set_feedback( setpoint ):
	setpoint = _denormalize( setpoint, output_limits )
	InputDevice.set_axis_setpoint( axis_index, setpoint / max_effort )

func _set_axis( index ):
	if index < InputDevice.axes_list.size(): axis_index = index
	print( "axis index " + str(axis_index) + " set" )

func _set_calibration( enabled ):
	if enabled: _reset_limits()
	InputDevice.state = InputDevice.CALIBRATION if enabled else InputDevice.OPERATION
	is_calibrating = enabled

func _get_calibration():
	return is_calibrating

func _set_max_effort( value ):
	if value > 100.0: value = 100.0
	elif value < 0.1: value = 0.1
	max_effort = value / 100.0

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
	input_limits = null
	output_limits = null