extends Node

var input_device = null
var axis_index = 0

var force_limits = [ -0.5, 0.5 ]
var force_range = 1.0
var position_limits = [ -0.5, 0.5 ]
var position_range = 1.0

var is_calibrating = false setget _set_calibration,_get_calibration

var scale = 1.0 setget _set_scale

func _init( device, index ):
	input_device = device
	axis_index = index

func get_position():
	var position = input_device.get_axis_position( axis_index )
	if is_calibrating: position_limits = _check_limits( position_limits, position[ 0 ] )
	else:
		position[ 0 ] = _normalize( position[ 0 ], position_range, position_limits[ 0 ] )
		position[ 1 ] = position[ 1 ] / position_range
		position[ 2 ] = position[ 2 ] / position_range
	return [ position[ 0 ] * scale, position[ 1 ] * scale, position[ 2 ] * scale ]

func set_position( setpoint ):
	setpoint = _denormalize( setpoint, position_range, position_limits[ 0 ] )
	input_device.set_axis_position( axis_index, setpoint / scale )

func get_force():
	var force = input_device.get_axis_force( axis_index )
	if is_calibrating: force_limits = _check_limits( force_limits, force )
	else: force = _normalize( force, force_range, force_limits[ 0 ] )
	return force * scale

func set_force( setpoint ):
	setpoint = _denormalize( setpoint, force_range, force_limits[ 0 ] )
	input_device.set_axis_force( axis_index, setpoint / scale )

func get_impedance(): 
	var impedance = input_device.get_axis_impedance( axis_index )
	if not is_calibrating:
		impedance[ 0 ] = impedance[ 0 ] * position_range / force_range
		impedance[ 1 ] = impedance[ 1 ] * position_range / force_range
		impedance[ 2 ] = impedance[ 2 ] * position_range / force_range
	return impedance

func _set_calibration( enabled ):
	if enabled:
		var force = input_device.get_axis_force( axis_index )
		force_limits = [ force - 0.001, force + 0.001 ]
		force_range = 1.0
		var position = input_device.get_axis_position( axis_index )
		position_limits = [ position - 0.001, position + 0.001 ]
		position_range = 1.0
	else:
		force_range = force_limits[ 1 ] - force_limits[ 0 ]
		position_range = position_limits[ 1 ] - position_limits[ 0 ]
	is_calibrating = enabled

func _get_calibration():
	return is_calibrating

func _set_scale( value ):
	if value > 100.0: value = 100.0
	elif value < 10.0: value = 10.0
	scale = value / 100.0

func _check_limits( limits, value ):
	limits[ 0 ] = min( value, limits[ 0 ] )
	limits[ 1 ] = max( value, limits[ 1 ] )
	return limits

func _normalize( value, value_range, value_min ):
	return ( 2 * ( value - value_min ) / value_range ) - 1.0

func _denormalize( value, value_range, value_min ):
	return ( ( value + 1.0 ) * value_range / 2 ) + value_min