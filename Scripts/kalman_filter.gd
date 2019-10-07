var state = Basis( Vector3( 0.0, 0.0, 0.0 ), 0.0 )
var state_predictor = Basis( Vector3( 1.0, 0.0, 0.0 ), 0.0 )
var input_predictor = Vector3.ZERO
var prediction_covariance = Basis( Vector3( 1.0, 0, 0 ), 0.0 )
var prediction_covariance_noise = [ 1.0, 1.0, 1.0 ]
var error_covariance_noise = [ 1.0, 1.0, 1.0 ]
  
func predict( input=Vector3() ):
	for index in range( 3 ): state[ index ] = state_predictor * state[ index ] + input_predictor * input[ index ]

	prediction_covariance = state_predictor * prediction_covariance * state_predictor.transposed()
	for index in range( 3 ): prediction_covariance[ index ][ index ] += prediction_covariance_noise[ index ]
	
	return state.transposed()
  
func update( measures ):
	measures = Basis( measures[ 0 ], measures[ 1 ], measures[ 2 ] ).transposed()

	var error = []
	for index in range( 3 ): error.append( measures[ index ] - state[ index ] )
	
	var error_covariance = prediction_covariance
	for index in range( 3 ): error_covariance[ index ][ index ] += error_covariance_noise[ index ]
	
	var gain = prediction_covariance * error_covariance.inverse()
	
	for index in range( 3 ): state[ index ] = state[ index ] + gain * error[ index ]
	var prediction_covariance_delta = gain * prediction_covariance
	for line in range( 3 ): for col in range( 3 ): prediction_covariance[ line ][ col ] -= prediction_covariance_delta[ line ][ col ]
	
	return state.transposed()
  
func process( measures, input=Vector3() ):
	var estimatedMeasures = predict( input )
	
	return update( measures )