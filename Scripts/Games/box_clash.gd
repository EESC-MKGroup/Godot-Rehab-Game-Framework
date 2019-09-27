extends Spatial

onready var boundary_1 = $Ground/Platform/Boundaries/CollisionShape1
onready var boundary_2 = $Ground/Platform/Boundaries/CollisionShape2
onready var movement_range = abs( boundary_1.translation.z - boundary_2.translation.z )

onready var input_axis_1 = GameManager.get_player_control( get_player_variables()[ 0 ] )
onready var input_axis_2 = GameManager.get_player_control( get_player_variables()[ 1 ] )

onready var player_box = $Box1
onready var player_input_axis = input_axis_1

static func get_player_variables():
	return [ "Box 1", "Box 2" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	$GUI.set_timeouts( 10.0, 1.0 )
	$GUI.set_max_effort( 100.0 )
	$Spring.body_1 = $Box1/Connector
	$Spring.body_2 = $Box2/Connector

func connect_server():
	GameConnection.connect_server( 2 ) 
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )

func _on_players_connected( player_ids ):
	print( "received player ids ", player_ids )
	$Box1.set_network_master( player_ids[ 0 ] )
	$Box2.set_network_master( player_ids[ 1 ] )
	rpc( "register_players", player_ids )
	GameConnection.connect( "game_timeout", $GUI, "_on_GUI_game_timeout" )
	$BoxTarget.show()

remote func register_players( player_ids ):
	$Box1.set_network_master( player_ids[ 0 ] )
	$Box2.set_network_master( player_ids[ 1 ] )
	if get_tree().get_network_unique_id() == player_ids[ 1 ]: 
		player_box = $Box2
		player_input_axis = input_axis_2
		$Camera.rotate_y( PI )
	#box_2.mode = RigidBody.MODE_KINEMATIC
	$BoxTarget.show()
	reset_connection()
	$Spring.stiffness = 0.0
	$Spring.damping = 0.0

func reset_connection():
	$Box1.enable()
	$Box2.enable()

func _process( delta ):
	$GUI.display_force( player_input_axis.get_force() )
	$GUI.display_position( player_box.translation.z )
	$GUI.display_feedback( player_box.feedback_force.z )
	$GUI.display_delay( int( 1000 * player_box.network_delay ) )

func _physics_process( delta ):
	$Box1.external_force = Vector3( 0, 0, input_axis_1.get_force() - $Spring.get_force() )
	$Box2.external_force = Vector3( 0, 0, input_axis_2.get_force() - $Spring.get_force() )
	$Box1.update_remote()
	$Box2.update_remote()
	input_axis_1.set_force( $Box1.feedback_force.z )
	input_axis_2.set_force( $Box2.feedback_force.z )
	$Box1/InputArrow.update( input_axis_1.get_force() )
	$Box2/InputArrow.update( input_axis_2.get_force() )
	$Box1/FeedbackArrow.update( $Box1.feedback_force.z )
	$Box2/FeedbackArrow.update( $Box2.feedback_force.z )
	
	$Box1/ErrorArrow.update( $Box1.target_position.z - $Box1.local_position.z )
	$Box2/ErrorArrow.update( $Box2.target_position.z - $Box2.local_position.z )

puppet func set_target( new_position, is_active ):
	$BoxTarget.translation.z = new_position
	$GUI.display_setpoint( $BoxTarget.translation.z )
	player_input_axis.set_position( $BoxTarget.translation.z / movement_range )
	if is_active: $BoxTarget.show()
	else: $BoxTarget.hide()

func _on_GUI_game_toggle( started ):
	player_input_axis.set_position( 0.0 )
	GameConnection.rpc( "register_player" )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	$BoxTarget.translation.z = ( randf() - 0.5 ) * movement_range
	rpc( "set_target", $BoxTarget.translation.z, ( timeouts_count % 2 == 0 ) )