extends Panel

var game_name = ""

var interface = null
var input_device = null
var input_axis = null

func _ready():
	if OS.get_cmdline_args().size() > 1:
		if OS.get_cmdline_args()[ 0 ] == "--server":
			GameConnection.is_server = true
			GameManager.select( OS.get_cmdline_args()[ 1 ] )
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	#$CalibrationToggle.pressed = InputAxis.is_calibrating
	$GameSelector/SelectionList.list_entries( GameManager.list_games() )
	$AddressInput/InterfaceSelector/SelectionList.list_entries( InputManager.interfaces_list )
	for interface_name in InputManager.interfaces_list:
		var device = InputManager.get_interface_device( interface_name )
		device.connect( "state_changed", self, "_on_state_changed" )
		device.connect( "socket_connected", self, "_on_socket_connected" )
	set_process( false )

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	$PositionSlider.value = input_axis.get_value()
	$PositionSlider/NumericDisplay.text = ( "%+.3f" % $PositionSlider.value )
	$ForceSlider.value = input_axis.get_value()
	$ForceSlider/NumericDisplay.text = ( "%+.3f" % $ForceSlider.value )

func _on_ConnectButton_pressed():
	print( "_on_ConnectButton_pressed" )
	input_device.connect_socket( $AddressInput.text )
#	DataLog.create_new_log( user_name, time_stamp )

func _on_state_changed( new_state ):
	match new_state:
		State.LIST_CONFIGS:
			$DeviceSelector/SelectionList.list_entries( input_device.available_configurations )
		State.GET_CONFIG:
			$AxisSelector/SelectionList.list_entries( input_device.axes_list )
		State.OFFSET:
			$OffsetToggle.pressed = true
			$CalibrationToggle.pressed = false
		State.CALIBRATION:
			$OffsetToggle.pressed = false
			$CalibrationToggle.pressed = true
		_:
#		State.PASSIVE:
			$OffsetToggle.pressed = false
			$CalibrationToggle.pressed = false

func _on_Interface_entry_selected( index, entry_name ):
	print( "_on_Interface_entry_selected" )
	input_device = InputManager.get_interface_device( entry_name )

func _on_Device_entry_selected( index, entry_name ):
	print( "_on_Device_entry_selected" )
	input_device.configuration = entry_name

func _on_Axis_entry_selected( index, entry_name ):
	print( "_on_Axis_entry_selected" )
	input_axis = InputManager.get_device_axis( input_device, index )
	set_process( true )

func _on_Game_entry_selected( index, entry_name ):
	print( "_on_Game_entry_selected" )
	game_name = entry_name
	$VariableSelector/SelectionList.list_entries( GameManager.list_game_variables( game_name ) )

func _on_Variable_entry_selected( index, entry_name ):
	print( "_on_Variable_entry_selected" )
	#GameManager.player_controls[ game_name + "_" + entry_name ] = InputAxis.new( InputDevice.interface_index, InputAxis.axis_index )

func _on_socket_connected():
	print( "_on_socket_connected" )
	Configuration.set_parameter( "server_address", $AddressInput.text )
	Configuration.set_parameter( "user_name", $UserInput.text )
	InputDevice.state = State.LIST_CONFIGS

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

func _on_PlayButton_pressed():
	GameManager.load_game( game_name )
