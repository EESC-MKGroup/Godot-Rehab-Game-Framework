extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	$Box1.enable()
	$Box2.enable()
	GameConnection.connect( "client_connected", self, "_on_client_connected" )
	get_tree().set_pause( true )

func _on_client_connected( client_id ):
	if client_id == 0: $Box1.set_network_master( get_tree().get_network_unique_id() )
	elif client_id == 1: $Box2.set_network_master( get_tree().get_network_unique_id() )

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
