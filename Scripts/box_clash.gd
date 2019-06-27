extends "res://Scripts/game.gd"

onready var boundary_1 = $Ground/Platform/Boundaries/CollisionShape1
onready var boundary_2 = $Ground/Platform/Boundaries/CollisionShape2
onready var movement_range = abs( boundary_1.translation.z - boundary_2.translation.z )

static func get_player_variables():
	return [ "Box1", "Box2" ]

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameConnection.is_server:
		GameConnection.connect_server( 2 ) 
		GameConnection.connect( "players_connected", self, "_on_players_connected" )
	else: 
		GameConnection.connect_client( Configuration.get_parameter( "server_address" ) )
		GameConnection.connect( "client_connected", self, "_on_client_connected" )

func _on_client_connected( client_id ):
	if client_id == 0: GameConnection.set_as_master( $Box1 )
	elif client_id == 1: GameConnection.set_as_master( $Box2 )

func _on_players_connected():
	$Box1.rpc( "enable" )
	$Box2.rpc( "enable" )
	$Box1.rpc( "update_server", 0.0, 0.0, OS.get_ticks_msec(), OS.get_ticks_msec() )
	$Box2.rpc( "update_server", 0.0, 0.0, OS.get_ticks_msec(), OS.get_ticks_msec() )

func get_player_force( body ):
	return body.transform.basis * InputAxis.get_value() * movement_range

func get_environment_force( body ):
	return body.transform.basis * $Spring.get_force()