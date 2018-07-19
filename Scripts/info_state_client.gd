extends Node

enum Request { GET_INFO = 1, DISABLE, ENABLE, RESET, PASSIVATE, OPERATE, OFFSET, CALIBRATE, PREPROCESS, SET_USER, SET_CONFIG }
enum Reply { GOT_INFO = 1, DISABLED, ENABLED, ERROR, PASSIVE, OPERATING, OFFSETTING, CALIBRATING, PREPROCESSING, USER_SET, CONFIG_SET }

const LOCAL_DEVICE_AXES_NUMBER = 4

signal state_changed
signal client_connected

var connection = StreamPeerTCP.new()

var devices_list = []
var axes_list = []
var current_device = 0
var current_axis = 0


func _ready():
	set_process( false )

func _process( delta ):
	var reply_code = connection.get_u8()
	if reply_code == Reply.GOT_INFO:
		var remote_device_info_string = connection.get_string()
		var remote_device_info = parse_json( remote_device_info_string )
		_add_remote_device_input( remote_device_info[ "id" ], remote_device_info[ "axes" ] )
		_update_axes_list( remote_device_info[ "axes" ] )
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

func get_devices_list():
	return devices_list

func get_axes_list( device_index ):
	return axes_list[ device_index ]

func _add_remote_device_input( device_name, device_axes ):
	var controller_mapping = RemoteAxisClient.DEVICE_ID + "," + device_name
	if device_axes.size() > 0:
		for axis_index in range( device_axes.size() ):
			controller_mapping += "," + device_axes[ axis_index ] + ":a" + str(axis_index)
		Input.add_joy_mapping( controller_mapping, true )

func _update_axes_list( remote_axes_list ):
	devices_list.clear()
	axes_list.clear()
	var devices = Input.get_connected_joypads()
	for device in devices:
		devices_list.append( Input.get_joy_name( device ) )
		axes_list.append( [] )
		for axis_index in range( LOCAL_DEVICE_AXES_NUMBER ):
			axes_list.append( device_name + "-" + Input.get_joy_axis_string( axis_index ) ) 
	axes_list[ -1 ] = remote_axes_list