extends "res://Scripts/wave_prediction_controller.gd"
#extends "res://Scripts/force_wave_controller.gd"
#extends "res://Scripts/prediction_optimal_controller.gd"
#extends "res://Scripts/pd_controller.gd"

func _ready():
	local_position = translation

func _physics_process( delta ):
	local_position = translation 
	local_velocity = linear_velocity
	var resulting_force = feedback_force + external_force
	if abs( resulting_force.length() ) > 0.01:
		local_acceleration = resulting_force.normalized() * mass / resulting_force.length()
	# Apply resulting force F_m to rigid body
	add_central_force( feedback_force + external_force )

func _integrate_forces( state ):
	if was_reset:
		state.transform.origin = target_position
		state.linear_velocity = target_velocity
		was_reset = false

func set_local_impedance( inertia, damping ):
	mass = inertia
	return .set_local_impedance( inertia, damping )
