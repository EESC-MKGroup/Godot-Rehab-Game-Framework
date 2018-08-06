extends Node

enum Request { GET_INFO = 1, DISABLE, ENABLE, RESET, PASSIVATE, OPERATE, OFFSET, CALIBRATE, PREPROCESS, SET_USER, SET_CONFIG }
enum Reply { GOT_INFO = 1, DISABLED, ENABLED, ERROR, PASSIVE, OPERATING, OFFSETTING, CALIBRATING, PREPROCESSING, USER_SET, CONFIG_SET }

const SERVER_PORT = 50000

const REMOTE_DEVICE_GUID = "ff"

const LOCAL_DEVICE_AXES_NUMBER = 4

signal reply_received
signal client_connected

var connection = StreamPeerTCP.new()

var remote_device_name = "" setget ,_get_remote_device_name
var remote_device_id = -1 setget ,_get_remote_device_id
var remote_axes_list = [] setget ,_get_remote_axes_list

func _ready():
	set_process( false )

func _process( delta ):
	var reply_code = connection.get_u8()
	if reply_code == Reply.GOT_INFO:
		var remote_device_info_string = connection.get_string()
		var remote_device_info = parse_json( remote_device_info_string )
		remote_device_name = remote_device_info[ "id" ]
		remote_axes_list = remote_device_info[ "axes" ]
		_add_remote_device_input()
		_update_remote_device()
		emit_signal( "reply_received", reply_code )

func connect_client( host ):
	if not connection.is_connected_to_host():
		connection.connect_to_host( host, SERVER_PORT )
		while connection.get_status() == connection.STATUS_CONNECTING: 
			print( "connecting to %s:%d" % [ host, SERVER_PORT ] )
			continue
		if connection.is_connected_to_host(): 
			emit_signal( "client_connected" )
			set_process( true )

func send_request( request_code ):
	if connection.is_connected_to_host():
		connection.put_u8( request_code )

func _get_remote_device_id():
	return remote_device_id

func _get_remote_device_name():
	return remote_device_name

func _get_remote_axes_list():
	return remote_axes_list

func _add_remote_device_input():
	var controller_mapping = REMOTE_DEVICE_GUID + "," + remote_device_name
	if remote_axes_list.size() > 0:
		for axis_index in range( remote_axes_list.size() ):
			controller_mapping += "," + remote_axes_list[ axis_index ] + ":a" + str(axis_index)
		Input.add_joy_mapping( controller_mapping, true )

func _update_remote_device():
	var device_ids_list = Input.get_connected_joypads()
	for device_id in device_ids_list:
		if Input.get_joy_guid( device_id ) == REMOTE_DEVICE_GUID:
			remote_device_id = device_id

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		connection.disconnect_from_host()