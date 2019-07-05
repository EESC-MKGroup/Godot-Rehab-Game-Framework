extends Node

enum Variable { POSITION, VELOCITY, ACCELERATION, FORCE, INERTIA, STIFFNESS, DAMPING, TOTAL_NUMBER }

const STATE_SERVER_PORT = 50000
const DATA_SERVER_PORT = 50001 

const BUFFER_SIZE = 512

var state_connection = StreamPeerTCP.new()
var state_buffer = StreamPeerBuffer.new()

var data_connection = PacketPeerUDP.new()
var input_buffer = StreamPeerBuffer.new()
var output_buffer = StreamPeerBuffer.new()

var available_devices = []
var device_info = {}

var device_id = 0
var reply_code = 0

var positions = [ 0 ]
var forces = [ 0 ]

static func get_id():
	return "IP"

func _ready():
	state_buffer.resize( BUFFER_SIZE )
	input_buffer.resize( BUFFER_SIZE )
	output_buffer.resize( BUFFER_SIZE )

func connect_socket( host ):
	data_connection.set_dest_address( host, DATA_SERVER_PORT )
	if not state_connection.is_connected_to_host():
		state_connection.connect_to_host( host, STATE_SERVER_PORT )
		while state_connection.get_status() == state_connection.STATUS_CONNECTING: 
			print( "connecting to %s:%d" % [ host, STATE_SERVER_PORT ] )
			continue
		if state_connection.is_connected_to_host(): 
			return true
		return false
	return true

func disconnect_socket():
	state_connection.disconnect_from_host()
	data_connection.close()

func set_request( request_code, info = "" ):
	if state_connection.is_connected_to_host():
		state_buffer.seek( 0 )
		state_buffer.put_u8( request_code )
		state_buffer.put_string( info )
		state_connection.put_data( state_buffer.data_array )
	print( "set request " + str(request_code) )

func _process( delta ):
	if state_connection.get_available_bytes() > 0:
		reply_code = state_connection.get_u8()
		match reply_code:
			InputManager.Reply.CONFIGS_LISTED:
				var devices_info_string = state_connection.get_string()
				available_devices = parse_json( devices_info_string )[ "robots" ]
			InputManager.Reply.GOT_CONFIG:
				var device_info_string = state_connection.get_string()
				device_info = parse_json( device_info_string )
	if data_connection.get_available_packet_count() > 0:
		input_buffer.set_position( 0 )
		input_buffer.put_data( data_connection.get_packet() )
		var inputs_number = input_buffer.get_u8()
		for input_index in range( inputs_number ):
			var axis_index = input_buffer.get_u8()
			for variable in range( Variable.TOTAL_NUMBER ):
				if variable == Variable.POSITION: positions[ axis_index ] = input_buffer.get_float()
				elif variable == Variable.FORCE: forces[ axis_index ] = input_buffer.get_float()

func get_reply():
	return reply_code

func get_available_devices():
	return available_devices

func get_device_info():
	return device_info

func get_axis_positions():
	return positions

func get_axis_forces():
	return forces

func set_axis_setpoints( position_setpoints, force_setpoints ):
	output_buffer.seek( 0 )
	var axes_number = position_setpoints.size()
	output_buffer.put_u8( axes_number )
	for axis_index in range( axes_number ):
		output_buffer.put_u8( axis_index )
		for variable in range( Variable.TOTAL_NUMBER ):
			var output = 0.0
			if variable == Variable.POSITION: output = position_setpoints[ axis_index ]
			elif variable == Variable.FORCE: output = force_setpoints[ axis_index ]
			output_buffer.put_float( output )
	data_connection.put_packet( output_buffer.data_array )