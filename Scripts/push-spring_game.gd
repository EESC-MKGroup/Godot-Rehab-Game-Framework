extends Spatial

enum DIRECTION { NONE = 0, UP = -1, DOWN = 1 }

const REST_TIMEOUTS = 20
const MAX_CYCLES = 3
const MAX_TIMEOUTS = 2
const HOLD_CYCLES = 5
const HOLD_TIMEOUTS = 15

var cycles_number = 0
var cycles_count = 0
var timeouts_number = 0
var timeouts_active_number = 0
var timeouts_count = 0
var direction = NONE

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

onready var camera = get_node( "Camera" )

onready var base = get_node( "SpringBase" )
onready var effector = base.get_node( "Effector" )
onready var spring = base.get_node( "Spring" )

onready var target = base.get_node( "Target" )
onready var arrow = base.get_node( "Arrow" )

onready var initial_position = effector.translation.y
onready var initial_scale = spring.scale.y
onready var max_displacement = abs( effector.translation.y ) / 2

var controller_axis = Controller.direction_axis

func _ready():
	Controller.set_status( 5 )
	if Controller.is_calibrating: 
		cycles_number = MAX_CYCLES
		timeouts_active_number = MAX_TIMEOUTS
	else:
		cycles_number = HOLD_CYCLES
		timeouts_active_number = HOLD_TIMEOUTS
	timeouts_number = timeouts_active_number + REST_TIMEOUTS
	Controller.set_axis_values( controller_axis, 0, 50.0 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( controller_axis )
	var player_force = abs( controller_values[ Controller.FORCE ] )
	var displacement = player_force * max_displacement
	displacement = clamp( displacement, 0.0, max_displacement )
	effector.translation.y = initial_position + displacement
	spring.scale.y = initial_scale * effector.translation.y / initial_position

func _on_GUI_game_timeout():
	setpoint_display.text = ( "%+.3f" % direction )
	if direction != NONE:
		if timeouts_count >= timeouts_active_number: 
			arrow.hide()
		if timeouts_count >= timeouts_number: 
			arrow.show()
			cycles_count += 1
			timeouts_count = 0
			if cycles_count >= cycles_number:
				if direction == UP: 
					camera.rotate_z( PI )
					direction = DOWN
				elif direction == DOWN:
					target.hide()
					arrow.hide()
					direction = NONE
				cycles_count = 0
		timeouts_count += 1
	print( "timeout: %d %d %d" % [ direction, cycles_count, timeouts_count ] )

func _on_GUI_game_toggle( started ):
	direction = UP
	if not Controller.is_calibrating: target.show()
	arrow.show()