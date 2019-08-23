#extends "res://Scripts/force_wave_controller.gd"
extends "res://Scripts/prediction_optimal_controller.gd"

sync func enable():
	.enable()
	initial_position = get_position_in_parent()

func _physics_process( delta ):
	local_position = translation 
	local_velocity = linear_velocity
	# Apply resulting force F_m to rigid body
	apply_central_impulse( feedback_force + external_force )

func _integrate_forces( state ):
	if was_reset:
		state.translation = initial_position
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		angular_velocity = linear_velocity.rotated( Vector3.UP, 90 ) / $Collider.shape.margin / 2
		was_reset = false