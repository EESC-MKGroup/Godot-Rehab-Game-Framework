extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axis_1 = GameManager.get_player_control( get_player_variables()[ 0 ] )
onready var input_axis_2 = GameManager.get_player_control( get_player_variables()[ 1 ] )

onready var paddles_1 = $Ground/Platform/Paddles1
onready var paddles_2 = $Ground/Platform/Paddles2
onready var target = $Ground/Platform/PaddlesTarget

onready var ball_cast = $Ground/Platform/Ball/RayCast

static func get_player_variables():
	return [ "Paddles 1", "Paddles 2" ]

func connect_server():
	GameConnection.connect_server( 2 ) 
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )
	GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 1: 
		paddles_1 = $Ground/Platform/Paddles2
		paddles_2 = $Ground/Platform/Paddles1
	GameConnection.set_as_master( paddles_1 )
	target.show()

func _on_players_connected():
	paddles_1.rpc( "enable" )
	paddles_2.rpc( "enable" )
	$Ground/Platform/Ball.rpc( "enable" )
	$Ground/Platform/Ball.reset()
	target.show()

func _physics_process( delta ):
	$GUI.display_force( input_axis_1.get_force() * movement_range )
	paddles_1.external_force.z = input_axis_1.get_force() * movement_range
	paddles_2.external_force.z = input_axis_2.get_force() * movement_range
	input_axis_1.set_force( paddles_1.feedback_force.lenght() / movement_range )
	input_axis_2.set_force( paddles_2.feedback_force.lenght() / movement_range )
	$GUI.display_position( paddles_1.translation.length() )
	
	ball_cast.cast_to = $Ground/Platform/Ball.linear_velocity.normalized() * movement_range
	$Ground/Platform/Ball.hide()
	if ball_cast.is_colliding():
		$Ground/Platform/Ball.show()
		target.global_transform.origin = ball_cast.get_collision_point()
		target.look_at( target.translation + ball_cast.get_collision_normal(), Vector3.UP )
	input_axis_1.set_position( target.translation.z / movement_range )
	$GUI.display_setpoint( target.translation.z / movement_range )

func _on_GUI_game_toggle( started ):
	input_axis_1.set_position( 0.0 )
	GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	#input_axis.set_position( 0.0 )

func _on_Boundaries_body_exited( body ):
	body.reset()
