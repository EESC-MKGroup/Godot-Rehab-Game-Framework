extends Node

const ASTEROID_SLOTS_NUMBER = 5
const PHASES_STIFFNESS = [ 100.0, 50.0, 30.0, 0.0 ]
const PHASE_WAVES_NUMBER = 10

export(float, 0.0, 1.0) var max_setpoint = 0.8

var setpoint_positions = []

var waves_count = 0
var score = 0

onready var boundary_area = get_node( "BoundaryArea" )
onready var boundaries = boundary_area.get_node( "Boundaries" )
onready var boundary_extents = boundaries.shape.extents

onready var player = boundaries.get_node( "Player" )

var asteroid_wall = preload( "res://Actors/FruitWall.tscn" )
var score_animation = preload( "res://Actors/PopUpAnimation.tscn" )

onready var asteroid_width = 2 * boundary_extents.y / ASTEROID_SLOTS_NUMBER
onready var asteroid_top = -boundary_extents.y + asteroid_width / 2

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var new_position = controller_values[ Controller.POSITION ] / max_setpoint * boundary_extents.y
	new_position = clamp( new_position, -boundary_extents.y, boundary_extents.y )
	var position_delta = new_position - player.translation.y
	player.translation.y = new_position
	player.rotation.x = ( player.rotation.x + 0.15 * position_delta / delta ) / 2
	
	DataLog.register_values( [ player.translation.y ] )

func _set_setpoint():
	if setpoint_positions.size() > 0:
		var setpoint_position = setpoint_positions.front() * max_setpoint
		var stiffness_phase = int( waves_count / PHASE_WAVES_NUMBER ) % PHASES_STIFFNESS.size()
		Controller.set_axis_values( Controller.VERTICAL, setpoint_position, PHASES_STIFFNESS[ stiffness_phase ] )
		setpoint_display.text = ( "%+.3f" % setpoint_position )

func _spawn_asteroids():
	var score_area = asteroid_wall.instance()
	score_area.translation.x = boundary_extents.x + waves_count * 2 * score_area.get_width().x
	score_area.connect( "body_exited", self, "_on_ScoreArea_body_exited", [ score_area ] )
	score_area.connect( "collider_reached", self, "_on_ScoreArea_collider_reached" )
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

func _on_ScoreArea_collider_reached( collider ):
	player.eat( collider )

func _on_GUI_game_timeout():
	_spawn_asteroids()

func _on_GUI_game_toggle( started ):
	Controller.set_axis_values( Controller.VERTICAL, 0.0, 1.0 ) 
	if Controller.is_calibrating: Controller.set_status( 3 )
	else: Controller.set_status( 2 )
