extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
						   GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

var control_values = [ GameManager.get_default_controls(), GameManager.get_default_controls() ]

static func get_player_variables():
	return [ "Ball X", "Ball Z" ]

func _ready():
	for input_axis in input_axes:
		input_axis.position_scale = movement_range
		input_axis.force_scale = 1.0

func connect_server():
	GameConnection.connect_server( 1 )
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )

func _on_players_connected( player_ids ):
	print( "received player ids ", player_ids )
	rpc( "register_players", player_ids )
	#GameConnection.connect( "game_timeout", $GUI, "_on_GUI_game_timeout" )
	$Ground/Platform/Target.show()

remote func register_players( player_ids ):
	$Ground/Platform/Target.show()
	$Ground/Platform/Ball.set_network_master( get_tree().get_network_unique_id() )
	reset_connection()

func reset_connection():
	$Ground/Platform/Ball.enable()

func _physics_process( delta ):
	var impedance = [ 0.0, 0.0, 0.0 ]
	control_values[ 0 ][ GameManager.POSITION ] = $Ground/Platform/Ball.translation.x
	control_values[ 1 ][ GameManager.POSITION ] = $Ground/Platform/Ball.translation.z
	for index in range( input_axes.size() ):
		control_values[ index ][ GameManager.INPUT ] = input_axes[ index ].get_input( control_values[ index ][ GameManager.POSITION ] )
		input_axes[ index ].feedback = control_values[ index ][ GameManager.FEEDBACK ]
		control_values[ index ][ GameManager.DELAY ] = $Ground/Platform/Ball.network_delay
		for i in range( impedance.size() ): impedance[ i ] += input_axes[ index ].impedance[ i ]
	$Ground/Platform/Ball.external_force = Vector3( control_values[ 0 ][ GameManager.INPUT ], 0, control_values[ 1 ][ GameManager.INPUT ] )
	control_values[ 0 ][ GameManager.IMPEDANCE ] = $Ground/Platform/Ball.set_system( impedance )
	control_values[ 1 ][ GameManager.IMPEDANCE ] = $Ground/Platform/Ball.set_system( impedance )
	$Ground/Platform/Ball.update_remote()
	control_values[ 0 ][ GameManager.FEEDBACK ] = $Ground/Platform/Ball.feedback_force.x
	control_values[ 1 ][ GameManager.FEEDBACK ] = $Ground/Platform/Ball.feedback_force.z
	
	$Ground/Platform/Ball/InputArrow.update( $Ground/Platform/Ball.external_force )
	$Ground/Platform/Ball/FeedbackArrow.update( $Ground/Platform/Ball.feedback_force )

func _on_GUI_game_toggle( started ):
	for input_axis in input_axes:
		input_axis.setpoint = 0.0

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	var target_x = rand_range( -movement_range / 4, movement_range / 4 )
	var target_z = rand_range( -movement_range / 4, movement_range / 4 )
	$Ground/Platform/Target.translation = Vector3( target_x, 0.0, target_z )
	input_axes[ 0 ].setpoint = target_x
	input_axes[ 1 ].setpoint = target_z
