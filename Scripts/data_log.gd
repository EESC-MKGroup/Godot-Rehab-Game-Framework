extends Node

var log_file = File.new()

const LOGS_PATH = "user://logs"

func create_new_log( log_name, time_stamp ):
	var log_directory = Directory.new()
	if not log_directory.dir_exists( LOGS_PATH ): log_directory.make_dir( LOGS_PATH )
	if log_file.is_open(): log_file.close()
	var date_time = OS.get_datetime_from_unix_time( time_stamp )
	var file_name = ( "%s-%d%02d%02d_%02d%02d" % [ log_name, 
	                                               date_time[ "year" ], date_time[ "month" ], date_time[ "day" ],
	                                               date_time[ "hour" ], date_time[ "minute" ] ] )
	log_file.open( LOGS_PATH + "/" + file_name + ".log", File.WRITE )

func register_values( values_list ):
	var string_buffer = ""
	for value in values_list:
		string_buffer += str(value) + " "
	log_file.store_line( string_buffer )

func _notification( what ):
	if what == NOTIFICATION_PREDELETE: 
		log_file.close()