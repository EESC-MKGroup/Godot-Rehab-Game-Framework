extends Node

enum State { LIST_CONFIGS = 1, GET_CONFIG, SET_CONFIG, SET_USER, DISABLED, ENABLED, RESET, PASSIVE, OPERATION, OFFSET, CALIBRATION }

signal state_changed
signal socket_connected

const INTERFACE_TYPES = [ "joystick", "lanip", "bluetooth" ]

var interface = null
var interface_index = 0 setget _set_interface,_get_interface
var interfaces_list = {} setget ,_get_interfaces_list

var positions = [ 0 ]
var forces = [ 0 ]
var setpoints = [ 0 ]

var state = State.DISABLED setget _set_state,_get_state

var read_thread = Thread.new()
var is_reading = false

var string_id = "" setget ,_get_string_id
var id = -1 setget ,_get_id
var axes_list = [] setget ,_get_axes_list

func _ready():
	for type_id in INTERFACE_TYPES:
		var plugin = load( "res://Scripts/input_" + type_id + ".gd" )
		if plugin != null: interfaces_list[ type_id ] = plugin.new()
	set_process( false )

func _get_interfaces_list():
	print( interfaces_list.keys() )
	return interfaces_list.keys()

func _get_id():
	return id

func _get_string_id():
	return string_id

func _get_axes_list():
	return axes_list

func _set_interface( index ):
	if index in range( interfaces_list.size() ):
		interface_index = index 
		interface = interfaces_list.values()[ index ]

func _get_interface():
	return interface_index

func get_axis_position( axis ):
	return positions[ axis ] if axis < positions.size() else 0.0

func get_axis_force( axis ):
	return forces[ axis ] if axis < forces.size() else 0.0

func set_axis_setpoint( axis, value ):
	if axis >= setpoints.size(): return
	setpoints[ axis ] = value

func _reset_axes():
	positions = []
	forces = []
	setpoints = []
	for axis in axes_list:
		positions.append( 0.0 )
		forces.append( 0.0 )
		setpoints.append( 0.0 )

func _get_device_state():
	var reply_code = interface.get_state()
	if state != reply_code:
		if reply_code == State.GET_INFO:
			var device_info = interface.get_info()
			string_id = device_info[ "id" ]
			axes_list = device_info[ "axes" ]
			_reset_axes()
		print( "new state " + str(reply_code) )
		emit_signal( "state_changed", reply_code )
		print( "state changed " + str(reply_code) )
	state = reply_code

func _get_device_data():
	for axis in range( axes_list.size() ):
		positions[ axis ] = interface.get_axis_position( axis )
		forces[ axis ] = interface.get_axis_force( axis )

func _run_read_loop( user_data ):
	is_reading = true
	while( is_reading ):
		interface.read_device()
		_get_device_state()
		_get_device_data()

func _process( delta ):
	interface.set_setpoints( setpoints )
	#hack
	interface.read_device()
	_get_device_state()
	_get_device_data()

func connect_socket( host ):
	if interface != null:
		if interface.connect_socket( host ):
			#if not is_reading: read_thread.start( self, "_run_read_loop", null )
			print( "connected to " + host )
			set_process( true )
			emit_signal( "socket_connected" )

func disconnect_socket():
	set_process( false )
	#if is_reading:
	#	is_reading = false
	#	read_thread.wait_to_finish()
	interface.disconnect_socket()

func _set_state( new_state ):
	interface.set_state( new_state )
	print( "set state " + str(new_state) )

func _get_state():
	return state

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		disconnect_socket()