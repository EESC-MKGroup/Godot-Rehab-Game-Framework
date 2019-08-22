#extends "res://Scripts/force_wave_controller.gd"
extends "res://Scripts/prediction_optimal_controller.gd"

func _physics_process( delta ):
	local_position = translation 
	local_velocity = linear_velocity
	# Apply resulting force F_m to rigid body
	apply_central_impulse( feedback_force + external_force )