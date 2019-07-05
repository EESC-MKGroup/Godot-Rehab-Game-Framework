extends Node

var input_device = null
var axis_index = 0

var force_limits = null
var position_limits = null

var is_calibrating = false setget _set_calibration,_get_calibration

var max_effort = 1.0 setget _set_max_effort

func _init( device, index ):
	input_device = device
	axis_index = index

func get_position():
	var position = input_device.get_axis_position( axis_index )
	if is_calibrating: position_limits = _check_limits( position_limits, position )
	elif position_limits != null: position = _normalize( position, position_limits )
	return position * max_effort

func set_position( setpoint ):
	setpoint = _denormalize( setpoint, position_limits )
	input_device.set_axis_position( axis_index, setpoint / max_effort )

func get_force():
	var force = input_device.get_axis_force( axis_index )
	if is_calibrating: force_limits = _check_limits( force_limits, force )
	elif force_limits != null: force = _normalize( force, force_limits )
	return force * max_effort

func set_force( setpoint ):
	setpoint = _denormalize( setpoint, force_limits )
	input_device.set_axis_force( axis_index, setpoint / max_effort )

func _set_calibration( enabled ):
	if enabled: _reset_limits()
	#input_device.state = State.CALIBRATION if enabled else State.OPERATION
	is_calibrating = enabled

func _get_calibration():
	return is_calibrating

func _set_max_effort( value ):
	if value > 100.0: value = 100.0
	elif value < 10.0: value = 10.0
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
	force_limits = null
	position_limits = null