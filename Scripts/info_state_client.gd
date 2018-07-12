extends Node

enum Request { GET_INFO = 1, DISABLE, ENABLE, RESET, PASSIVATE, OPERATE, OFFSET, CALIBRATE, PREPROCESS, SET_USER, SET_CONFIG }
enum Reply { GOT_INFO = 1, DISABLED, ENABLED, ERROR, PASSIVE, OPERATING, OFFSETTING, CALIBRATING, PREPROCESSING, USER_SET, CONFIG_SET }

signal state_changed
signal client_connected

var connection = StreamPeerTCP.new()

var axes_list = []

func _ready():
	set_process( false )

func _process( delta ):
	var reply_code = connection.get_u8()
	if reply_code == Reply.GOT_INFO:
		var info_string = connection.get_string()
		var info = parse_json( info_string )
		axes_list.clear()
		var robot_name = info[ "id" ]
		for axis_name in info[ "axes" ]:
			axes_list.append( robot_name + "-" + axis_name )
	emit_signal( "state_changed", reply_code )

func connect_client( host, port ):
	if not connection.is_connected_to_host():
		connection.connect_to_host( host, port )
		while connection.get_status() == connection.STATUS_CONNECTING: 
			print( "connecting to %s:%d" % [ host, port ] )
			continue
		if connection.is_connected_to_host(): 
			emit_signal( "client_connected" )
			set_process( true )

func refresh_axes_info():
	if connection.is_connected_to_host():
		connection.put_u8( GET_INFO )

func get_axes_list():
	return axes_list