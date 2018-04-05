extends Spatial

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

onready var base = get_node( "SpringBase" )
onready var effector = base.get_node( "Effector" )
onready var spring = base.get_node( "Spring" )

onready var initial_position = effector.translation.y
onready var max_displacement = abs( effector.translation.y ) / 2

func _ready():
	Controller.set_status( 5 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var player_force = controller_values[ Controller.FORCE ]
	var displacement = controller_values[ Controller.POSITION ] * max_displacement
	displacement = clamp( displacement, 0.0, max_displacement )
	effector.translation.y = initial_position + displacement

func _on_GUI_game_timeout():
	setpoint_display.text = ( "%+.3f" % max_displacement )
	Controller.set_axis_values( Controller.VERTICAL, 0, 50.0 )
