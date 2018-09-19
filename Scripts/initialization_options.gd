extends Panel

onready var position_slider = get_node( "PositionSlider" )
onready var position_display = get_node( "PositionSlider/NumericDisplay" )

func _ready():
	if OS.get_cmdline_args().size() > 1:
		if OS.get_cmdline_args()[ 0 ] == "-server":
			GameConnection.is_server = true
			GameManager.select( OS.get_cmdline_args()[ 1 ] )
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	$CalibrationToggle.pressed = RemoteDevice.is_calibrating
	var font = $DeviceSelectionButton/SelectionList.get_font( "font" )
	$DeviceSelectionButton/SelectionList.get_popup().add_font_override( "font", font )
	$AxisSelectionButton/SelectionList.get_popup().add_font_override( "font", font )
	$DeviceSelectionButton/SelectionList.get_popup().connect( "index_pressed", self, "_on_Device_index_pressed" )
	$AxisSelectionButton/SelectionList.get_popup().connect( "index_pressed", self, "_on_Axis_index_pressed" )
	InputDevice.connect( "reply_received", self, "_on_reply_received" )
	InputDevice.connect( "socket_connected", self, "_on_socket_connected" )
	_refresh_devices_list()

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	position_slider.value = InputAxis.get_value()
	position_display.text = ( "%+.3f" % position_slider.value )

func _on_ConnectButton_pressed():
	print( "_on_ConnectButton_pressed" )
	InputDevice.connect_socket( $AddressInput.text )
	InputDevice.state = InputDevice.GET_INFO
#	DataLog.create_new_log( user_name, time_stamp )

func _refresh_devices_list():
	$DeviceSelectionButton/SelectionList.get_popup().clear()
	for interface_name in InputDevice.interfaces_list:
		$DeviceSelectionButton/SelectionList.get_popup().add_item( interface_name )
	_on_Device_index_pressed( 0 )

func _refresh_axes_list():
	$AxisSelectionButton/SelectionList.get_popup().clear()
	var device_name = InputDevice.string_id
	for axis_name in InputDevice.axes_list:
		$AxisSelectionButton/SelectionList.get_popup().add_item( device_name + "-" + axis_name )
	_on_Axis_index_pressed( 0 )

func _on_reply_received( reply_code ):
	match reply_code:
		InputDevice.GET_INFO:
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
	InputDevice.set_interface( index )
	$DeviceSelectionButton/SelectionList.text = $DeviceSelectionButton/SelectionList.get_popup().get_item_text( index )

func _on_Axis_index_pressed( index ):
	print( "_on_Axis_index_pressed" )
	InputAxis.axis_index = index
	$AxisSelectionButton/SelectionList.text = $AxisSelectionButton/SelectionList.get_popup().get_item_text( InputAxis.axis_index )

func _on_socket_connected():
	print( "_on_socket_connected" )
	Configuration.set_parameter( "server_address", $AddressInput.text )
	Configuration.set_parameter( "user_name", $UserInput.text )
	_refresh_axes_list()

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