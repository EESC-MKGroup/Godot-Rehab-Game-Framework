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

onready var camera = get_node( "Camera" )

onready var base = get_node( "SpringBase" )
onready var effector = base.get_node( "Effector" )
onready var spring = base.get_node( "Spring" )

onready var target = base.get_node( "Target" )
onready var arrow = base.get_node( "Arrow" )

onready var force_panel = get_node( "ForcePanel" )
onready var force_display = force_panel.get_node( "MeasureDisplay" )

onready var initial_position = effector.translation.y
onready var initial_scale = spring.scale.y
onready var max_displacement = abs( effector.translation.y ) / 2

func _ready():
	Controller.set_status( 5 )
	if Controller.direction_axis == Controller.HORIZONTAL:
		$Camera.rotate_z( PI / 2 )
	if Controller.is_calibrating: 
		cycles_number = MAX_CYCLES
		$GUI.set_timeouts( MAX_TIMEOUT, REST_TIMEOUT )
		$GUI.set_max_effort( 100.0 )
		force_panel.show()
	else:
		cycles_number = HOLD_CYCLES
		$GUI.set_timeouts( HOLD_TIMEOUT, REST_TIMEOUT )
		$GUI.set_max_effort( 70.0 )
	Controller.set_axis_values( 0, 50.0 )
	$GUI.display_setpoint( 0.0 )

func _physics_process( delta ):
	var player_force = Controller.get_axis_values()[ Controller.FORCE ]
	var displacement_factor = abs( player_force )
	var displacement = displacement_factor * max_displacement
	displacement = clamp( displacement, 0.0, max_displacement )
	effector.translation.y = initial_position + displacement
	spring.scale.y = initial_scale * effector.translation.y / initial_position
	
	force_display.text = ( "%+4.1fN" % player_force )
	
	if not Controller.is_calibrating:
		var score_state = 0
		if direction != NONE: score_state = 1 if displacement == max_displacement else -1
		DataLog.register_values( [ direction, player_force, score_state ] )

func _on_GUI_game_timeout( timeouts_count ):
	if direction == NONE: direction = UP
	if timeouts_count == 0: 
		arrow.show()
		if cycles_count >= cycles_number:
			if direction == UP: 
				camera.rotate_z( PI )
				direction = DOWN
			cycles_count = 0
		$GUI.display_setpoint( direction )
	if timeouts_count == 1:
		arrow.hide()
		cycles_count += 1
		$GUI.wait_rest()
		if cycles_count >= cycles_number and direction == DOWN:
			target.hide()
			direction = NONE
			$GUI.end_game( 2 * cycles_number, 0 )
		$GUI.display_setpoint( 0.0 )

func _on_GUI_game_toggle( started ):
	if not Controller.is_calibrating: target.show()