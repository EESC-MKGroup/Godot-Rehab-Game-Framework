extends Panel

onready var position_slider = get_node( "PositionSlider" )
onready var position_display = get_node( "PositionSlider/NumericDisplay" )

func _ready():
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	$CalibrationToggle.pressed = Controller.is_calibrating
	$DirectionSelector.pressed = ( Controller.direction_axis == Controller.HORIZONTAL )
	Controller.set_status( 1 )

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	var axis_values = Controller.get_axis_values()
	var position = axis_values[ Controller.POSITION ]
	position_slider.value = position
	position_display.text = ( "%+.3f" % position )

func _on_ConnectButton_pressed():
	var server_address = Configuration.get_parameter( "server_address" )
	Controller.connect_client( server_address, 8000 )
	var user_name = Configuration.get_parameter( "user_name" )
	var time_stamp = OS.get_unix_time()
	Controller.set_identifier( user_name, time_stamp )
	DataLog.create_new_log( user_name, time_stamp )

func _on_AddressInput_text_changed( new_text ):
	Configuration.set_parameter( "server_address", new_text )

func _on_UserInput_text_changed( new_text ):
	Configuration.set_parameter( "user_name", new_text )

func _on_SetpointSlider_value_changed( value ):
	Controller.set_axis_values( value, 1 )

func _on_CalibrationToggle_toggled( button_pressed ):
	Controller.is_calibrating = button_pressed

func _on_DirectionSelector_toggled( button_pressed ):
	if button_pressed: Controller.direction_axis = Controller.HORIZONTAL
	else: Controller.direction_axis = Controller.VERTICAL
