extends Panel

func _ready():
	if OS.get_cmdline_args().size() > 1:
		if OS.get_cmdline_args()[ 0 ] == "--server":
			GameConnection.is_server = true
			GameManager.select( OS.get_cmdline_args()[ 1 ] )
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	$CalibrationToggle.pressed = InputAxis.is_calibrating
	var font = $DeviceSelector/SelectionList.get_font( "font" )
	$DeviceSelector/SelectionList.get_popup().add_font_override( "font", font )
	$AxisSelector/SelectionList.get_popup().add_font_override( "font", font )
	$GameSelector/SelectionList.get_popup().add_font_override( "font", font )
	$VariableSelector/SelectionList.get_popup().add_font_override( "font", font )
	$DeviceSelector/SelectionList.get_popup().connect( "index_pressed", self, "_on_Device_index_pressed" )
	$AxisSelector/SelectionList.get_popup().connect( "index_pressed", self, "_on_Axis_index_pressed" )
	$GameSelector/SelectionList.get_popup().connect( "index_pressed", self, "_on_Game_index_pressed" )
	$VariableSelectorSelector/SelectionList.get_popup().connect( "index_pressed", self, "_on_Variable_index_pressed" )
	InputDevice.connect( "state_changed", self, "_on_state_changed" )
	InputDevice.connect( "socket_connected", self, "_on_socket_connected" )
	_refresh_devices_list()

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	$PositionSlider.value = InputAxis.get_value()
	$PositionSlider/NumericDisplay.text = ( "%+.3f" % $PositionSlider.value )
	$ForceSlider.value = InputAxis.get_value()
	$ForceSlider/NumericDisplay.text = ( "%+.3f" % $ForceSlider.value )

func _on_ConnectButton_pressed():
	print( "_on_ConnectButton_pressed" )
	InputDevice.connect_socket( $AddressInput.text )
#	DataLog.create_new_log( user_name, time_stamp )

func _refresh_devices_list():
	$DeviceSelector/SelectionList.get_popup().clear()
	for interface_name in InputDevice.interfaces_list:
		$DeviceSelector/SelectionList.get_popup().add_item( interface_name )
	_on_Device_index_pressed( 0 )

func _refresh_axes_list():
	$AxisSelector/SelectionList.get_popup().clear()
	var device_name = InputDevice.string_id
	print( InputDevice.axes_list )
	for axis_name in InputDevice.axes_list:
		$AxisSelector/SelectionList.get_popup().add_item( device_name + " - " + axis_name )
	_on_Axis_index_pressed( 0 )

func _on_state_changed( new_state ):
	match new_state:
		InputDevice.LIST_CONFIGS:
			_refresh_devices_list()
		InputDevice.OFFSET:
			$OffsetToggle.pressed = true
			$CalibrationToggle.pressed = false
		InputDevice.CALIBRATION:
			$OffsetToggle.pressed = false
			$CalibrationToggle.pressed = true
		_:
#		InputDevice.PASSIVE:
			$OffsetToggle.pressed = false
			$CalibrationToggle.pressed = false

func _on_Device_index_pressed( index ):
	print( "_on_Device_index_pressed" )
	InputDevice.interface_index = index
	var interface_name = $DeviceSelector/SelectionList.get_popup().get_item_text( InputDevice.interface_index )
	$DeviceSelector/SelectionList.text = interface_name
	InputDevice.state = InputDevice.SET_CONFIG
	_refresh_axes_list()

func _on_Axis_index_pressed( index ):
	print( "_on_Axis_index_pressed" )
	InputAxis.axis_index = index
	var axis_name = $AxisSelector/SelectionList.get_popup().get_item_text( InputAxis.axis_index )
	$AxisSelector/SelectionList.text = axis_name

func _on_socket_connected():
	print( "_on_socket_connected" )
	Configuration.set_parameter( "server_address", $AddressInput.text )
	Configuration.set_parameter( "user_name", $UserInput.text )
	InputDevice.state = InputDevice.LIST_CONFIGS

func _on_AddressInput_text_changed( new_text ):
	print( "_on_AddressInput_text_changed" )

func _on_SetpointSlider_value_changed( value ):
	print( "_on_SetpointSlider_value_changed" )
	InputAxis.set_feedback( value )

func _on_CalibrationToggle_toggled( button_pressed ):
	print( "_on_CalibrationToggle_toggled" )
	InputDevice.state = InputDevice.CALIBRATION if button_pressed else InputDevice.PASSIVE
	InputAxis.is_calibrating = button_pressed

func _on_OffsetToggle_toggled( button_pressed ):
	print( "_on_OffsetToggle_toggled" )
	InputDevice.state = InputDevice.OFFSET if button_pressed else InputDevice.PASSIVE