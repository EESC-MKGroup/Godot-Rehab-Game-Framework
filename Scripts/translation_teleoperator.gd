#extends "res://Scripts/force_wave_controller.gd"
#extends "res://Scripts/prediction_optimal_controller.gd"
extends "res://Scripts/pd_controller.gd"

func _physics_process( delta ):
	local_position = translation 
	local_velocity = linear_velocity
	# Apply resulting force F_m to rigid body
	var resulting_force = global_transform.basis * ( feedback_force + external_force )
	add_central_force( resulting_force )

func _integrate_forces( state ):
	if was_reset:
		state.transform.origin = target_position
		state.linear_velocity = target_velocity
		was_reset = false