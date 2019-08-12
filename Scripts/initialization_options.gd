extends Panel

var interface_index = 0
var device_index = 0

var input_device = null
var input_axis = null

func _ready():
	if OS.get_cmdline_args().size() > 1:
		if OS.get_cmdline_args()[ 0 ] == "--server":
			GameConnection.is_server = true
			GameManager.load_game( OS.get_cmdline_args()[ 1 ] )
	$AddressInput.text = Configuration.get_parameter( "server_address" )
	$UserInput.text = Configuration.get_parameter( "user_name" )
	var interface_names = InputManager.interface_names
	$AddressInput/InterfaceSelector/SelectionList.list_entries( interface_names )
	$AddressInput/InterfaceSelector/SelectionList.select_entry_name( Configuration.get_parameter( "interface" ) )
	for interface_index in range( interface_names.size() ):
		var device = InputManager.get_interface_device( interface_index )
		device.connect( "state_changed", self, "_on_state_changed" )
		device.connect( "configs_listed", self, "_on_configs_listed" )
		device.connect( "config_received", self, "_on_config_received" )
		device.connect( "socket_connected", self, "_on_socket_connected" )
	$GameSelector/SelectionList.list_entries( GameManager.list_games() )
	$GameSelector/SelectionList.select_entry_name( Configuration.get_parameter( "game" ) )
	set_process( false )

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	$PositionSlider.value = input_axis.get_position()
	$PositionSlider/NumericDisplay.text = ( "%+.3f" % $PositionSlider.value )
	$ForceSlider.value = input_axis.get_force()
	$ForceSlider/NumericDisplay.text = ( "%+.3f" % $ForceSlider.value )

func _on_ConnectButton_pressed():
	input_device.connect_socket( $AddressInput.text )
#	DataLog.create_new_log( user_name, time_stamp )

func _on_configs_listed( available_configurations ):
	$DeviceSelector/SelectionList.list_entries( available_configurations )
	#$DeviceSelector/SelectionList.select_entry_name( Configuration.get_parameter( "device" ) )

func _on_config_received( device_id, axes_list ):
	$AxisSelector/SelectionList.list_entries( axes_list )
	$AxisSelector/SelectionList.select_entry_name( Configuration.get_parameter( "axis" ) )
	$EnabledToggle.disabled = false
	$OffsetToggle.disabled = false
	$CalibrationToggle.disabled = false
	$OperationToggle.disabled = false

func _on_state_changed( state_reply ):
	var toggle_states = [ false, false, false, false ]
	print( "state reply: " + str(state_reply) )
	match state_reply:
		InputManager.Reply.ENABLED: toggle_states = [ true, true, false, false ]
		InputManager.Reply.OFFSETTING: toggle_states = [ true, true, false, false ]
		InputManager.Reply.CALIBRATING: toggle_states = [ true, false, true, false ]
		InputManager.Reply.OPERATING: toggle_states = [ true, false, false, true ]
		InputManager.Reply.PASSIVE: toggle_states = [ true, false, false, false ]
	$EnabledToggle.pressed = toggle_states[ 0 ]
	$OffsetToggle.pressed = toggle_states[ 1 ]
	$CalibrationToggle.pressed = toggle_states[ 2 ]
	$OperationToggle.pressed = toggle_states[ 3 ]

func _on_Interface_entry_selected( index, entry_name ):
	interface_index = index
	input_device = InputManager.get_interface_device( index )
	Configuration.set_parameter( "interface", entry_name )

func _on_Device_entry_selected( index, entry_name ):
	device_index = index
	input_device.configuration = entry_name
	Configuration.set_parameter( "device", entry_name )

func _on_Axis_entry_selected( index, entry_name ):
	input_axis = InputManager.get_device_axis( interface_index, device_index, index )
	$CalibrationToggle.pressed = input_axis.is_calibrating
	set_process( true )
	Configuration.set_parameter( "axis", entry_name )

func _on_Game_entry_selected( index, entry_name ):
	Configuration.set_parameter( "game", entry_name )
	$VariableSelector/SelectionList.list_entries( GameManager.list_game_variables( entry_name ) )
	$VariableSelector/SelectionList.select_entry_name( Configuration.get_parameter( "game_variable" ) )

func _on_Variable_entry_selected( index, entry_name ):
	GameManager.player_controls[ entry_name ] = input_axis
	Configuration.set_parameter( "game_variable", entry_name )

func _on_socket_connected():
	Configuration.set_parameter( "server_address", $AddressInput.text )
	Configuration.set_parameter( "user_name", $UserInput.text )
	input_device.request_available_configurations()
	input_device.user_name = $UserInput.text

#func _on_AddressInput_text_changed( new_text ):
#	print( "_on_AddressInput_text_changed" )

func _on_PositionSetpointSlider_value_changed( value ):
	input_axis.set_position( value )

func _on_ForceSetpointSlider_value_changed( value ):
	input_axis.set_force( value )

func _on_EnabledToggle_toggled( button_pressed ):
	if button_pressed: input_device.request_state_change( InputManager.Request.ENABLE )
	else: input_device.request_state_change( InputManager.Request.DISABLE )

func _on_CalibrationToggle_toggled( button_pressed ):
	if button_pressed: input_device.request_state_change( InputManager.Request.CALIBRATE )
	else: input_device.request_state_change( InputManager.Request.PASSIVATE )
	input_axis.is_calibrating = button_pressed

func _on_OffsetToggle_toggled( button_pressed ):
	if button_pressed: input_device.request_state_change( InputManager.Request.OFFSET )
	else: input_device.request_state_change( InputManager.Request.PASSIVATE )

func _on_OperationToggle_toggled(button_pressed):
	if button_pressed: input_device.request_state_change( InputManager.Request.OPERATE )
	else: input_device.request_state_change( InputManager.Request.PASSIVATE )

func _on_PlayButton_pressed():
	GameManager.load_game( Configuration.get_parameter( "game" ) )