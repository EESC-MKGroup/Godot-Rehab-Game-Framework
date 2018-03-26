extends Node

const ASTEROID_SLOTS_NUMBER = 5
var asteroids_number = 0

var score = 0

var asteroid = preload( "res://Actors/Asteroid.tscn" )
onready var area = get_node( "BoundaryArea" )
onready var boundaries = area.get_node( "Boundaries" )
onready var boundary_extents = boundaries.shape.extents

onready var score_area = boundaries.get_node( "ScoreArea" )
var score_animation = preload( "res://Actors/ScoreAnimation.tscn" )

onready var asteroid_width = 2 * boundary_extents.y / ASTEROID_SLOTS_NUMBER
onready var asteroid_top = -boundary_extents.y + asteroid_width / 2

export var asteroid_speed = 3

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )
onready var start_button = get_node( "GUI/StartButton" )

func _ready():
	set_physics_process( false )
	start_button.connect( "toggled", self, "_on_StartButton_toggled" )
	if Controller.is_calibrating: Controller.set_status( 2 )
	else: Controller.set_status( 3 )

func _physics_process( delta ):
	score_area.translation.x -= asteroid_speed * delta
	if asteroids_number <= 0:
		_spawn_asteroids()

func _spawn_asteroids():
	var spawn_positions = []
	for asteroid_index in range( 0, ASTEROID_SLOTS_NUMBER ):
		spawn_positions.append( asteroid_top + asteroid_index * asteroid_width )
	var target_index = randi() % ASTEROID_SLOTS_NUMBER
	var target_position = spawn_positions[ target_index ] 
	score_area.translation = Vector3( boundary_extents.x, target_position, 0 )
	var setpoint_position = target_position / boundary_extents.y
	spawn_positions.remove( target_index )
	for position in spawn_positions:
		var spawned_asteroid = asteroid.instance()
		var spawn_position = Vector3( boundary_extents.x, position, 0 )
		spawned_asteroid.translate( spawn_position )
		spawned_asteroid.linear_speed = asteroid_speed
		boundaries.add_child( spawned_asteroid )
	asteroids_number = spawn_positions.size()
	Controller.set_axis_values( Controller.VERTICAL, setpoint_position, 1 )
	setpoint_display.text = ( "%+.3f" % setpoint_position )

func _on_StartButton_toggled( button_pressed ):
	set_physics_process( button_pressed )

func _on_BoundaryArea_body_exited( body ):
	body.queue_free()
	asteroids_number -= 1

func _on_ScoreArea_body_exited( body ):
	if asteroids_number >= ASTEROID_SLOTS_NUMBER - 1:
		score += 1
		var score_up = score_animation.instance()
		score_up.rotation = Vector3( 0, PI, PI / 2 )
		score_up.translation.z = -0.5
		body.add_child( score_up )