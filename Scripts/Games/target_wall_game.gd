extends Spatial

const COLLIDER_SLOTS_NUMBER = 5
const TOTAL_WAVES_NUMBER = 100

export(PackedScene) var target_wall = null
export(PackedScene) var score_animation = null

onready var boundary_extents = $BoundaryArea/Boundaries.shape.extents

onready var player = $BoundaryArea/Boundaries/Player

onready var collider_width = 2 * boundary_extents.y / COLLIDER_SLOTS_NUMBER
onready var collider_top = -boundary_extents.y + collider_width / 2

var setpoint_positions = []
var setpoint_position = 0

var waves_count = 0
var score = 0
var score_state = 0

onready var input_axis = GameManager.get_player_control( get_player_variables()[ 0 ] )

var control_values = [ GameManager.get_default_controls() ]

static func get_player_variables():
	return [ "Player" ]

func _ready():
	$GUI.set_timeouts( 3.0, 0.0 )
	if input_axis.is_calibrating: $GUI.set_max_effort( 100.0 )
	else: $GUI.set_max_effort( 80.0 )
	#if Controller.direction_axis == Controller.HORIZONTAL:
	#	$Camera.rotate_z( PI / 2 )
	#	$Background.translation.x = $Camera.translation.x
	#	var background_size = $Background.region_rect.size
	#	background_size = Vector2( background_size.y, background_size.x )
	#	$Background.region_rect = Rect2( Vector2( 0, 0 ), background_size )
	input_axis.position_scale = boundary_extents.y
	input_axis.force_scale = 1.0
	control_values[ 0 ][ GameManager.SETPOINT ] = 0.0

func _physics_process( delta ):
	control_values[ 0 ][ GameManager.INPUT ] = input_axis.get_input( player.translation.y )
	player.move_and_slide( Vector3.BACK * control_values[ 0 ][ GameManager.INPUT ] )
	
	control_values[ 0 ][ GameManager.POSITION ] = player.translation.y
	
	control_values[ 0 ][ GameManager.IMPEDANCE ] = input_axis.impedance[ 1 ]
	
	if not input_axis.is_calibrating:
		DataLog.register_values( [ setpoint_position, player.translation.y, score_state ] )
		score_state = 0

func _set_setpoint():
	if setpoint_positions.size() > 0:
		setpoint_position = setpoint_positions.front()
		input_axis.setpoint = setpoint_position
		control_values[ 0 ][ GameManager.SETPOINT ] = setpoint_position

func _on_GUI_game_timeout( timeouts_count ):
	if timeouts_count < TOTAL_WAVES_NUMBER:
		var score_area = target_wall.instance()
		score_area.translation.x = boundary_extents.x + timeouts_count * 2 * score_area.get_width().x
		score_area.connect( "wall_passed", self, "_on_ScoreArea_wall_passed" )
		score_area.connect( "collider_reached", self, "_on_ScoreArea_collider_reached" )
		$BoundaryArea/Boundaries.add_child( score_area )
		var target_position = score_area.spawn_colliders( COLLIDER_SLOTS_NUMBER )
		setpoint_positions.push_back( target_position )
		_set_setpoint()

func _on_BoundaryArea_area_exited( area ):
	area.queue_free()

func _on_ScoreArea_wall_passed( has_passed_ok ):
	score_state = -1
	if has_passed_ok:
		score += 1
		score_state = 1
		var score_up = score_animation.instance()
		#player.add_child( score_up )
		player.call_deferred( "add_child", score_up )
	setpoint_positions.pop_front()
	waves_count += 1
	if waves_count >= TOTAL_WAVES_NUMBER: 
		DataLog.register_values( [ waves_count, score ] )
		$GUI.end_game( waves_count, score )
		DataLog.end_log()
	_set_setpoint()

func _on_ScoreArea_collider_reached( collider ):
	player.interact( collider )

func _on_GUI_game_toggle( started ):
	input_axis.setpoint = 0.0
	control_values[ 0 ][ GameManager.SETPOINT ] = 0.0
