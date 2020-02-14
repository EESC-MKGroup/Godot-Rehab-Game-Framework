extends Spatial

onready var movement_range = $Ground/Platform.mesh.size.z

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
						   GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

var control_values = [ GameManager.get_default_controls(), GameManager.get_default_controls() ]

var is_playing = false

static func get_player_variables():
	return [ "Ball X", "Ball Z" ]

func _ready():
	$GUI.set_timeouts( 5.0, 10.0 )
	for input_axis in input_axes:
		input_axis.position_scale = movement_range
		input_axis.force_scale = 1.0

func connect_server():
	GameConnection.connect_server( 1 )
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )
	$GUI.disconnect( "game_timeout", self, "_on_GUI_game_timeout" )

func _on_players_connected( player_ids ):
	print( "received player ids ", player_ids )
	rpc( "register_players", player_ids )
	$GUI/RightPanel/StartButton.pressed = true
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
	control_values[ 0 ][ GameManager.IMPEDANCE ] = $Ground/Platform/Ball.set_local_impedance( impedance[ 0 ], impedance[ 1 ] )
	control_values[ 1 ][ GameManager.IMPEDANCE ] = $Ground/Platform/Ball.set_local_impedance( impedance[ 0 ], impedance[ 1 ] )
	# input_axes[ 0 ].force_scale = difficulty_adaption( impedance[ 2 ] )
	# input_axes[ 1 ].force_scale = difficulty_adaption( impedance[ 2 ] )
	$Ground/Platform/Ball.update_remote()
	control_values[ 0 ][ GameManager.FEEDBACK ] = $Ground/Platform/Ball.feedback_force.x
	control_values[ 1 ][ GameManager.FEEDBACK ] = $Ground/Platform/Ball.feedback_force.z
	
	$Ground/Platform/Ball/InputArrow.update( Vector3( input_axes[ 0 ].force[ 1 ], 0, input_axes[ 1 ].force[ 1 ] ) )
	$Ground/Platform/Ball/FeedbackArrow.update( Vector3( input_axes[ 0 ].feedback[ 1 ], 0, input_axes[ 1 ].feedback[ 1 ] ) )
	
	if is_playing:
		DataLog.register_values( [ control_values[ 0 ][ GameManager.SETPOINT ],
								   control_values[ 0 ][ GameManager.POSITION ], 
								   $Ground/Platform/Ball.linear_velocity.x, $Ground/Platform/Ball.local_acceleration.x,
								   input_axes[ 0 ].force[ 0 ], input_axes[ 0 ].feedback[ 0 ],
								   impedance[ 0 ], impedance[ 1 ], impedance[ 2 ] ] )

func _on_GUI_game_toggle( started ):
	for input_axis in input_axes:
		input_axis.setpoint = 0.0
	is_playing = true

func _on_GUI_game_timeout( timeouts_count ):
	var target = $Ground/Platform/Ball.translation
	target.x = rand_range( -movement_range / 3, movement_range / 3 )
	target.z = 0.0#rand_range( -movement_range / 3, movement_range / 3 )
	rpc( "set_target", target )

puppetsync func set_target( target ):
	print( "set target: ", target )
	if is_playing:
		$GUI.reset_timer()
		$Ground/Platform/Target.translation = target
		control_values[ 0 ][ GameManager.SETPOINT ] = target.x
		control_values[ 1 ][ GameManager.SETPOINT ] = target.z
		input_axes[ 0 ].setpoint = control_values[ 0 ][ GameManager.SETPOINT ]
		input_axes[ 1 ].setpoint = control_values[ 1 ][ GameManager.SETPOINT ]
