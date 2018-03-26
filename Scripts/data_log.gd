extends Node

var log_file = File.new()

func create_new_log( file_name ):
	if log_file.is_open(): log_file.close()
	log_file.open( "user://Logs/" + file_name + ".log", File.WRITE )

func register_values( values_list ):
	var string_buffer = ""
	for value in values_list:
		string_buffer += str(value) + " "
	log_file.store_line( string_buffer )

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		log_file.close()