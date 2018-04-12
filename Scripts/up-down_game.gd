extends Spatial

const REST_TIMEOUTS = 20
const PLAY_CYCLES = 3
const PLAY_TIMEOUTS = 8

enum DIRECTION { NONE = 0, UP = -1, DOWN = 1 }

var cycles_count = 0
var timeouts_count = 0
var direction = UP 

export(float, 0.0, 1.0) var max_setpoint = 0.7

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
	setpoint_display.text = ( "%+.3f" % 0.0 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var new_position = controller_values[ Controller.POSITION ] / max_setpoint * max_position
	new_position = clamp( new_position, -max_position, max_position )
	player.translation.y = -new_position

func _switch_objects():
	if direction == NONE:
		watermelon.hide()
		balloon.hide()
		print( "rest phase" )
	else:
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
		print( "play phase" )
	if cycles_count < PLAY_CYCLES:
		if timeouts_count >= PLAY_TIMEOUTS: 
			direction = NONE
		if timeouts_count >= PLAY_TIMEOUTS + REST_TIMEOUTS: 
			direction = UP
			cycles_count += 1
			timeouts_count = 0
			if cycles_count >= PLAY_CYCLES:
				direction = NONE
	timeouts_count += 1
	var target_position = direction * max_position
	target.translation.y = -target_position
	Controller.set_axis_values( Controller.VERTICAL, direction * max_setpoint, 1 )
	setpoint_display.text = ( "%+.3f" % ( direction * max_setpoint ) )

func _on_GUI_game_timeout():
	_switch_objects()

func _on_GUI_game_toggle( started ):
	if Controller.is_calibrating: Controller.set_status( 1 )
	else: Controller.set_status( 4 )
	Controller.set_axis_values( Controller.VERTICAL, 0.0, 1 )
