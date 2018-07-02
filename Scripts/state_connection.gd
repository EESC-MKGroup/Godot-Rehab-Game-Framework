extends Node

enum Request { GET_INFO = 1, DISABLE, ENABLE, RESET, PASSIVATE, OPERATE, OFFSET, CALIBRATE, PREPROCESS, SET_USER, SET_CONFIG }
enum Reply { GOT_INFO = 1, DISABLED, ENABLED, ERROR, PASSIVE, OPERATING, OFFSETTING, CALIBRATING, PREPROCESSING, USER_SET, CONFIG_SET }

signal state_changed

var connection = StreamPeerTCP.new()

var info = {}

func _ready():
	set_process( false )

func connect_client( host, port ):
	if not connection.is_connected_to_host():
		connection.connect_to_host( host, port )
		while connection.get_status() == connection.STATUS_CONNECTING: 
			print( "connecting to %s:%d" % [ host, port ] )
			continue
		if connection.is_connected_to_host(): 
			output_status = 1
			set_process( true )

func _process( delta ):
	var reply_code = connection.get_u8()
	if reply_code == Reply.GOT_INFO:
		var info_string = connection.get_string()
		info = parse_json( info_string )
	emit_signal( "state_changed", reply_code )