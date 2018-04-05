extends Spatial

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

onready var base = get_node( "SpringBase" )
onready var effector = base.get_node( "Effector" )
onready var spring = base.get_node( "Spring" )
onready var target = base.get_node( "Target" )

onready var initial_position = effector.translation.y
onready var initial_scale = spring.scale.y
onready var max_displacement = abs( effector.translation.y ) / 2

func _ready():
	Controller.set_status( 5 )
	if Controller.is_calibrating: target.hide()

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var player_force = controller_values[ Controller.FORCE ]
	var displacement = player_force * max_displacement
	displacement = clamp( displacement, 0.0, max_displacement )
	effector.translation.y = initial_position + displacement
	spring.scale.y = initial_scale * effector.translation.y / initial_position

func _on_GUI_game_timeout():
	setpoint_display.text = ( "%+.3f" % -1 )
	Controller.set_axis_values( Controller.VERTICAL, 0, 50.0 )
