extends Spatial

onready var boundary_1 = $Ground/Platform/Boundaries/CollisionShape1
onready var boundary_2 = $Ground/Platform/Boundaries/CollisionShape2
onready var movement_range = abs( boundary_1.translation.z - boundary_2.translation.z )

onready var input_axis = GameManager.player_controls[ get_player_variables()[ 0 ] ]

static func get_player_variables():
	return [ "Player Box" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameConnection.is_server:
		GameConnection.connect_server( 2 ) 
		GameConnection.connect( "players_connected", self, "_on_players_connected" )
	else: 
		GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )
		GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 0: 
		GameConnection.set_as_master( $Box1 )
		$Box2.mode = RigidBody.MODE_KINEMATIC
	elif client_id == 1: 
		GameConnection.set_as_master( $Box2 )
		$Box1.mode = RigidBody.MODE_KINEMATIC

func _on_players_connected():
	$Box1.rpc( "enable" )
	$Box2.rpc( "enable" )

func get_player_force( body ):
	return body.transform.basis * Vector3.FORWARD * input_axis.get_force() * movement_range

func get_environment_force( body ):
	return body.transform.basis * Vector3.FORWARD * $Spring.get_force()