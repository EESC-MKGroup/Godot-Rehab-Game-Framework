extends Panel

const INFO_SERVER_STATE_PORT = 50000

onready var position_slider = get_node( "PositionSlider" )
onready var position_display = get_node( "PositionSlider/NumericDisplay" )

func _ready():
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	$CalibrationToggle.pressed = RemoteAxisClient.is_calibrating
	$DirectionSelector.pressed = ( RemoteAxisClient.direction_axis == RemoteAxisClient.HORIZONTAL )
	InfoStateClient.connect( "state_changed", self, "_on_state_changed" )
	InfoStateClient.connect( "client_connected", self, "_on_client_connected" )

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	var axis_values = RemoteAxisClient.get_axis_values()
	var position = axis_values[ RemoteAxisClient.POSITION ]
	position_slider.value = position
	position_display.text = ( "%+.3f" % position )

func _on_ConnectButton_pressed():
	var server_address = Configuration.get_parameter( "server_address" )
	InfoStateClient.connect_client( server_address, INFO_SERVER_STATE_PORT )
	InfoStateClient.refresh_axes_info()
#	var user_name = Configuration.get_parameter( "user_name" )
#	var time_stamp = OS.get_unix_time()
#	RemoteAxisClient.set_identifier( user_name, time_stamp )
#	DataLog.create_new_log( user_name, time_stamp )

func _on_state_changed( new_state ):
	if new_state == InfoStateClient.GOT_INFO:
		var axes_list = InfoStateClient.get_axes_list()

func _on_client_connected():
	$ConnectButton.text = "Refresh"

func _on_AddressInput_text_changed( new_text ):
	Configuration.set_parameter( "server_address", new_text )
	$ConnectButton.text = "Connect"

func _on_UserInput_text_changed( new_text ):
	Configuration.set_parameter( "user_name", new_text )

func _on_SetpointSlider_value_changed( value ):
	RemoteAxisClient.set_axis_values( value, 1 )

func _on_CalibrationToggle_toggled( button_pressed ):
	RemoteAxisClient.is_calibrating = button_pressed

func _on_DirectionSelector_toggled( button_pressed ):
	if button_pressed: RemoteAxisClient.direction_axis = RemoteAxisClient.HORIZONTAL
	else: RemoteAxisClient.direction_axis = RemoteAxisClient.VERTICAL
