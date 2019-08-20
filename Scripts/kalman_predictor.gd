var state = [ Vector3(), Vector3(), Vector3() ]
var state_predictor = Basis( Vector3( 1.0, 0, 0 ), 0.0 )
var input_predictor = Vector3()
var prediction_covariance = Basis( Vector3( 1.0, 0, 0 ), 0.0 )
var prediction_covariance_noise = [ 1.0, 1.0, 1.0 ]
var error_covariance_noise = [ 1.0, 1.0, 1.0 ]

func set_measurement( measureIndex, stateIndex, deviation ):
	error_covariance_noise[ measureIndex ][ measureIndex ] = deviation * deviation

func set_state_prediction_factor( newStateIndex, preStateIndex, ratio ):
	state_predictor[ newStateIndex ][ preStateIndex ] = ratio
    
func set_input_prediction_factor( newStateIndex, inputIndex, ratio ):
	input_predictor[ newStateIndex ][ inputIndex ] = ratio
    
func set_prediction_noise( stateIndex, deviation ):
	prediction_covariance_noise[ stateIndex ][ stateIndex ] = deviation * deviation
  
func predict( input=Vector3() ):
	for index in range( 3 ):
		state[ index ] = state_predictor * state[ index ] + input_predictor * input[ index ]
	
	prediction_covariance = state_predictor * prediction_covariance * state_predictor.transposed()
	for index in range( 3 ):
		prediction_covariance[ index ][ index ] += prediction_covariance_noise[ index ]
	
	return state
  
func update( measures, estimatedMeasures ):
	var error = []
	for index in range( 3 ):
		error.append( measures[ index ] - estimatedMeasures[ index ] )
	
	var error_covariance = prediction_covariance
	for index in range( 3 ):
		error_covariance[ index ][ index ] += error_covariance_noise[ index ]
	
	var gain = prediction_covariance * error_covariance.inverse()
	
	state = state + gain * error
	var prediction_covariance_delta = gain * prediction_covariance
	for line in range( 3 ):
		for col in range( 3 ):
			prediction_covariance[ line ][ col ] -= prediction_covariance_delta[ line ][ col ]
	
	return state
  
func process( measures, input=Vector3() ):
	var estimatedMeasures = predict( input )
	
	return update( measures, estimatedMeasures )