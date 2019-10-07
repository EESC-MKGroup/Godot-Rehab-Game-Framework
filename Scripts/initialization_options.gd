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
	$UserInput.text = Settings.get_value( "user", "name", "User" )
	var interface_names = InputManager.interface_names
	$AddressInput/InterfaceSelector/Menu.list_entries( interface_names )
	$AddressInput/InterfaceSelector/Menu.select_entry_name( Settings.get_value( "device", "interface", "Null" ) )
	for interface_index in range( interface_names.size() ):
		var device = InputManager.get_interface_device( interface_index )
		device.connect( "state_changed", self, "_on_state_changed" )
		device.connect( "configs_listed", self, "_on_configs_listed" )
		device.connect( "config_received", self, "_on_config_received" )
		device.connect( "socket_connected", self, "_on_socket_connected" )
	$GameSelector/Menu.list_entries( GameManager.list_games() )
	$GameSelector/Menu.select_entry_name( Settings.get_value( "game", "title" ) )
	GameManager.list_files( "res://Scripts/Inputs", "" )
	set_process( false )
	
	var filter = load( "res://Scripts/kalman_filter.gd" ).new()
	filter.error_covariance_noise[ 0 ] = 4.0
	filter.error_covariance_noise[ 1 ] = 2.0
	filter.error_covariance_noise[ 2 ] = 1.0
	filter.state_predictor[ 1 ][ 0 ] = 0.02
	filter.state_predictor[ 2 ][ 0 ] = pow( 0.02, 2 ) / 2
	filter.state_predictor[ 2 ][ 1 ] = 0.02
	filter.state_predictor[ 2 ][ 2 ] = 0.0
	filter.input_predictor[ 2 ] = 1.0
	var COST_RATIO = 0.00001
	var A = filter.state_predictor
	var B = filter.input_predictor
	var X = Basis( Vector3( 1.0, 0, 0 ), 0.0 )
	print( "A: ", A )
	print( "B: ", B )
	for i in range( 10 ):
		X = A.transposed() * X * A
		for index in range( 3 ): X[ index ][ index ] += 1.0
		var aux = B.dot( X * B ) + COST_RATIO
		aux = ( A.transposed() * X * B ).outer( (1/aux) * B ) * X * A
		for line in range( 3 ): for col in range( 3 ): X[ line ][ col ] -= aux[ line ][ col ]
	print( "X: ", X )
	var gain = ( 1 / ( B.dot( X * B ) + COST_RATIO ) ) * ( ( X * A ).transposed() * B )
	var state = Basis( Vector3( 0.0, 0.0, 0.0 ), 0.0 )
	var input = Vector3( 0.0, 0.0, 0.0 )
	var setpoints = [ 0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0 ]
	print( "gain: ", gain )
	for setpoint in setpoints:
		#state = filter.predict()
		setpoint = Vector3( setpoint, 0, 0 )
		#state = filter.update( [ setpoint, state[ 1 ], state[ 2 ] ], state )
		state = filter.process( [ setpoint, state[ 1 ], state[ 2 ] ], input )
		print( "state: ", state[ 0 ], state[ 1 ], state[ 2 ] )
		input = -( state * gain )
		print( "input: ", input )

func _input( event ):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE: get_tree().quit()

func _process( delta ):
	$PositionSlider.value = input_axis.get_position()[ 0 ]
	$PositionSlider/NumericDisplay.text = ( "%+.3f" % $PositionSlider.value )
	$ForceSlider.value = input_axis.get_force()
	$ForceSlider/NumericDisplay.text = ( "%+.3f" % $ForceSlider.value )

func _on_ConnectButton_pressed():
	input_device.connect_socket( $AddressInput.text )

func _on_configs_listed( available_settingss ):
	$DeviceSelector/Menu.list_entries( available_settingss )
	#$DeviceSelector/Menu.select_entry_name( Settings.get_value( "device", "id" ) )

func _on_config_received( device_id, axes_list ):
	$AxisSelector/Menu.list_entries( axes_list )
	#$AxisSelector/Menu.select_entry_name( Settings.get_value( "device", "axis" ) )
	$EnabledToggle.disabled = false
	$OffsetToggle.disabled = false
	$CalibrationToggle.disabled = false
	$OperationToggle.disabled = false

func _on_state_changed( state_reply ):
	var toggle_states = [ false, false, false, false ]
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
	var default_address = InputManager.get_interface_default_address( index )
	$AddressInput.text = Settings.get_value( "device", "address_" + entry_name, default_address )
	Settings.set_value( "device", "interface", entry_name )

func _on_Device_entry_selected( index, entry_name ):
	device_index = index
	input_device.configuration = entry_name
	Settings.set_value( "device", "id", entry_name )

func _on_Axis_entry_selected( index, entry_name ):
	input_axis = InputManager.get_device_axis( interface_index, device_index, index )
	$CalibrationToggle.pressed = input_axis.is_calibrating
	set_process( true )
	Settings.set_value( "device", "axis", entry_name )
	GameManager.player_controls[ $VariableSelector/Menu.text ] = input_axis

func _on_Game_entry_selected( index, entry_name ):
	Settings.set_value( "game", "title", entry_name )
	$VariableSelector/Menu.list_entries( GameManager.list_game_variables( entry_name ) )
	$VariableSelector/Menu.select_entry_name( Settings.get_value( "game", "variable" ) )

func _on_Variable_entry_selected( index, entry_name ):
	GameManager.player_controls[ entry_name ] = input_axis
	Settings.set_value( "game", "variable", entry_name )

func _on_socket_connected():
	Settings.set_value( "device", "address_" + $AddressInput/InterfaceSelector/Menu.text, $AddressInput.text )
	Settings.set_value( "user", "name", $UserInput.text )
	input_device.user_name = $UserInput.text
	input_device.request_available_configurations()

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
	DataLog.start_new_log( $UserInput.text + " " + $GameSelector/Menu.text )
	GameManager.load_game( $GameSelector/Menu.text )