extends Node

const CONFIG_FILE_PATH = "user://config.json"

var parameters = { 
                     "server_address": "127.0.0.1",
                     "user_name": "User"
                 }

func _ready():
	var config_file = File.new()
	if config_file.open( CONFIG_FILE_PATH, File.READ ) == OK:
		var json_string = config_file.get_as_text()
		var parse_result = parse_json( json_string )
		if typeof(parse_result) == TYPE_DICTIONARY:
			for key in parse_result.keys():
				parameters[ key ] = parse_result[ key ]
		config_file.close()

func set_parameter( key, value ):
	parameters[ key ] = value
	_save_parameters()

func get_parameter( key ):
	if not parameters.has( key ): return null
	return parameters[ key ]

func _save_parameters():
	var config_file = File.new()
	if config_file.open( CONFIG_FILE_PATH, File.WRITE ) == OK:
		config_file.store_string( to_json( parameters ) )
		config_file.close()

#func _notification( what ):
#	if what == NOTIFICATION_PREDELETE: _save_parameters()