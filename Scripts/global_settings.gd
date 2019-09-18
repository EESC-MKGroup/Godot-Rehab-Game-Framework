extends Node

const CONFIG_FILE_PATH = "user://settings.cfg"
var config_file = ConfigFile.new()

func _ready():
	config_file.load( CONFIG_FILE_PATH )

func set_value( section, key, value ):
	config_file.set_value( section, key, value )

func get_value( section, key, default=null ):
	return config_file.get_value( section, key, default )

func _notification( what ):
	if what == NOTIFICATION_PREDELETE:
		config_file.save( CONFIG_FILE_PATH )