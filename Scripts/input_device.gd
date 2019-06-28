extends Node

enum State { LIST_CONFIGS = 1, GET_CONFIG, SET_CONFIG, SET_USER, DISABLED, ENABLED, RESET, PASSIVE, OPERATION, OFFSET, CALIBRATION }

signal state_changed
signal socket_connected

var interface = null

var positions = [ 0 ]
var forces = [ 0 ]
var position_setpoints = [ 0 ]
var force_setpoints = [ 0 ]

var configuration = "" setget _set_configuration
var user_name = "" setget _set_user
var state = State.DISABLED setget _set_state,_get_state

var string_id = "" setget ,_get_string_id
var axes_list = [] setget ,_get_axes_list
var available_configurations = [] setget ,_get_available_configurations

func _init( input_interface ):
	interface = input_interface
	set_process( false )

func request_available_configurations():
	interface.set_state( State.LIST_CONFIGS )

func _get_available_configurations():
	return available_configurations

func _set_configuration( value ):
	interface.set_state( State.SET_CONFIG, value )

func _set_user( value ):
	interface.set_state( State.SET_USER, value )

func _get_string_id():
	return string_id

func _get_axes_list():
	return axes_list

func get_axis_position( axis_index ):
	return positions[ axis_index ] if axis_index < positions.size() else 0.0

func get_axis_force( axis_index ):
	return forces[ axis_index ] if axis_index < forces.size() else 0.0

func set_axis_setpoint( axis_index, position, force ):
	if axis_index >= position_setpoints.size(): return
	position_setpoints[ axis_index ] = position
	force_setpoints[ axis_index ] = force

func _reset_axes():
	positions = []
	forces = []
	position_setpoints = []
	force_setpoints = []
	for axis in axes_list:
		positions.append( 0.0 )
		forces.append( 0.0 )
		position_setpoints.append( 0.0 )
		force_setpoints.append( 0.0 )

func _get_device_state():
	var reply_code = interface.get_state()
	if state != reply_code:
		if reply_code == State.GET_CONFIG:
			var device_info = interface.get_info()
			string_id = device_info[ "id" ]
			axes_list = device_info[ "axes" ]
			_reset_axes()
		elif reply_code == State.LIST_CONFIGS:
			available_configurations = interface.list_configurations()
		print( "new state " + str(reply_code) )
		emit_signal( "state_changed", reply_code )
		print( "state changed " + str(reply_code) )
	state = reply_code

func _get_device_data():
	for axis_index in range( axes_list.size() ):
		positions[ axis_index ] = interface.get_axis_position( axis_index )
		forces[ axis_index ] = interface.get_axis_force( axis_index )

func _process( delta ):
	interface.set_setpoints( position_setpoints, force_setpoints )
	#hack
	interface.read_device()
	_get_device_state()
	_get_device_data()

func connect_socket( host ):
	if interface != null:
		if interface.connect_socket( host ):
			print( "connected to " + host )
			set_process( true )
			emit_signal( "socket_connected" )

func disconnect_socket():
	set_process( false )
	interface.disconnect_socket()

func _set_state( new_state ):
	interface.set_state( new_state )
	print( "set state " + str(new_state) )

func _get_state():
	return state

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		disconnect_socket()