extends Spatial

enum OBJECT { WATERMELON = 1, BALLOON = -1 }
var current_object = BALLOON 

onready var setpoint_timer = get_node( "Timer" )

onready var setpoint_display = get_node( "GUI/SetpointDisplay" )
onready var start_button = get_node( "GUI/StartButton" )

onready var boundaries = get_node( "GameSpace/Boundaries" )
onready var max_position = boundaries.shape.extents.y

onready var hand = boundaries.get_node( "Hand" )
onready var target = boundaries.get_node( "Target" )
onready var ray = hand.get_node( "RayCast" )
onready var watermelon = hand.get_node( "Watermelon" )
onready var balloon = hand.get_node( "Balloon" )

func _ready():
	start_button.connect( "pressed", self, "_on_StartButton_pressed" )

func _enter_tree():
	Controller.set_status( 4 )

func _physics_process( delta ):
	var controller_values = Controller.get_axis_values( Controller.VERTICAL )
	var new_position = controller_values[ Controller.POSITION ] * max_position
	new_position = clamp( new_position, -max_position, max_position )
	hand.translation.y = new_position
	if ray.is_colliding(): _switch_and_reset()

func _switch_objects():
	if current_object == WATERMELON:
		balloon.show()
		watermelon.hide()
		current_object = BALLOON
	elif current_object == BALLOON:
		watermelon.show()
		balloon.hide()
		current_object = WATERMELON
	var target_position = current_object * max_position
	target.translation.y = target_position
	Controller.set_axis_values( Controller.VERTICAL, target_position, 1 )
	setpoint_display.text = ( "%+.3f" % current_object )

func _switch_and_reset():
	_switch_objects()
	setpoint_timer.stop()
	setpoint_timer.start()

func _on_StartButton_pressed():
	_switch_and_reset()

func _on_Timer_timeout():
	_switch_objects()
