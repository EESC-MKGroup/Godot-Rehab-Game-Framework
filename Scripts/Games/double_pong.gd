extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
                           GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

onready var target = $Ground/Platform/PaddlesTarget
onready var ball_cast = $Ground/Platform/Ball/RayCast

onready var paddles = [ $Ground/Platform/Paddles1, $Ground/Platform/Paddles2 ]

var control_values = [ [ 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0 ] ]

static func get_player_variables():
	return [ "Paddles 1", "Paddles 2" ]

func connect_server():
	GameConnection.connect_server( 2 ) 
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )

func _on_players_connected( player_ids ):
	print( "received player ids ", player_ids )
	for index in range( paddles.size() ):
		paddles[ index ].set_network_master( player_ids[ index ] )
	rpc( "register_players", player_ids )
	#GameConnection.connect( "game_timeout", $GUI, "_on_GUI_game_timeout" )
	$Ground/Platform/PaddlesTarget.show()

remote func register_players( player_ids ):
	for index in range( paddles.size() ):
		paddles[ index ].set_network_master( player_ids[ index ] )
	if get_tree().get_network_unique_id() == player_ids[ 1 ]: 
		$Camera.rotate_y( PI / 2 )
	$Ground/Platform/PaddlesTarget.show()
	reset_connection()

func reset_connection():
	for paddle in paddles:
		paddle.enable()

func _physics_process( delta ):
	for index in range( paddles.size() ):
		control_values[ index ][ 0 ] = paddles[ index ].translation.z
		control_values[ index ][ 2 ] = input_axes[ index ].get_force()
		paddles[ index ].external_force = Vector3( 0, 0, control_values[ index ][ 2 ] )
		control_values[ index ][ 3 ] = paddles[ index ].feedback_force.z
		paddles[ index ].update_remote()
		input_axes[ index ].set_force( control_values[ index ][ 3 ] )
		
		control_values[ index ][ 4 ] = paddles[ index ].network_delay
	
	ball_cast.cast_to = $Ground/Platform/Ball.linear_velocity.normalized() * movement_range
	$Ground/Platform/Ball.hide()
	if ball_cast.is_colliding():
		$Ground/Platform/Ball.show()
		target.global_transform.origin = ball_cast.get_collision_point()
		target.look_at( target.translation + ball_cast.get_collision_normal(), Vector3.UP )
	control_values[ 0 ][ 1 ] = target.translation.z
	control_values[ 1 ][ 1 ] = target.translation.x
	for index in range( input_axes.size() ):
		input_axes[ index ].set_position( control_values[ index ][ 1 ] / movement_range )

func _on_GUI_game_toggle( started ):
	for input_axis in input_axes:
		input_axis.set_position( 0.0 )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	#input_axis.set_position( 0.0 )

func _on_Boundaries_body_exited( body ):
	body.reset()
