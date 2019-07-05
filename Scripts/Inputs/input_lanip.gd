extends Node

enum Variable { POSITION, VELOCITY, ACCELERATION, FORCE, INERTIA, STIFFNESS, DAMPING, TOTAL_NUMBER }

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

func connect_socket( address ):
	var address_parts = address.split( ":" )
	var host = address_parts[ 0 ]
	var port = int(address_parts[ 1 ])
	print( "connecting to %s:%d" % [ host, port ] )
	data_connection.set_dest_address( host, port )
	if not state_connection.is_connected_to_host():
		state_connection.connect_to_host( host, port )
		while state_connection.get_status() == state_connection.STATUS_CONNECTING: 
			print( "connected to %s:%d" % [ host, port ] )
			continue
		if state_connection.is_connected_to_host(): 
			return true
		return false
	return true

func disconnect_socket():
	state_connection.disconnect_from_host()
	data_connection.close()

func set_request( request_code, info_string = "" ):
	if state_connection.is_connected_to_host():
		state_buffer.clear()
		state_buffer.put_u8( request_code )
		state_buffer.put_data( info_string.to_ascii() )
		state_connection.put_data( state_buffer.data_array )
	print( "set request " + str(request_code) + "[" + info_string + "]" )

func update_data():
	if state_connection.is_connected_to_host():
		if state_connection.get_available_bytes() > 0:
			reply_code = state_connection.get_u8()
			var reply_info = state_connection.get_data( state_connection.get_available_bytes() - 1 )
			print( reply_info[ 1 ].get_string_from_ascii() )
			match reply_code:
				InputManager.Reply.CONFIGS_LISTED:
					print( "configs listed" )
					var devices_info_string = reply_info[ 1 ].get_string_from_ascii()
					available_devices = parse_json( devices_info_string )[ "robots" ]
				InputManager.Reply.GOT_CONFIG:
					print( "got listed" )
					var device_info_string = reply_info[ 1 ].get_string_from_ascii()
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
	if state_connection.is_connected_to_host():
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