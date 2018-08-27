extends RigidBody

enum Coordinate { X, Y, Z }
enum Variable { POSITION, IMPEDANCE = POSITION,
				VELOCITY, FILTER = VELOCITY,
				ACCELERATION, FORCE = ACCELERATION, WAVE = FORCE,
				MOMENTUM, WAVE_INTEGRAL = MOMENTUM }

var element_id = -1

var initial_position = Vector3.ZERO

var last_input = Vector3.ZERO
var last_delayed_input = Vector3.ZERO
var last_time_step = 0

func enable():
	linear_velocity = Vector3()
	angular_velocity = Vector3()
	
	#var extents = $Collider.shape.extents;
	#//rangeLimits = boundaries.bounds.extents - Vector3.one * GetComponent<Collider>().bounds.extents.magnitude;
	#Vector3 bodyExtents = transform.rotation * GetComponent<Collider>().bounds.extents;
	#rangeLimits = new Vector3( boundaries.bounds.extents.x - Mathf.Abs( bodyExtents.x ), 
	#	                       boundaries.bounds.extents.y - Mathf.Abs( bodyExtents.y ), 
	#	                       boundaries.bounds.extents.z - Mathf.Abs( bodyExtents.z ) );
	
	initial_position = get_position_in_parent()
	last_time_step = OS.get_system_time_secs()

sync func reset():
	translation = initial_position
	linear_velocity = Vector3()
	angular_velocity = Vector3()

# Half round-trip time calculation
#func calculate_delay( dispatch_time, arrival_time ): 

func filter_delayed_input( delayed_input, error_integral, delay ):
	delayed_input += error_integral
	
	# Filter delayed input to ensure stability: x_out / x_in = l / ( s + l ) => discrete form (s = 2/T * (z-1)/(z+1))
	# x_out = ( (2-lT) * x_out_old + lT * (x_in+u_in_old) ) / (2+lT), where l = 1/delay
	var step = ( OS.get_system_time_secs() - last_time_step ) / delay
	var result = ( ( 2 - step ) * last_input + step * ( delayed_input + last_delayed_input ) ) / ( 2 + step )
	last_input = result
	last_delayed_input = delayed_input
	last_time_step = OS.get_system_time_secs()
	
	return result