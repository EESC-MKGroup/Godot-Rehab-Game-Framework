extends Panel

onready var position_slider = get_node( "PositionSlider" )
onready var position_display = get_node( "PositionSlider/NumericDisplay" )

func _ready():
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	$CalibrationToggle.pressed = RemoteAxisClient.is_calibrating
	$DeviceSelectionButton/SelectionList.get_popup().add_font_override( "font", get_font( "font" ) )
	$AxisSelectionButton/SelectionList.get_popup().add_font_override( "font", get_font( "font" ) )
	$DeviceSelectionButton/SelectionList.get_popup().connect( "index_pressed", self, "_on_Device_index_pressed" )
	$AxisSelectionButton/SelectionList.get_popup().connect( "index_pressed", self, "_on_Axis_index_pressed" )
#	for variable_name in [ "Position", "Velocity", "Acceleration", "Force", "Inertia", "Stiffness", "Damping" ]:
#		$VariableSelectionButton/AxisSelectionList.get_popup().add_item( variable_name )
	InfoStateClient.connect( "reply_received", self, "_on_reply_received" )
	InfoStateClient.connect( "client_connected", self, "_on_client_connected" )

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	position_slider.value = InputAxis.get_value()
	position_display.text = ( "%+.3f" % position_slider.value )

func _on_ConnectButton_pressed():
	RemoteAxisClient.connect_client( $AddressInput.text )
	InfoStateClient.connect_client( $AddressInput.text )
	InfoStateClient.send_request( InfoStateClient.Request.GET_INFO )
#	DataLog.create_new_log( user_name, time_stamp )

func _on_reply_received( reply_code ):
	match reply_code:
		InfoStateClient.Reply.GOT_INFO:
			$DeviceSelectionButton/SelectionList.get_popup().clear()
			var devices = InputAxis.get_devices_list()
			for device_name in devices:
				$DeviceSelectionButton/SelectionList.get_popup().add_item( device_name )
			_on_Device_index_pressed( 0 )
		InfoStateClient.Reply.OFFSETTING:
			$OffsetToggle.pressed = true
			$CalibrationToggle.pressed = false
		InfoStateClient.Reply.CALIBRATING:
			$OffsetToggle.pressed = false
			$CalibrationToggle.pressed = true
		_:
#		InfoStateClient.Reply.PASSIVATING:
			$OffsetToggle.pressed = false
			$CalibrationToggle.pressed = false

func _on_Device_index_pressed( index ):
	InputAxis.device_index = index
	$AxisSelectionButton/AxisSelectionList.get_popup().clear()
	var axes_list = InputAxis.get_axes_list()
	for axis_name in axes_list:
		$AxisSelectionButton/AxisSelectionList.get_popup().add_item( axis_name )

func _on_Axis_index_pressed( index ):
	InputAxis.axis_index = index

func _on_client_connected():
	$ConnectButton.text = "Refresh"
	Configuration.set_parameter( "server_address", $AddressInput.text )
	Configuration.set_parameter( "user_name", $UserInput.text )

func _on_AddressInput_text_changed( new_text ):
	$ConnectButton.text = "Connect"

func _on_SetpointSlider_value_changed( value ):
	InputAxis.set_feedback( value )

func _on_CalibrationToggle_toggled( button_pressed ):
	var request = InfoStateClient.Request.CALIBRATE if button_pressed else InfoStateClient.Request.PASSIVATE
	InfoStateClient.send_request( request )
	RemoteAxisClient.is_calibrating = button_pressed

func _on_OffsetToggle_toggled( button_pressed ):
	var request = InfoStateClient.Request.OFFSET if button_pressed else InfoStateClient.Request.PASSIVATE
	InfoStateClient.send_request( request )