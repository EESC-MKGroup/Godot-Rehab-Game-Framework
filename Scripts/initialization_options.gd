extends Panel

onready var server_address_entry = get_node( "AddressInput" )
onready var user_name_entry = get_node( "UserInput" )
onready var position_slider = get_node( "PositionSlider" )
onready var position_display = get_node( "PositionSlider/NumericDisplay" )
onready var calibration_toggle = get_node( "CalibrationToggle" )

func _ready():
	Controller.set_status( 1 )
	server_address_entry.text = Configuration.get_parameter( "server_address" )
	user_name_entry.text = Configuration.get_parameter( "user_name" )
	calibration_toggle.pressed = Controller.is_calibrating

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	var axis_values = Controller.get_axis_values( Controller.VERTICAL )
	var position = axis_values[ Controller.POSITION ]
	position_slider.value = position
	position_display.text = ( "%+.3f" % position )

func _on_ConnectButton_pressed():
	Controller.connect_client( Configuration.get_parameter( "server_address" ), 8000 )
	Controller.set_user( Configuration.get_parameter( "user_name" ) )

func _on_AddressInput_text_entered( new_text ):
	Configuration.set_parameter( "server_address", new_text )

func _on_UserInput_text_entered( new_text ):
	Configuration.set_parameter( "user_name", new_text )

func _on_SetpointSlider_value_changed( value ):
	Controller.set_axis_values( Controller.VERTICAL, value, 1 )

func _on_CalibrationToggle_toggled( button_pressed ):
	Controller.is_calibrating = button_pressed
