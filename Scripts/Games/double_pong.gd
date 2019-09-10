extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axis = GameManager.player_controls[ get_player_variables()[ 0 ] ]

onready var target = $Ground/Platform/PaddlesTarget

onready var ball_cast = $Ground/Platform/Ball/RayCast

static func get_player_variables():
	return [ "Player Paddle" ]

func connect_server():
	GameConnection.connect_server( 2 ) 
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )
	GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 0: GameConnection.set_as_master( $Ground/Platform/Paddles1 )
	elif client_id == 1: GameConnection.set_as_master( $Ground/Platform/Paddles2 )

func _on_players_connected():
	$Ground/Platform/Paddles1.rpc( "enable" )
	$Ground/Platform/Paddles2.rpc( "enable" )
	$Ground/Platform/Ball.rpc( "enable" )
	$Ground/Platform/Ball.reset()

func _physics_process( delta ):
	ball_cast.cast_to = $Ground/Platform/Ball.linear_velocity.is_normalized() * movement_range
	$Ground/Platform/Ball.hide()
	if ball_cast.is_colliding():
		$Ground/Platform/Ball.show()
		target.global_transform.origin = ball_cast.get_collision_point()
		target.look_at( target.translation + ball_cast.get_collision_normal(), Vector3.UP )

func get_player_force( body ):
	return body.transform.basis * input_axis.get_force() * movement_range

func get_environment_force( body ):
	return Vector3.ZERO

func set_feedback_force( force ):
	input_axis.set_force( force.lenght() / movement_range )
	input_axis.set_position( target.translation.dot( force ) / force.length() / movement_range )

func set_resulting_position( position ):
	$GUI.display_measure( position.length() )

func _on_GUI_game_toggle( started ):
	input_axis.set_position( 0.0 )
	GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	#input_axis.set_position( 0.0 )

func _on_Boundaries_body_exited( body ):
	body.reset()
