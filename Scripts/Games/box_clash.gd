extends Spatial

onready var boundary_1 = $Ground/Platform/Boundaries/CollisionShape1
onready var boundary_2 = $Ground/Platform/Boundaries/CollisionShape2
onready var movement_range = abs( boundary_1.translation.z - boundary_2.translation.z )

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
						   GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

onready var boxes = [ $Box1, $Box2 ] 
onready var input_arrows = [ $Box1/InputArrow, $Box2/InputArrow ] 
onready var feedback_arrows = [ $Box1/FeedbackArrow, $Box2/FeedbackArrow ] 

var control_values = [ GameManager.get_default_controls(), GameManager.get_default_controls() ]

static func get_player_variables():
	return [ "Box 1", "Box 2" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	$GUI.set_timeouts( 10.0, 1.0 )
	$GUI.set_max_effort( 100.0 )
	$Spring.body_1 = $Box1/Connector
	$Spring.body_2 = $Box2/Connector
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
	for index in range( boxes.size() ):
		boxes[ index ].set_network_master( player_ids[ index ] )
	rpc( "register_players", player_ids )
	GameConnection.connect( "game_timeout", $GUI, "_on_GUI_game_timeout" )
	$BoxTarget.show()

remote func register_players( player_ids ):
	for index in range( boxes.size() ):
		boxes[ index ].set_network_master( player_ids[ index ] )
	if get_tree().get_network_unique_id() == player_ids[ 1 ]: 
		$Camera.rotate_y( PI )
	#box_2.mode = RigidBody.MODE_KINEMATIC
	$BoxTarget.show()
	reset_connection()
	$Spring.stiffness = 0.0
	$Spring.damping = 0.0

func reset_connection():
	for box in boxes:
		box.enable()

func _physics_process( delta ):
	var log_values = []
	
	for index in range( boxes.size() ):
		control_values[ index ][ GameManager.POSITION ] = boxes[ index ].translation.z
		control_values[ index ][ GameManager.INPUT ] = input_axes[ index ].get_input( control_values[ index ][ 0 ] )
		boxes[ index ].external_force = Vector3( 0, 0, control_values[ index ][ GameManager.INPUT ] - $Spring.force )
		var impedance = input_axes[ index ].impedance
		control_values[ index ][ GameManager.IMPEDANCE ] = boxes[ index ].set_local_impedance( impedance[ 0 ], impedance[ 1 ] )
		# input_axes[ index ].force_scale = difficulty_adaption( impedance[ 2 ] )
		control_values[ index ][ GameManager.FEEDBACK ] = boxes[ index ].feedback_force.z
		boxes[ index ].update_remote()
		input_axes[ index ].feedback = control_values[ index ][ GameManager.FEEDBACK ]
		input_arrows[ index ].update( Vector3( 0, 0, input_axes[ index ].force[ 1 ] ) )
		feedback_arrows[ index ].update( boxes[ index ].feedback_force )
		
		control_values[ index ][ GameManager.DELAY ] = boxes[ index ].network_delay
		
		for value in control_values[ index ]: log_values.append( value )
	
	DataLog.register_values( log_values )

puppet func set_target( new_position, is_active ):
	$BoxTarget.translation.z = new_position
	control_values[ 0 ][ GameManager.SETPOINT ] = new_position
	control_values[ 1 ][ GameManager.SETPOINT ] = -new_position
	for index in range( input_axes.size() ):
		input_axes[ index ].setpoint = control_values[ index ][ GameManager.SETPOINT ]
	if is_active: $BoxTarget.show()
	else: $BoxTarget.hide()

func _on_GUI_game_toggle( started ):
	for input_axis in input_axes:
		input_axis.setpoint = 0.0
	GameConnection.rpc( "register_player" )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	$BoxTarget.translation.z = rand_range( -movement_range / 2, movement_range / 2 )
	rpc( "set_target", $BoxTarget.translation.z, ( timeouts_count % 2 == 0 ) )
