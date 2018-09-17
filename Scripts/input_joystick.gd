extends Node

var device_id = 0
var state = 0

var device_setpoints = [ 0, 0, 0, 0, 0, 0 ]

func _ready():
	pass

func connect_socket( string_id ):
	var device_index = int(string_id)
	var device_ids_list = Input.get_connected_joypads()
	device_id = device_ids_list[ device_index ]
	return true

func disconnect_socket():
	pass

func read_device():
	pass

func set_state( new_state ):
	state = new_state

func get_state():
	return state

func get_info():
	var device_info = {}
	device_info[ "id" ] = Input.get_joy_name( device_id )
	device_info[ "axes" ] = []
	for axis in [ 0, 1, 2, 3, 4, 5 ]:
		device_info[ "axes" ].append( Input.get_joy_axis_string( axis ) )
	return device_info

func get_axis_position( axis ):
	return Input.get_joy_axis( device_id, axis )

func get_axis_force( axis ):
	return Input.get_joy_axis( device_id, axis )

func set_axis_position( axis, value ):
	device_setpoints[ axis ] = value 
	var x_feedback = device_setpoints[ 0 ] | ( device_setpoints[ 1 ] << 16 )
	var y_feedback = device_setpoints[ 2 ] | ( device_setpoints[ 3 ] << 16 )
	var z_feedback = device_setpoints[ 4 ] | ( device_setpoints[ 5 ] << 16 )
	#z_feedback += device_setpoints[ 6 ] | ( device_setpoints[ 7 ] << 16 )
	Input.start_joy_vibration( device_id, x_feedback, y_feedback, z_feedback )