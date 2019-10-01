extends Spatial

enum Direction { NONE = 0, UP = 1, DOWN = -1 }

const PLAY_TIMEOUT = 3.0
const REST_TIMEOUT = 120.0

const PLAY_CYCLES = 3
const PLAY_TIMEOUTS = 8

onready var space_scale = $GameSpace/Boundaries.shape.extents.y

onready var player = $GameSpace/Boundaries/Player
onready var target = $GameSpace/Boundaries/Target
onready var watermelon = $GameSpace/Boundaries/Player/Watermelon
onready var balloon = $GameSpace/Boundaries/Player/Balloon
onready var ray = $GameSpace/Boundaries/Player/RayCast

var score_animation = preload( "res://Actors/ScorePing.tscn" )

var cycles_count = 0
var direction = Direction.NONE 

var score = 0
var score_state = 0

var target_reached = false

onready var input_axis = GameManager.get_player_control( get_player_variables()[ 0 ] )

var control_values = [ [ 0, 0, 0, 0, 0 ] ]

static func get_player_variables():
	return [ "Hand" ]

func _ready():
	$GUI.set_timeouts( PLAY_TIMEOUT, REST_TIMEOUT )
	if input_axis.is_calibrating: $GUI.set_max_effort( 100.0 )
	else: $GUI.set_max_effort( 70.0 )
#	if Controller.direction_axis == Controller.HORIZONTAL:
#		$Camera.rotate_z( PI / 2 )
	input_axis.set_position( 0.0 )
	control_values[ 0 ][ 1 ] = 0.0

func _physics_process( delta ):
	control_values[ 0 ][ 2 ] = input_axis.get_force()
	player.add_central_force( Vector3.UP * control_values[ 0 ][ 2 ] )
	
	control_values[ 0 ][ 0 ] = player.translation.y
	input_axis.set_position( control_values[ 0 ][ 0 ] / space_scale )
	
	if not input_axis.is_calibrating:
		DataLog.register_values( [ direction, control_values[ 0 ][ 2 ], control_values[ 0 ][ 0 ], score_state ] )
		score_state = 0

func _change_display():
	if direction == Direction.NONE:
		watermelon.hide()
		balloon.hide()
	elif direction == Direction.DOWN:
		balloon.show()
		watermelon.hide()
	elif direction == Direction.UP:
		watermelon.show()
		balloon.hide()
	var target_position = direction * space_scale
	target.translation.y = target_position
	input_axis.set_position( direction )
	control_values[ 0 ][ 1 ] = direction

func _on_GUI_game_timeout( timeouts_count ):
	if direction == Direction.NONE:
		direction = Direction.UP if ( cycles_count % 2 == 0 ) else Direction.DOWN
	else:
		if target_reached:
			score += 1
			score_state = 1
			var score_up = score_animation.instance()
			player.add_child( score_up )
		else:
			score_state = -1
		if direction == Direction.UP: direction = Direction.DOWN
		elif direction == Direction.DOWN: direction = Direction.UP
	if cycles_count < PLAY_CYCLES:
		if timeouts_count >= PLAY_TIMEOUTS: 
			direction = Direction.NONE
			cycles_count += 1
			$GUI.wait_rest()
			if cycles_count >= PLAY_CYCLES: 
				DataLog.register_values( [ PLAY_TIMEOUTS * PLAY_CYCLES, score ] )
				$GUI.end_game( PLAY_TIMEOUTS * PLAY_CYCLES, score )
				DataLog.end_log()
		_change_display()
	player.gravity_scale = direction

func _on_GUI_game_toggle( started ):
	input_axis.set_position( 0.0 )
	control_values[ 0 ][ 1 ] = 0.0
	_change_display()

func _on_Target_body_entered( body ):
	target_reached = true

func _on_Target_body_exited( body ):
	target_reached = false
