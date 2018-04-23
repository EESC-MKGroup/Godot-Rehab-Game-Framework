extends Spatial

const PLAY_TIMEOUT = 3.0
const REST_TIMEOUT = 120.0

enum DIRECTION { NONE = 0, UP = -1, DOWN = 1 }

var cycles_count = 0
var direction = UP 

onready var setpoint_timer = get_node( "Timer" )

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

onready var boundaries = get_node( "GameSpace/Boundaries" )
onready var max_position = boundaries.shape.extents.y

onready var player = boundaries.get_node( "Player" )
onready var target = boundaries.get_node( "Target" )
onready var watermelon = player.get_node( "Watermelon" )
onready var balloon = player.get_node( "Balloon" )
onready var ray = player.get_node( "RayCast" )

var score_animation = preload( "res://Actors/ScorePing.tscn" )

var controller_axis = Controller.direction_axis

func _ready():
	$GUI.set_timeouts( PLAY_TIMEOUT, REST_TIMEOUT )
	if controller_axis == Controller.HORIZONTAL:
		$Camera.rotate_z( PI / 2 )
	setpoint_display.text = ( "%+.3f" % 0.0 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( controller_axis )
	var new_position = controller_values[ Controller.POSITION ] * max_position
	new_position = clamp( new_position, -max_position, max_position )
	player.translation.y = -new_position

func _change_display():
	if direction == NONE:
		watermelon.hide()
		balloon.hide()
	elif direction == DOWN:
		balloon.show()
		watermelon.hide()
	elif direction == UP:
		watermelon.show()
		balloon.hide()
	var target_position = direction * max_position
	target.translation.y = -target_position
	Controller.set_axis_values( controller_axis, direction, 1 )
	setpoint_display.text = ( "%+.3f" % direction )

func _on_GUI_game_timeout( timeouts_count ):
	if direction == NONE:
		ray.enabled = false
		print( "rest phase (%d/%d)" % [ timeouts_count, PLAY_TIMEOUTS + REST_TIMEOUTS ] )
	else:
		if ray.is_colliding():
			var score_up = score_animation.instance()
			player.add_child( score_up )
		ray.enabled = true
		if direction == UP: direction = DOWN
		elif direction == DOWN: direction = UP
		print( "play phase (%d/%d)" % [ timeouts_count, PLAY_TIMEOUTS ] )
	_change_display()
	if cycles_count < PLAY_CYCLES:
		if timeouts_count >= PLAY_TIMEOUTS: 
			direction = NONE
			$GUI.end_play()
		if timeouts_count >= PLAY_TIMEOUTS + REST_TIMEOUTS: 
			direction = UP
			cycles_count += 1
			if cycles_count >= PLAY_CYCLES:
				direction = NONE
				$GUI.end_play()
	_change_display()

func _on_GUI_game_toggle( started ):
	if Controller.is_calibrating: Controller.set_status( 1 )
	else: Controller.set_status( 4 if controller_axis == Controller.VERTICAL else 8 )
	Controller.set_axis_values( controller_axis, 0.0, 1 )
	_change_display()
