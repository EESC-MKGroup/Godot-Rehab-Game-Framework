extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
						   GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

onready var target = $Ground/Platform/PaddlesTarget
onready var ball_cast = $Ground/Platform/Ball/RayCast

onready var paddles = [ $Ground/Platform/Paddles1, $Ground/Platform/Paddles2 ]

var control_values = [ GameManager.get_default_controls(), GameManager.get_default_controls() ]

static func get_player_variables():
	return [ "Paddles 1", "Paddles 2" ]

func _ready():
	for input_axis in input_axes:
		input_axis.position_scale = movement_range
		input_axis.force_scale = 1.0

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
		control_values[ index ][ GameManager.POSITION ] = paddles[ index ].translation.z
		control_values[ index ][ GameManager.INPUT ] = input_axes[ index ].get_input( paddles[ index ].translation.z )
		paddles[ index ].external_force = Vector3( 0, 0, control_values[ index ][ GameManager.INPUT ] )
		control_values[ index ][ GameManager.FEEDBACK ] = paddles[ index ].feedback_force.z
		paddles[ index ].update_remote()
		input_axes[ index ].feedback = control_values[ index ][ GameManager.FEEDBACK ]
		control_values[ index ][ GameManager.IMPEDANCE ] = paddles[ index ].set_system( input_axes[ index ].impedance )
		
		control_values[ index ][ GameManager.DELAY ] = paddles[ index ].network_delay
	
	ball_cast.cast_to = $Ground/Platform/Ball.linear_velocity.normalized() * movement_range
	$Ground/Platform/Ball.hide()
	if ball_cast.is_colliding():
		$Ground/Platform/Ball.show()
		target.global_transform.origin = ball_cast.get_collision_point()
		target.look_at( target.translation + ball_cast.get_collision_normal(), Vector3.UP )
	control_values[ 0 ][ GameManager.SETPOINT ] = target.translation.z
	control_values[ 1 ][ GameManager.SETPOINT ] = target.translation.x
	for index in range( input_axes.size() ):
		input_axes[ index ].setpoint = control_values[ index ][ GameManager.SETPOINT ]

func _on_GUI_game_toggle( started ):
	for input_axis in input_axes:
		input_axis.setpoint = 0.0

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	#input_axis.setpoint = 0.0

func _on_Boundaries_body_exited( body ):
	body.reset()
