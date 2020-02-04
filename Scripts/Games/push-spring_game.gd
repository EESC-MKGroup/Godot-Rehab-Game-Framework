extends Spatial

enum Direction { NONE = 0, UP = 1, DOWN = -1 }

const MAX_TIMEOUT = 6.0
const MAX_CYCLES = 3
const HOLD_TIMEOUT = 15.0
const HOLD_CYCLES = 5
const REST_TIMEOUT = 60.0

onready var effector = $SpringBase/Effector
onready var spring = $SpringBase/Spring

var cycles_number = 0
var cycles_count = 0
var direction = Direction.NONE

var score_state = 0
var max_score = 0
var score = 0

onready var input_axis = GameManager.get_player_control( get_player_variables()[ 0 ] )

var control_values = [ GameManager.get_default_controls() ]

static func get_player_variables():
	return [ "Hand" ]

func _ready():
#	if Controller.direction_axis == Controller.HORIZONTAL:
#		$Camera.rotate_z( PI / 2 )
	if input_axis.is_calibrating: 
		cycles_number = MAX_CYCLES
		$GUI.set_timeouts( MAX_TIMEOUT, REST_TIMEOUT )
		$GUI.set_max_effort( 100.0 )
		$ForcePanel.show()
	else:
		cycles_number = HOLD_CYCLES
		$GUI.set_timeouts( HOLD_TIMEOUT, REST_TIMEOUT )
		$GUI.set_max_effort( 20.0 )
	input_axis.set_position( 0.0 )
	input_axis.position_scale = abs( effector.translation.y )
	input_axis.force_scale = 1.0
	control_values[ 0 ][ GameManager.SETPOINT ] = 0.0
	$SpringBase/Spring.body_1 = $SpringBase
	$SpringBase/Spring.body_2 = $SpringBase/Effector/Handle

func _physics_process( delta ):
	control_values[ 0 ][ GameManager.POSITION ] = effector.translation.y
	var player_position = control_values[ 0 ][ GameManager.POSITION ]
	
	control_values[ 0 ][ GameManager.INPUT ] = input_axis.get_input( player_position )
	var player_force = -direction * control_values[ 0 ][ GameManager.INPUT ]
	var spring_force = spring.get_force()
	
	effector.add_central_force( Vector3.UP * ( player_force + spring_force ) )
	
	control_values[ 0 ][ GameManager.IMPEDANCE ] = input_axis.impedance[ 1 ]
	
	input_axis.setpoint = player_position
	
	if direction != Direction.NONE:
		max_score += 1
		score += score_state
	
	if not input_axis.is_calibrating:
		DataLog.register_values( [ direction, player_force, player_position, score_state ] )

func _on_GUI_game_timeout( timeouts_count ):
	if direction == Direction.NONE: direction = Direction.UP
	if timeouts_count == 0: 
		$SpringBase/Arrow.show()
		if cycles_count >= cycles_number:
			if direction == Direction.UP: 
				$Camera.rotate_z( PI )
				direction = Direction.DOWN
			cycles_count = 0
		control_values[ 0 ][ 1 ] = direction
	if timeouts_count == 1:
		$SpringBase/Arrow.hide()
		cycles_count += 1
		$GUI.wait_rest()
		if cycles_count >= cycles_number and direction == Direction.DOWN:
			$SpringBase/Target.hide()
			direction = Direction.NONE
			DataLog.register_values( [ max_score, score ] )
			$GUI.end_game( max_score, score )
			DataLog.end_log()
		control_values[ 0 ][ 1 ] = 0.0

func _on_GUI_game_toggle( started ):
	if not input_axis.is_calibrating: $SpringBase/Target.show()

func _on_Target_body_entered( body ):
	if direction != Direction.NONE: score_state = 1

func _on_Target_body_exited( body ):
	score_state = 0
