extends "res://Scripts/network_controller.gd"

var proportional_gain = 10.0
var derivative_gain = 5.0

remote func update_server( remote_position, remote_velocity, remote_force, client_time, last_server_time ):
	target_position = remote_position + remote_velocity * network_delay
	target_velocity = remote_velocity
	var position_error = target_position - local_position
	var velocity_error = target_velocity - local_velocity
	feedback_force = proportional_gain * position_error + derivative_gain * velocity_error
	print( "feedback: ", proportional_gain, "*", position_error, "+", derivative_gain, "*", velocity_error, "=", feedback_force )
	.update_server( local_position, local_velocity, external_force, client_time, last_server_time )

remote func update_client( remote_position, remote_velocity, remote_force, server_time, last_client_time ):
	target_position = remote_position + remote_velocity * network_delay
	target_velocity = remote_velocity
	var position_error = target_position - local_position
	var velocity_error = target_velocity - local_velocity
	feedback_force = proportional_gain * position_error + derivative_gain * velocity_error

	.update_client( local_position, local_velocity, external_force, server_time, last_client_time )

func set_system( inertia, damping, stiffness ):
	proportional_gain = (2.0/3) * ( inertia + damping + stiffness ) / time_step / 2
	derivative_gain = (1.0/3) * ( inertia + damping + stiffness ) / time_step / 2
