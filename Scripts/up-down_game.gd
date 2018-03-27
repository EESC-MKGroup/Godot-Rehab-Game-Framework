extends Spatial

enum DIRECTION { UP = 1, DOWN = -1 }
var direction = DOWN 

onready var setpoint_timer = get_node( "Timer" )

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

onready var boundaries = get_node( "GameSpace/Boundaries" )
onready var max_position = boundaries.shape.extents.y

onready var hand = boundaries.get_node( "Hand" )
onready var target = boundaries.get_node( "Target" )
onready var ray = hand.get_node( "RayCast" )
onready var watermelon = hand.get_node( "Watermelon" )
onready var balloon = hand.get_node( "Balloon" )

func _ready():
	Controller.set_status( 4 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var new_position = controller_values[ Controller.POSITION ] * max_position
	new_position = clamp( new_position, -max_position, max_position )
	hand.translation.y = new_position
	#if ray.is_colliding():
	#	print( "target reached" ) 
	#	_switch_and_reset()

func _switch_objects():
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
	Controller.set_axis_values( Controller.VERTICAL, direction, 1 )
	setpoint_display.text = ( "%+.3f" % direction )

func _on_GUI_game_timeout():
	_switch_objects()
