extends Node

class PlayerVariable:
	var limits = [ 0, 0 ]
	var offset = 0
	var name = ""
	var deviceID = 0
	var axisID = 0

var player_variables = [] setget ,_get_player_variables

func _get_player_variables():
	return player_variables