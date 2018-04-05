extends Spatial

enum DIRECTION { UP = 1, DOWN = -1 }
var direction = DOWN 

export(float, 0.0, 1.0) var max_setpoint = 0.3 

onready var setpoint_timer = get_node( "Timer" )

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

onready var boundaries = get_node( "GameSpace/Boundaries" )
onready var max_position = boundaries.shape.extents.y

onready var player = boundaries.get_node( "Player" )
onready var target = boundaries.get_node( "Target" )
onready var watermelon = player.get_node( "Watermelon" )
onready var balloon = player.get_node( "Balloon" )
onready var ray = player.get_node( "RayCast" )

var score_animation = preload( "res://Actors/PopUpAnimation.tscn" )

func _ready():
	Controller.set_status( 4 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var new_position = controller_values[ Controller.POSITION ] * max_position
	new_position = clamp( new_position / max_setpoint, -max_position, max_position )
	player.translation.y = new_position

func _switch_objects():
	if ray.is_colliding():
		var score_up = score_animation.instance()
		score_up.set_animation( "score_up", "point" )
		player.add_child( score_up )
	if direction == UP:
		balloon.show()
		watermelon.hide()
		direction = DOWN
	elif direction == DOWN:
		watermelon.show()
		balloon.hide()
		direction = UP
	var target_position = direction * max_position
	target.translation.y = target_position
	Controller.set_axis_values( Controller.VERTICAL, direction * max_setpoint, 1 )
	setpoint_display.text = ( "%+.3f" % direction )

func _on_GUI_game_timeout():
	_switch_objects()
