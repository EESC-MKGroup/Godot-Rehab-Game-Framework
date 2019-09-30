extends Spatial

onready var boundary_1 = $Ground/Platform/Boundaries/CollisionShape1
onready var boundary_2 = $Ground/Platform/Boundaries/CollisionShape2
onready var movement_range = abs( boundary_1.translation.z - boundary_2.translation.z )

onready var input_axes = [ GameManager.get_player_control( get_player_variables()[ 0 ] ),
                           GameManager.get_player_control( get_player_variables()[ 1 ] ) ]

onready var boxes = [ $Box1, $Box2 ] 
onready var input_arrows = [ $Box1/InputArrow, $Box2/InputArrow ] 
onready var feedback_arrows = [ $Box1/FeedbackArrow, $Box2/FeedbackArrow ] 

var control_values = []
var player_index = 0

static func get_player_variables():
	return [ "Box 1", "Box 2" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	$GUI.set_timeouts( 10.0, 1.0 )
	$GUI.set_max_effort( 100.0 )
	$Spring.body_1 = $Box1/Connector
	$Spring.body_2 = $Box2/Connector
	for variable_name in get_player_variables():
		control_values.append( [ 0, 0, 0, 0, 0 ] )

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
		player_index = 1
		$Camera.rotate_y( PI )
	#box_2.mode = RigidBody.MODE_KINEMATIC
	$BoxTarget.show()
	reset_connection()
	$Spring.stiffness = 0.0
	$Spring.damping = 0.0

func reset_connection():
	$Box1.enable()
	$Box2.enable()

func _physics_process( delta ):
	for index in range( boxes.size() ):
		control_values[ index ][ 0 ] = boxes[ index ].translation.z
		control_values[ index ][ 2 ] = input_axes[ index ].get_force()
		var input = control_values[ index ][ 2 ] - $Spring.get_force()
		boxes[ index ].external_force = Vector3( 0, 0, input )
		control_values[ index ][ 3 ] = boxes[ index ].feedback_force.z
		boxes[ index ].update_remote()
		input_axes[ index ].set_force( control_values[ index ][ 3 ] )
		input_arrows[ index ].update( control_values[ index ][ 2 ] )
		feedback_arrows[ index ].update( control_values[ index ][ 3 ] )
		
		control_values[ index ][ 4 ] = boxes[ index ].network_delay

puppet func set_target( new_position, is_active ):
	$BoxTarget.translation.z = new_position
	control_values[ player_index ][ 1 ] = new_position
	input_axes[ player_index ].set_position( new_position / movement_range )
	if is_active: $BoxTarget.show()
	else: $BoxTarget.hide()

func _on_GUI_game_toggle( started ):
	input_axes[ player_index ].set_position( 0.0 )
	GameConnection.rpc( "register_player" )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	$BoxTarget.translation.z = ( randf() - 0.5 ) * movement_range
	rpc( "set_target", $BoxTarget.translation.z, ( timeouts_count % 2 == 0 ) )