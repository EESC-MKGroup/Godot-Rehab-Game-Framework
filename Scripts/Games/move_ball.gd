extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
                           GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

var control_values = [ [ 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0 ] ]

static func get_player_variables():
	return [ "Ball X", "Ball Z" ]

func connect_server():
	GameConnection.connect_server( 2 )
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
	for index in range( input_axes.size() ):
		control_values[ index ][ 2 ] = input_axes[ index ].get_force()
		input_axes[ index ].set_force( control_values[ index ][ 3 ] )
		control_values[ index ][ 4 ] = $Ground/Platform/Ball.network_delay
	control_values[ 0 ][ 0 ] = $Ground/Platform/Ball.translation.x
	control_values[ 1 ][ 0 ] = $Ground/Platform/Ball.translation.z
	$Ground/Platform/Ball.external_force = Vector3( control_values[ 0 ][ 2 ], 0, control_values[ 1 ][ 2 ] )
	$Ground/Platform/Ball.update_remote()
	control_values[ 0 ][ 3 ] = $Ground/Platform/Ball.feedback_force.x
	control_values[ 1 ][ 3 ] = $Ground/Platform/Ball.feedback_force.z
	
	$Ground/Platform/Ball/InputArrow.update( $Ground/Platform/Ball.external_force )
	$Ground/Platform/Ball/FeedbackArrow.update( $Ground/Platform/Ball.feedback_force )

func _on_GUI_game_toggle( started ):
	for input_axis in input_axes:
		input_axis.set_position( 0.0 )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	#input_axis.set_position( 0.0 )
