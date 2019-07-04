extends Spatial

onready var paddles_1 = $Ground/Platform/Paddles1
onready var paddles_2 = $Ground/Platform/Paddles2

onready var input_axis = GameManager.player_controls[ get_player_variables()[ 0 ] ]

static func get_player_variables():
	return [ "Player Paddle" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameConnection.is_server:
		GameConnection.connect_server( 2 ) 
		GameConnection.connect( "players_connected", self, "_on_players_connected" )
	else: 
		GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )
		GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 0: GameConnection.set_as_master( paddles_1 )
	elif client_id == 1: GameConnection.set_as_master( paddles_2 )

func _on_players_connected():
	paddles_1.rpc( "enable" )
	paddles_2.rpc( "enable" )
	paddles_1.rpc( "update_server", 0.0, 0.0, OS.get_ticks_msec(), OS.get_ticks_msec() )
	paddles_2.rpc( "update_server", 0.0, 0.0, OS.get_ticks_msec(), OS.get_ticks_msec() )