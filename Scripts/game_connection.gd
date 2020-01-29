extends Node

const SERVER_PORT = 50004

signal players_connected( player_ids )

var peer = NetworkedMultiplayerENet.new()
var is_server = false

var network_ids = []
var max_clients_number = 0

func _ready():
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
	max_clients_number = max_clients

func shutdown():
	set_process( false )
	peer.disconnect()
	get_tree().set_network_peer( null )

func _on_peer_connected( peer_id ):
	print( "new peer connected: " + str(peer_id) )
	network_ids.append( peer_id )
	if network_ids.size() >= max_clients_number:
		peer.refuse_new_connections = true
		emit_signal( "players_connected", network_ids )

func _on_peer_disconnected( peer_id ):
	network_ids.remove( network_ids.find( peer_id ) )
	print( "peer disconnected: " + str(peer_id) )

func _on_connected_to_server():
	var peer_id = peer.get_unique_id()
	print( "peer new unique id: " + str(peer_id) )

func _on_connection_failed():
	print( "connection failed!")

func _on_server_disconnected():
	network_ids.clear()
	print( "server disconnected!" )

remote func register_player():
	print( "player registered" )
