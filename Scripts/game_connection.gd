extends Node

const SERVER_PORT = 50004

const PACKET_SIZE = 512

const TYPE_VALUES_NUMBER = 4

var peer = NetworkedMultiplayerENet.new()
var peed_id = -1

var networkDelay = 0.0

var input_buffer = StreamPeerBuffer.new()
var output_buffer = StreamPeerBuffer.new()

var remote_values = {}
var local_values = {}

var receive_thread = Thread.new()
var is_receiving = false

var input_delays = {}

func _ready():
	input_buffer.resize( PACKET_SIZE )
	output_buffer.resize( PACKET_SIZE )
	get_tree().connect( "network_peer_connected", self, "_on_peer_connected" )
	get_tree().connect( "network_peer_disconnected", self, "_on_peer_disconnected" )
	get_tree().connect( "connected_to_server", self, "_on_connected_to_server" )
	get_tree().connect( "connection_failed", self, "_on_connection_failed" )
	get_tree().connect( "server_disconnected", self, "_on_server_disconnected" )

func connect_client( host ):
	peer.create_client( host, SERVER_PORT )
	peer.set_target_peer( NetworkedMultiplayerPeer.TARGET_PEER_SERVER )
	get_tree().set_network_peer( peer )

func connect_server( max_clients=2 ):
	peer.create_server( SERVER_PORT, max_clients )
	peer.set_target_peer( NetworkedMultiplayerPeer.TARGET_PEER_BROADCAST )
	get_tree().set_network_peer( peer )

func shutdown():
	set_process( false )
	if is_receiving:
		is_receiving = false
		receive_thread.wait_to_finish()
	peer.disconnect()

func set_local_value( object_id, value_type, value_index, value ):
	var local_key = object_id << 8 | value_type
	
	if not local_values.has( local_key ): local_values[ local_key ] = [].resize( TYPE_VALUES_NUMBER )
	
	print( "updating value [" + str(local_key) + "," + str(value_index) + "]: " + local_values[ local_key ][ value_index ].ToString() + " -> " + value.ToString() );
	local_values[ local_key ][ value_index ] = value;

func get_remote_value( object_id, value_type, value_index ):
	var remote_key = object_id << 8 | value_type
	
	if remote_values.has( remote_key ): return remote_values[ remote_key ][ value_index ] 
	
	return 0.0;

func receive_data():
	is_receiving = true
	while( is_receiving ):
		input_buffer.set_position( 0 )
		input_buffer.put_data( peer.get_packet() )
		var inputs_number = input_buffer.get_u8()
		for input_index in range( inputs_number ):
			var object_id = input_buffer.get_u8()
			var value_type = input_buffer.get_u8()
			for value_index in range( TYPE_VALUES_NUMBER ):
				remote_values[ object_id << 8 | value_type ][ value_index ] = input_buffer.get_float()

func _process( delta ):
	output_buffer.seek( 0 )
	var axes_number = InfoStateClient.remote_axis_list.size()
	var feedbacks_list = InputAxis.get_feedbacks()
	output_buffer.put_u8( axes_number )
	for axis_index in range( axes_number ):
		output_buffer.put_u8( axis_index )
		for variable in range( Variable.TOTAL_NUMBER ):
			var output = feedbacks_list[ axis_index ] if variable == Variable.POSITION else 0
			output_buffer.put_float( output )
	peer.put_data( output_buffer.data_array )

func _on_peer_connected():
	pass

func _on_peer_disconnected():
	pass

func _on_connected_to_server():
	pass

func _on_connection_failed():
	pass

func _on_server_disconnected():
	pass

#public float GetNetworkDelay( byte objectID ) 
#	if( inputDelays.ContainsKey( objectID ) ) return inputDelays[ objectID ]
#	return 0.0 