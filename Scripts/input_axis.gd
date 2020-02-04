extends Node

var input_device = null
var axis_index = 0

var position_limits = [ -0.5, 0.5 ]
var position_range = 1.0

var position_offset = 0.0
var force_offset = 0.0

var position = [ 0.0, 0.0, 0.0 ] setget ,_get_position
var setpoint = 0.0 setget _set_position
var force = 0.0 setget ,_get_force
var feedback = 0.0 setget _set_force
var impedance = [ 0.0, 0.0, 0.0 ] setget ,_get_impedance

var is_offsetting = false setget _set_offset
var is_calibrating = false setget _set_calibration,_get_calibration

var position_scale = 1.0 setget _set_position_scale
var force_scale = 1.0 setget _set_force_scale

func _init( device, index ):
	input_device = device
	axis_index = index

func _get_position():
	var raw_position = input_device.get_axis_position( axis_index )
	if is_calibrating:
		position_limits[ 0 ] = min( raw_position[ 0 ], position_limits[ 0 ] )
		position_limits[ 1 ] = max( raw_position[ 0 ], position_limits[ 1 ] )
		position[ 0 ] = raw_position[ 0 ]
		position[ 1 ] = raw_position[ 1 ]
		position[ 2 ] = raw_position[ 2 ]
	else:
		position[ 0 ] = 2 * ( raw_position[ 0 ] - position_offset ) / position_range
		position[ 0 ] = raw_position[ 0 ] * position_scale
		position[ 1 ] = raw_position[ 1 ] / position_range * position_scale
		position[ 2 ] = raw_position[ 2 ] / position_range * position_scale
	return [ position[ 0 ], position[ 1 ], position[ 2 ] ]

func _set_position( setpoint ):
	setpoint = ( setpoint * position_range / 2 ) + position_offset
	input_device.set_axis_position( axis_index, setpoint / position_scale )

func _get_force():
	var raw_force = input_device.get_axis_force( axis_index )
	return ( raw_force - force_offset ) * force_scale

func _set_force( setpoint ):
	input_device.set_axis_force( axis_index, setpoint / force_scale + force_offset )

func _get_impedance(): 
	var raw_impedance = input_device.get_axis_impedance( axis_index )
	if not is_calibrating:
		impedance[ 0 ] = raw_impedance[ 0 ] * position_range / position_scale
		impedance[ 1 ] = raw_impedance[ 1 ] * position_range / position_scale
		impedance[ 2 ] = raw_impedance[ 2 ] * position_range / position_scale
	return impedance

func get_input( player_position ):
	if is_calibrating: return 0.0
	var force = _get_force()
	var position = _get_position()
	var impedance = _get_impedance()
	var position_error = position[ 0 ] - player_position
	var correction = impedance[ 0 ] * position_error - impedance[ 1 ] * position[ 1 ]
	return force + correction * force_scale

func _set_offset( enabled ):
	if enabled:
		position_offset = 0.0
		force_offset = 0.0
	else:
		var raw_position = input_device.get_axis_position( axis_index )
		var raw_force = input_device.get_axis_force( axis_index )
		position_offset = raw_position[ 0 ]
		force_offset = raw_force
	is_offsetting = enabled

func _set_calibration( enabled ):
	if enabled:
		var raw_position = input_device.get_axis_position( axis_index )
		position_limits = [ raw_position[ 0 ] - 0.001, raw_position[ 0 ] + 0.001 ]
		position_range = 1.0
	else:
		position_range = position_limits[ 1 ] - position_limits[ 0 ]
	is_calibrating = enabled

func _get_calibration():
	return is_calibrating

func _set_position_scale( value ):
	position_scale = max( value, 0.1 )

func _set_force_scale( value ):
	#if value > 100.0: value = 100.0
	#elif value < 10.0: value = 10.0
	#force_scale = value / 100.0
	force_scale = max( value, 0.1 )
