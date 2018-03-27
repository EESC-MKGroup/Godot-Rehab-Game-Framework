extends Node

const ASTEROID_SLOTS_NUMBER = 5

var setpoint_positions = []
var score = 0

var asteroid = preload( "res://Actors/Asteroid.tscn" )
onready var boundary_area = get_node( "BoundaryArea" )
onready var boundaries = boundary_area.get_node( "Boundaries" )
onready var boundary_extents = boundaries.shape.extents

var asteroid_wall = preload( "res://Actors/AsteroidWall.tscn" )
var score_animation = preload( "res://Actors/ScoreAnimation.tscn" )

onready var asteroid_width = 2 * boundary_extents.y / ASTEROID_SLOTS_NUMBER
onready var asteroid_top = -boundary_extents.y + asteroid_width / 2

export var asteroid_speed = 3

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )
onready var start_button = get_node( "GUI/StartButton" )

onready var setpoint_timer = get_node( "Timer" )
var setpoint_position = 0

func _ready():
	start_button.connect( "toggled", self, "_on_StartButton_toggled" )
	Controller.set_axis_values( Controller.VERTICAL, 0.0, 1.0 ) 
	if Controller.is_calibrating: Controller.set_status( 3 )
	else: Controller.set_status( 2 )

func _set_setpoint( setpoint_position ):
	Controller.set_axis_values( Controller.VERTICAL, setpoint_position, 30.0 )
	setpoint_display.text = ( "%+.3f" % setpoint_position )

func _spawn_asteroids():
	var spawn_positions = []
	for asteroid_index in range( 0, ASTEROID_SLOTS_NUMBER ):
		spawn_positions.append( asteroid_top + asteroid_index * asteroid_width )
	var target_index = randi() % ASTEROID_SLOTS_NUMBER
	var target_position = spawn_positions[ target_index ] 
	setpoint_positions.push_back( target_position / boundary_extents.y )
	spawn_positions.remove( target_index )
	var score_area = asteroid_wall.instance()
	score_area.translation.x = boundary_extents.x
	score_area.spawn_asteroids( spawn_positions, asteroid_speed )
	score_area.connect( "body_exited", self, "_on_ScoreArea_body_exited", [ score_area ] )
	boundaries.add_child( score_area )
	_set_setpoint( setpoint_positions.front() )

func _on_BoundaryArea_area_exited( area ):
	area.queue_free()

func _on_ScoreArea_body_exited( body, area ):
	if area.get_asteroids_number() >= ASTEROID_SLOTS_NUMBER - 1:
		score += 1
		var score_up = score_animation.instance()
		score_up.rotation = Vector3( 0, PI, PI / 2 )
		score_up.translation.z = -0.5
		body.add_child( score_up )
	if setpoint_positions.size() > 0: setpoint_positions.pop_front()

func _on_GUI_game_timeout():
	_spawn_asteroids()
