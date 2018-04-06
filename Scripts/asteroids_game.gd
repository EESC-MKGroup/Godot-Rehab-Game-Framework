extends Node

const ASTEROID_SLOTS_NUMBER = 5
const PHASES_STIFFNESS = [ 100.0, 50.0, 30.0, 0.0 ]
const PHASE_WAVES_NUMBER = 10

var setpoint_positions = []

var waves_count = 0
var score = 0

onready var boundary_area = get_node( "BoundaryArea" )
onready var boundaries = boundary_area.get_node( "Boundaries" )
onready var boundary_extents = boundaries.shape.extents

var asteroid_wall = preload( "res://Actors/AsteroidWall.tscn" )
var score_animation = preload( "res://Actors/PopUpAnimation.tscn" )

onready var asteroid_width = 2 * boundary_extents.y / ASTEROID_SLOTS_NUMBER
onready var asteroid_top = -boundary_extents.y + asteroid_width / 2

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

func _ready():
	Controller.set_axis_values( Controller.VERTICAL, 0.0, 1.0 ) 
	if Controller.is_calibrating: Controller.set_status( 3 )
	else: Controller.set_status( 2 )

func _set_setpoint():
	if setpoint_positions.size() > 0:
		var setpoint_position = setpoint_positions.front()
		var stiffness_phase = int( waves_count / PHASE_WAVES_NUMBER ) % PHASES_STIFFNESS.size()
		Controller.set_axis_values( Controller.VERTICAL, setpoint_position, PHASES_STIFFNESS[ stiffness_phase ] )
		setpoint_display.text = ( "%+.3f" % setpoint_position )

func _spawn_asteroids():
	var score_area = asteroid_wall.instance()
	score_area.translation.x = boundary_extents.x + score_area.get_width().x
	score_area.connect( "body_exited", self, "_on_ScoreArea_body_exited", [ score_area ] )
	boundaries.add_child( score_area )
	var target_position = score_area.spawn_colliders( ASTEROID_SLOTS_NUMBER )
	setpoint_positions.push_back( target_position / boundary_extents.y )
	_set_setpoint()
	waves_count += 1

func _on_BoundaryArea_area_exited( area ):
	area.queue_free()

func _on_ScoreArea_body_exited( body, area ):
	if area.get_colliders_number() >= ASTEROID_SLOTS_NUMBER - 1:
		score += 1
		var score_up = score_animation.instance()
		score_up.set_animation( "score_up", "warpout" )
		body.add_child( score_up )
	setpoint_positions.pop_front()
	_set_setpoint()

func _on_GUI_game_timeout():
	_spawn_asteroids()
