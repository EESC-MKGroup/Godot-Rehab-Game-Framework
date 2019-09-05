extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

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
	if client_id == 0: GameConnection.set_as_master( $Ground/Platform/Paddles1 )
	elif client_id == 1: GameConnection.set_as_master( $Ground/Platform/Paddles2 )

func _on_players_connected():
	$Ground/Platform/Paddles1.rpc( "enable" )
	$Ground/Platform/Paddles2.rpc( "enable" )
	$Ground/Platform/Ball.rpc( "enable" )
	$Ground/Platform/Ball.reset()

func get_player_force( body ):
	return body.transform.basis * input_axis.get_force() * movement_range

func get_environment_force( body ):
	return Vector3.ZERO

func _on_GUI_game_toggle( started ):
	input_axis.set_position( 0.0 )
	GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	input_axis.set_position( 0.0 )

func _on_Boundaries_body_exited(body):
	$Ground/Platform/Ball.reset()
