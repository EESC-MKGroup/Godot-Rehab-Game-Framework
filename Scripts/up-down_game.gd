extends Spatial

enum DIRECTION { NONE = 0, UP = 1, DOWN = -1 }

const PLAY_TIMEOUT = 3.0
const REST_TIMEOUT = 120.0

const PLAY_CYCLES = 3
const PLAY_TIMEOUTS = 8

var cycles_count = 0
var direction = NONE 

var score = 0
var score_state = 0

onready var boundaries = get_node( "GameSpace/Boundaries" )
onready var max_position = boundaries.shape.extents.y

onready var player = boundaries.get_node( "Player" )
onready var target = boundaries.get_node( "Target" )
onready var watermelon = player.get_node( "Watermelon" )
onready var balloon = player.get_node( "Balloon" )
onready var ray = player.get_node( "RayCast" )

var score_animation = preload( "res://Actors/ScorePing.tscn" )

func _ready():
	$GUI.set_timeouts( PLAY_TIMEOUT, REST_TIMEOUT )
	if Controller.is_calibrating: $GUI.set_max_effort( 100.0 )
	else: $GUI.set_max_effort( 70.0 )
	if Controller.direction_axis == Controller.HORIZONTAL:
		$Camera.rotate_z( PI / 2 )
	Controller.set_axis_values( 0.0, 0 )
	$GUI.display_setpoint( 0.0 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values()
	var new_position = controller_values[ Controller.POSITION ] * max_position
	new_position = clamp( new_position, -max_position, max_position )
	player.translation.y = new_position
	
	if not Controller.is_calibrating:
		var measure_value = player.translation.y / max_position
		DataLog.register_values( [ direction, measure_value, score_state ] )
		score_state = 0

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
	target.translation.y = target_position
	Controller.set_axis_values( direction, 1 )
	$GUI.display_setpoint( direction )

func _on_GUI_game_timeout( timeouts_count ):
	if direction == NONE:
		direction = UP
	else:
		if ray.is_colliding():
			score += 1
			score_state = 1
			var score_up = score_animation.instance()
			player.add_child( score_up )
		else:
			score_state = -1
		if direction == UP: direction = DOWN
		elif direction == DOWN: direction = UP
	if cycles_count < PLAY_CYCLES:
		if timeouts_count >= PLAY_TIMEOUTS: 
			direction = NONE
			cycles_count += 1
			$GUI.wait_rest()
			if cycles_count >= PLAY_CYCLES: $GUI.end_game( PLAY_TIMEOUTS * PLAY_CYCLES, score )
		_change_display()

func _on_GUI_game_toggle( started ):
	if Controller.is_calibrating: Controller.set_status( 1 )
	elif Controller.direction_axis == Controller.VERTICAL: Controller.set_status( 4 )
	else: Controller.set_status( 8 )
	Controller.set_axis_values( 0.0, 1 )
	_change_display()
