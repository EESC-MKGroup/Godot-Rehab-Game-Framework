extends Spatial

onready var boundary_1 = $Ground/Platform/Boundaries/CollisionShape1
onready var boundary_2 = $Ground/Platform/Boundaries/CollisionShape2
onready var movement_range = abs( boundary_1.translation.z - boundary_2.translation.z )

onready var box_1 = $Box1
onready var box_2 = $Box2
onready var arrow_1 = $Box1/Arrow
onready var arrow_2 = $Box2/Arrow

onready var input_axis_1 = GameManager.get_player_control( get_player_variables()[ 0 ] )
onready var input_axis_2 = GameManager.get_player_control( get_player_variables()[ 1 ] )

static func get_player_variables():
	return [ "Box 1", "Box 2" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	$GUI.set_timeouts( 10.0, 1.0 )
	$GUI.set_max_effort( 100.0 )
	$Spring.body_1 = box_1
	$Spring.body_2 = box_2

func connect_server():
	GameConnection.connect_server( 2 ) 
	GameConnection.connect( "players_connected", self, "_on_players_connected" )

func connect_client( address ):
	GameConnection.connect_client( address )
	GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 1: 
		box_1 = $Box2
		box_2 = $Box1
		arrow_1 = $Box2/Arrow
		arrow_2 = $Box1/Arrow
	GameConnection.set_as_master( box_1 )
	box_2.mode = RigidBody.MODE_KINEMATIC
	$BoxTarget.show()

func _on_players_connected():
	box_1.rpc( "enable" )
	box_2.rpc( "enable" )
	GameConnection.set_as_master( self )
	GameConnection.connect( "game_timeout", $GUI, "_on_GUI_game_timeout" )
	$BoxTarget.show()

func _physics_process( delta ):
	$GUI.display_force( input_axis_1.get_force() )
	box_1.external_force.z = input_axis_1.get_force() - $Spring.get_force()
	box_2.external_force.z = -input_axis_2.get_force() + $Spring.get_force()
	input_axis_1.set_force( box_1.feedback_force.length() / movement_range )
	input_axis_2.set_force( box_2.feedback_force.length() / movement_range )
	arrow_1.update( box_1.feedback_force / movement_range )
	arrow_2.update( box_2.feedback_force / movement_range )
	$GUI.display_position( box_1.translation.length() )

puppet func set_target( new_position, is_active ):
	$BoxTarget.translation.z = new_position
	$GUI.display_setpoint( $BoxTarget.translation.z )
	input_axis_1.set_position( $BoxTarget.translation.z / movement_range )
	if is_active: $BoxTarget.show()
	else: $BoxTarget.hide()

func _on_GUI_game_toggle( started ):
	input_axis_1.set_position( 0.0 )

func _on_GUI_game_timeout( timeouts_count ):
	print( "timeout: ", timeouts_count )
	$BoxTarget.translation.z = ( randf() - 0.5 ) * movement_range
	rpc( "set_target", $BoxTarget.translation.z, ( timeouts_count % 2 == 0 ) )