extends "res://Scripts/network_controller.gd"

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var position_observer = kalman_filter.new()
onready var force_observer = kalman_filter.new()
onready var time_step = get_physics_process_delta_time()

const COST_RATIO = 0.0001

var position_state = [ Vector3.ZERO, Vector3.ZERO, Vector3.ZERO ]
var force_state = [ Vector3.ZERO, Vector3.ZERO, Vector3.ZERO ]

var feedback_gain = Vector3.ZERO
var cost_2_go = Basis( Vector3( 1.0, 0, 0 ), 0.0 )

func _ready():
	position_observer.error_covariance_noise[ 0 ] = 4.0
	position_observer.error_covariance_noise[ 1 ] = 2.0
	position_observer.error_covariance_noise[ 2 ] = 1.0
	position_observer.state_predictor[ 0 ][ 1 ] = time_step
	position_observer.state_predictor[ 0 ][ 2 ] = pow( time_step, 2 ) / 2
	position_observer.state_predictor[ 1 ][ 2 ] = time_step
	position_observer.state_predictor[ 2 ][ 2 ] = 0.0

	force_observer.prediction_covariance_noise[ 0 ] = 4.0
	force_observer.prediction_covariance_noise[ 1 ] = 2.0
	force_observer.prediction_covariance_noise[ 2 ] = 1.0
	force_observer.state_predictor[ 0 ][ 1 ] = time_step
	force_observer.state_predictor[ 0 ][ 2 ] = pow( time_step, 2 ) / 2
	force_observer.state_predictor[ 1 ][ 2 ] = time_step

	cost_2_go = _calculate_optimal_cost_2_go( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )
	feedback_gain = _calculate_feedback_gain( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )

func predict_input_signal( remote_position, remote_velocity, remote_force, time_delay ): 	
	time_delay = int( time_delay / time_step ) * time_step
	position_state[ 0 ] = remote_position + remote_velocity * time_delay
	position_state[ 1 ] = remote_velocity
	position_state = position_observer.process( position_state, remote_force )
	force_state = force_observer.predict()
	force_state = force_observer.update( [ remote_force, force_state[ 1 ], force_state[ 2 ] ], force_state )
	remote_force = force_state[ 0 ] + force_state[ 1 ] * time_delay + force_state[ 2 ] * 0.5 * time_delay * time_delay
	
	return [ position_state, remote_force ]

remote func update_server( remote_position, remote_velocity, remote_force, client_time, last_server_time ):
	var remote_state = predict_input_signal( remote_position, remote_velocity, remote_force, network_delay )
	remote_position = remote_state[ 0 ][ 0 ]
	remote_force = remote_state[ 1 ]
	
	feedback_force = _calculate_feedback_input( feedback_gain, remote_state[ 0 ] ) + remote_force
	
	.update_server( remote_position, remote_velocity, remote_force, client_time, last_server_time )

remote func update_client( remote_position, remote_velocity, remote_force, server_time, last_client_time ):
	var remote_state = predict_input_signal( remote_position, remote_velocity, remote_force, network_delay )
	remote_position = remote_state[ 0 ][ 0 ]
	remote_force = remote_state[ 1 ]
	
	feedback_force = _calculate_feedback_input( feedback_gain, remote_state[ 0 ] ) + remote_force
	
	.update_client( remote_position, remote_velocity, remote_force, server_time, last_client_time )

func set_system( inertia, damping, stiffness ):
	position_observer.state_predictor[ 2 ][ 0 ] = -stiffness / inertia
	position_observer.state_predictor[ 2 ][ 1 ] = -damping / inertia
	position_observer.input_predictor[ 2 ][ 0 ] = 1 / inertia
	
	cost_2_go = _calculate_optimal_cost_2_go( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )
	feedback_gain = _calculate_feedback_gain( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )

func _calculate_optimal_cost_2_go( A, B, X0 ):
	var X = X0
	var X_old = Basis( Vector3( 0.0, 0.0, 0.0 ), 0.0 )
	for i in range( 10 ):#not X.is_equal_approx( X_old ):
		X_old = X
		X = A.transposed() * X_old * A
		for index in range( 3 ): X[ index ][ index ] += 1.0
		var aux = B.dot( X_old * B ) + COST_RATIO
		aux = ( A.transposed() * X_old * B ).outer( (1/aux) * B ) * X_old * A
		for line in range( 3 ): for col in range( 3 ): X[ line ][ col ] -= aux[ line ][ col ]
		if abs( X.determinant() - X_old.determinant() ) < 0.001: break
	return X

func _calculate_feedback_gain( A, B, X ):
	return ( 1 / ( B.dot( X * B ) + COST_RATIO ) ) * ( ( X * A ).transposed() * B )

func _calculate_feedback_input( gain, state ):
	return -( Basis( state[ 0 ], state[ 1 ], state[ 2 ] ) * gain )