extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axis_1 = GameManager.get_player_control( get_player_variables()[ 0 ] )
onready var input_axis_2 = GameManager.get_player_control( get_player_variables()[ 1 ] )

onready var target = $Ground/Platform/PaddlesTarget
onready var ball_cast = $Ground/Platform/Ball/RayCast

onready var player_paddles = $Ground/Platform/Paddles1
onready var player_input_axis = input_axis_1

static func get_player_variables():
	return [ "Paddles 1", "Paddles 2" ]

func connect_server():
	GameConnection.connect_server( 2 ) 
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )

func _on_players_connected( player_ids ):
	print( "received player ids ", player_ids )
	$Ground/Platform/Paddles1.set_network_master( player_ids[ 0 ] )
	$Ground/Platform/Paddles2.set_network_master( player_ids[ 1 ] )
	rpc( "register_players", player_ids )
	#GameConnection.connect( "game_timeout", $GUI, "_on_GUI_game_timeout" )
	$Ground/Platform/PaddlesTarget.show()

remote func register_players( player_ids ):
	$Ground/Platform/Paddles1.set_network_master( player_ids[ 0 ] )
	$Ground/Platform/Paddles2.set_network_master( player_ids[ 1 ] )
	if get_tree().get_network_unique_id() == player_ids[ 1 ]: 
		player_paddles = $Ground/Platform/Paddles2
		player_input_axis = input_axis_2
		$Camera.rotate_y( PI / 2 )
	$Ground/Platform/PaddlesTarget.show()
	reset_connection()

func reset_connection():
	$Ground/Platform/Paddles1.enable()
	$Ground/Platform/Paddles2.enable()

func _physics_process( delta ):
	$GUI.display_force( input_axis_1.get_force() )
	$Ground/Platform/Paddles1.external_force.z = input_axis_1.get_force()
	$Ground/Platform/Paddles2.external_force.z = input_axis_2.get_force()
	input_axis_1.set_force( $Ground/Platform/Paddles1.feedback_force.z )
	input_axis_2.set_force( $Ground/Platform/Paddles2.feedback_force.z )
	$GUI.display_position( player_paddles.translation.z )
	
	ball_cast.cast_to = $Ground/Platform/Ball.linear_velocity.normalized() * movement_range
	$Ground/Platform/Ball.hide()
	if ball_cast.is_colliding():
		$Ground/Platform/Ball.show()
		target.global_transform.origin = ball_cast.get_collision_point()
		target.look_at( target.translation + ball_cast.get_collision_normal(), Vector3.UP )
	input_axis_1.set_position( target.translation.z / movement_range )
	input_axis_2.set_position( target.translation.x / movement_range )
	$GUI.display_setpoint( target.translation.z )

func _on_GUI_game_toggle( started ):
	input_axis_1.set_position( 0.0 )
	input_axis_2.set_position( 0.0 )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	#input_axis.set_position( 0.0 )

func _on_Boundaries_body_exited( body ):
	body.reset()
