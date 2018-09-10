extends Spatial

enum DIRECTION { NONE = 0, UP = 1, DOWN = -1 }

const MAX_TIMEOUT = 6.0
const MAX_CYCLES = 3
const HOLD_TIMEOUT = 15.0
const HOLD_CYCLES = 5
const REST_TIMEOUT = 60.0

var cycles_number = 0
var cycles_count = 0
var direction = NONE

onready var effector = $SpringBase/Effector
onready var spring = $SpringBase/Spring

onready var force_display = $ForcePanel/MeasureDisplay

onready var initial_position = effector.translation.y
onready var initial_scale = spring.scale.y
onready var max_displacement = 0.8 * abs( effector.translation.y )

func _ready():
#	if Controller.direction_axis == Controller.HORIZONTAL:
#		$Camera.rotate_z( PI / 2 )
	if RemoteDevice.is_calibrating: 
		cycles_number = MAX_CYCLES
		$GUI.set_timeouts( MAX_TIMEOUT, REST_TIMEOUT )
		$GUI.set_max_effort( 100.0 )
		$ForcePanel.show()
	else:
		cycles_number = HOLD_CYCLES
		$GUI.set_timeouts( HOLD_TIMEOUT, REST_TIMEOUT )
		$GUI.set_max_effort( 20.0 )
	RemoteDevice.set_axis_values( 0.0 )
	$GUI.display_setpoint( 0.0 )

func _physics_process( delta ):
	var player_force = abs( RemoteDevice.get_value() * max_displacement )
	var spring_force = abs( spring.get_force() )
	
	effector.add_central_force( Vector3.UP * ( player_force - spring_force ) )
	
	force_display.text = ( "%+4.1fN" % player_force )
	
	if not RemoteDevice.is_calibrating:
		var score_state = 0
		if direction != NONE: score_state = 1 if displacement == max_displacement else -1
		DataLog.register_values( [ direction, player_force, score_state ] )

func _on_GUI_game_timeout( timeouts_count ):
	if direction == NONE: direction = UP
	if timeouts_count == 0: 
		$SpringBase/Arrow.show()
		if cycles_count >= cycles_number:
			if direction == UP: 
				$Camera.rotate_z( PI )
				direction = DOWN
			cycles_count = 0
		$GUI.display_setpoint( direction )
	if timeouts_count == 1:
		$SpringBase/Arrow.hide()
		cycles_count += 1
		$GUI.wait_rest()
		if cycles_count >= cycles_number and direction == DOWN:
			$SpringBase/Target.hide()
			direction = NONE
			$GUI.end_game( 2 * cycles_number, 0 )
		$GUI.display_setpoint( 0.0 )

func _on_GUI_game_toggle( started ):
	if not Controller.is_calibrating: $SpringBase/Target.show()