extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameConnection.is_server:
		GameConnection.connect_server( 2 ) 
		GameConnection.connect( "players_connected", self, "_on_players_connected" )
	else: 
		GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )
		GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 0: $Box1.set_network_master( get_tree().get_network_unique_id() )
	elif client_id == 1: $Box2.set_network_master( get_tree().get_network_unique_id() )

func _on_players_connected():
	$Box1.rpc( "enable" )
	$Box2.rpc( "enable" )
	$Box1.rpc( "update_server", 0.0, 0.0, OS.get_ticks_msec(), OS.get_ticks_msec() )
	$Box2.rpc( "update_server", 0.0, 0.0, OS.get_ticks_msec(), OS.get_ticks_msec() )