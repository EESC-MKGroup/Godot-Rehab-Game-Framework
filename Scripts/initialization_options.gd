extends Panel

onready var position_slider = get_node( "PositionSlider" )
onready var position_display = get_node( "PositionSlider/NumericDisplay" )

func _ready():
	if OS.get_cmdline_args()[ 0 ] == "-server":
		GameConnection.is_server = true
		GameManager.select( OS.get_cmdline_args()[ 1 ] )
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	$CalibrationToggle.pressed = RemoteDeviceClient.is_calibrating
	var font = $DeviceSelectionButton/SelectionList.get_font( "font" )
	$DeviceSelectionButton/SelectionList.get_popup().add_font_override( "font", font )
	$AxisSelectionButton/SelectionList.get_popup().add_font_override( "font", font )
	$DeviceSelectionButton/SelectionList.get_popup().connect( "index_pressed", self, "_on_Device_index_pressed" )
	$AxisSelectionButton/SelectionList.get_popup().connect( "index_pressed", self, "_on_Axis_index_pressed" )
	InfoStateClient.connect( "reply_received", self, "_on_reply_received" )
	InfoStateClient.connect( "client_connected", self, "_on_client_connected" )
	_refresh_devices_list()

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	position_slider.value = InputAxis.get_value()
	position_display.text = ( "%+.3f" % position_slider.value )

func _on_ConnectButton_pressed():
	print( "_on_ConnectButton_pressed" )
	RemoteDeviceClient.connect_client( $AddressInput.text )
	InfoStateClient.connect_client( $AddressInput.text )
	InfoStateClient.send_request( InfoStateClient.Request.GET_INFO )
#	DataLog.create_new_log( user_name, time_stamp )

func _refresh_devices_list():
	$DeviceSelectionButton/SelectionList.get_popup().clear()
	var devices = InputAxis.get_devices_list()
	for device_name in devices:
		$DeviceSelectionButton/SelectionList.get_popup().add_item( device_name )
	_on_Device_index_pressed( 0 )

func _on_reply_received( reply_code ):
	match reply_code:
		InfoStateClient.Reply.GOT_INFO:
			_refresh_devices_list()
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
	print( "_on_Device_index_pressed" )
	InputAxis.device_index = index
	$DeviceSelectionButton/SelectionList.text = $DeviceSelectionButton/SelectionList.get_popup().get_item_text( InputAxis.device_index )
	$AxisSelectionButton/SelectionList.get_popup().clear()
	var axes_list = InputAxis.get_axes_list()
	for axis_name in axes_list:
		$AxisSelectionButton/SelectionList.get_popup().add_item( axis_name )
	$AxisSelectionButton/SelectionList.text = $AxisSelectionButton/SelectionList.get_popup().get_item_text( 0 )

func _on_Axis_index_pressed( index ):
	print( "_on_Axis_index_pressed" )
	InputAxis.axis_index = index
	$AxisSelectionButton/SelectionList.text = $AxisSelectionButton/SelectionList.get_popup().get_item_text( InputAxis.axis_index )

func _on_client_connected():
	print( "_on_client_connected" )
	$ConnectButton.text = "Refresh"
	Configuration.set_parameter( "server_address", $AddressInput.text )
	Configuration.set_parameter( "user_name", $UserInput.text )

func _on_AddressInput_text_changed( new_text ):
	print( "_on_AddressInput_text_changed" )
	$ConnectButton.text = "Connect"

func _on_SetpointSlider_value_changed( value ):
	print( "_on_SetpointSlider_value_changed" )
	InputAxis.set_feedback( value )

func _on_CalibrationToggle_toggled( button_pressed ):
	print( "_on_CalibrationToggle_toggled" )
	var request = InfoStateClient.Request.CALIBRATE if button_pressed else InfoStateClient.Request.PASSIVATE
	InfoStateClient.send_request( request )
	RemoteDeviceClient.is_calibrating = button_pressed

func _on_OffsetToggle_toggled( button_pressed ):
	print( "_on_OffsetToggle_toggled" )
	var request = InfoStateClient.Request.OFFSET if button_pressed else InfoStateClient.Request.PASSIVATE
	InfoStateClient.send_request( request )