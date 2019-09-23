extends "res://Scripts/network_controller.gd"

var proportional_gain = 10.0
var derivative_gain = 5.0

remote func update_server( remote_position, remote_velocity, remote_force, last_server_time, client_time=0.0 ):
	var time_delay = calculate_delay( last_server_time )
	
	var position_error = remote_position - local_position
	var velocity_error = remote_velocity - local_velocity
	feedback_force = proportional_gain * position_error + derivative_gain * velocity_error
	
	.update_server( remote_position, remote_velocity, remote_force, client_time )

master func update_player( remote_position, remote_velocity, remote_force, last_client_time, server_time=0.0 ):
	var time_delay = calculate_delay( last_client_time )

	var position_error = remote_position - local_position
	var velocity_error = remote_velocity - local_velocity
	feedback_force = proportional_gain * position_error + derivative_gain * velocity_error
	
	.update_player( remote_position, remote_velocity, remote_force, server_time )

func set_system( inertia, damping, stiffness ):
	proportional_gain = stiffness
	derivative_gain = damping