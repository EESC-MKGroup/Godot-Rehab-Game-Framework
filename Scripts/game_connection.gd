extends Node

const SERVER_PORT = 50004

const PACKET_SIZE = 512

const TYPE_VALUES_NUMBER = 4

signal clients_connected

var peer = NetworkedMultiplayerENet.new()

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
				var remote_key = object_id << 8 | value_type
				remote_values[ remote_key ][ value_index ] = input_buffer.get_float()

func _process( delta ):
	output_buffer.seek( 0 )
	var outputs_number = local_values.size()
	output_buffer.put_u8( outputs_number )
	for local_key in local_values.keys():
		var object_id = local_key >> 8 & 0xFF
		var value_type = local_key & 0xFF
		output_buffer.put_u8( object_id )
		output_buffer.put_u8( object_id )
		for value_index in range( TYPE_VALUES_NUMBER ):
			output_buffer.put_float( local_values[ local_key ][ value_index ] )
	peer.put_data( output_buffer.data_array )

func _on_peer_connected( peer_id ):
	print( "new peer connected: " + str(peer_id) )

func _on_peer_disconnected( peer_id ):
	print( "peer disconnected: " + str(peer_id) )

func _on_connected_to_server():
	var peer_id = peer.get_unique_id()
	print( "peer new unique id: " + str(peer_id) )

func _on_connection_failed():
	print( "connection failed!")

func _on_server_disconnected():
	print( "server disconnected!" )

#public float GetNetworkDelay( byte objectID ) 
#	if( inputDelays.ContainsKey( objectID ) ) return inputDelays[ objectID ]
#	return 0.0 