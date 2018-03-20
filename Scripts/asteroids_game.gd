extends Node

const ASTEROIDS_NUMBER = 5

var asteroid = preload( "res://Actors/Asteroid.tscn" )
onready var area = get_node( "Area" )
onready var boundaries = area.get_node( "Boundaries" )
onready var boundary_extents = boundaries.shape.extents

onready var asteroid_width = 2 * boundary_extents.y / ASTEROIDS_NUMBER
onready var asteroid_top = -boundary_extents.y + asteroid_width / 2

func _ready():
	var start_button = get_node( "GUI/StartButton" )
	set_physics_process( false )
	start_button.connect( "pressed", self, "_on_StartButton_pressed" )

func _physics_process( delta ):
	if boundaries.get_child_count() <= 1:
		_spawn_asteroids()

func _spawn_asteroids():
	var spawn_positions = []
	for asteroid_index in range( 0, ASTEROIDS_NUMBER ):
		spawn_positions.append( asteroid_top + asteroid_index * asteroid_width )
	var targetPosition = randi() % ASTEROIDS_NUMBER
	spawn_positions.remove( targetPosition )
	for position in spawn_positions:
		var spawned_asteroid = asteroid.instance()
		var spawn_position = Vector3( boundary_extents.x, position, 0 )
		spawned_asteroid.translate( spawn_position )
		boundaries.add_child( spawned_asteroid )
	Controller.set_axis_values( Controller.AXIS.VERTICAL, targetPosition, 1 )

func _on_StartButton_pressed():
	set_physics_process( true )

func _on_body_exited( body ):
	body.queue_free()
