extends "res://Scripts/network_controller.gd"

onready var kalman_filter = preload( "res://Scripts/kalman_filter.gd" ) 
onready var position_observer = kalman_filter.new()
onready var force_observer = kalman_filter.new()

const COST_RATIO = 0.00001
const GAMMA = 0.7

var feedback_gain = Vector3.ZERO
var cost_2_go = Basis( Vector3( 1.0, 0, 0 ), 0.0 )

var local_damping = 0.0
var extra_energy = 0.0

func _ready():
	position_observer.error_covariance_noise[ 0 ] = 4.0
	position_observer.error_covariance_noise[ 1 ] = 2.0
	position_observer.error_covariance_noise[ 2 ] = 1.0
	position_observer.state_predictor[ 1 ][ 0 ] = time_step
	position_observer.state_predictor[ 2 ][ 0 ] = pow( time_step, 2 ) / 2
	position_observer.state_predictor[ 2 ][ 1 ] = time_step
	position_observer.state_predictor[ 2 ][ 2 ] = 0.0

	force_observer.prediction_covariance_noise[ 0 ] = 4.0
	force_observer.prediction_covariance_noise[ 1 ] = 2.0
	force_observer.prediction_covariance_noise[ 2 ] = 1.0
	force_observer.state_predictor[ 1 ][ 0 ] = time_step
	force_observer.state_predictor[ 2 ][ 0 ] = pow( time_step, 2 ) / 2
	force_observer.state_predictor[ 2 ][ 1 ] = time_step
	
	cost_2_go = _calculate_optimal_cost_2_go( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )
	feedback_gain = _calculate_feedback_gain( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )

func _calculate_feedback_input( remote_position, remote_velocity, remote_force ): 	
	var time_delay = int( network_delay / time_step ) * time_step
	var error_state = position_observer.predict( remote_force + external_force )
	target_position = remote_position #+ remote_velocity * time_delay
	target_velocity = remote_velocity
	var position_error = local_position - target_position
	var velocity_error = local_velocity - target_velocity
	error_state = position_observer.update( [ position_error, velocity_error, error_state[ 2 ] ] )
	
	var force_state = force_observer.predict()
	force_state = force_observer.update( [ remote_force, force_state[ 1 ], force_state[ 2 ] ] )
	var estimated_force = force_state[ 0 ] + force_state[ 1 ] * time_delay + force_state[ 2 ] * 0.5 * time_delay * time_delay
	
	return -( error_state * feedback_gain ) + estimated_force

remote func update_server( remote_position, remote_velocity, remote_force, client_time, last_server_time ):
	feedback_force = _calculate_feedback_input( remote_position, remote_velocity, remote_force )
	
	feedback_force = stabilize_force( feedback_force )
	
	.update_server( local_position, local_velocity, external_force, client_time, last_server_time )

remote func update_client( remote_position, remote_velocity, remote_force, server_time, last_client_time ):
	feedback_force = _calculate_feedback_input( remote_position, remote_velocity, remote_force )
	
	feedback_force = stabilize_force( feedback_force )
	
	.update_client( local_position, local_velocity, external_force, server_time, last_client_time )

func set_local_impedance( inertia, damping ):
	#position_observer.state_predictor[ 0 ][ 2 ] = -stiffness / inertia
	#position_observer.state_predictor[ 1 ][ 2 ] = -damping / inertia
	position_observer.input_predictor[ 2 ] = 1 / inertia
	
	local_damping = damping
	
	cost_2_go = _calculate_optimal_cost_2_go( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )
	feedback_gain = _calculate_feedback_gain( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )
	
	return local_damping

remote func set_remote_impedance( inertia, damping, stiffness ):
	position_observer.state_predictor[ 0 ][ 2 ] = -stiffness / inertia
	position_observer.state_predictor[ 1 ][ 2 ] = -damping / inertia
	#position_observer.input_predictor[ 2 ] = 1 / inertia
	
	cost_2_go = _calculate_optimal_cost_2_go( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )
	feedback_gain = _calculate_feedback_gain( position_observer.state_predictor, position_observer.input_predictor, cost_2_go )

func _calculate_optimal_cost_2_go( A, B, X ):
	X = A.transposed() * X * A
	for index in range( 3 ): X[ index ][ index ] += 1.0
	var aux = B.dot( X * B ) + COST_RATIO
	aux = ( A.transposed() * X * B ).outer( (1/aux) * B ) * X * A
	for line in range( 3 ): for col in range( 3 ): X[ line ][ col ] -= aux[ line ][ col ]
	return X

func _calculate_feedback_gain( A, B, X ):
	return ( 1 / ( B.dot( X * B ) + COST_RATIO ) ) * ( ( X * A ).transposed() * B )

func stabilize_force( input_force ):
	var input_power = input_force.dot( local_velocity )
	var damping_power = ( local_damping * local_velocity ).dot( local_velocity )
	if damping_power < 0.0: damping_power = 0.0
	var energy_diff = ( input_power - damping_power ) * time_step
	extra_energy = GAMMA * extra_energy + energy_diff
	var extra_damping_force = Vector3.ZERO
	if abs( local_velocity.length() ) > 0.001 and extra_energy > 0.0:
		extra_damping_force = local_velocity.normalized() * extra_energy / ( local_velocity.length() * time_step )
		if extra_damping_force.length() > input_force.length(): extra_damping_force = input_force
	extra_energy -= extra_damping_force.dot( local_velocity ) * time_step
	return input_force - extra_damping_force
