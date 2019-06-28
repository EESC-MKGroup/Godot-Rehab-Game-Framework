extends Node

const INTERFACE_TYPES = [ "joystick", "lanip", "bluetooth" ]

var interface = null
var interface_index = 0 setget _set_interface,_get_interface
var interfaces_list = {} setget ,_get_interfaces_list

func _ready():
	for type_id in INTERFACE_TYPES:
		var plugin = load( "res://Scripts/input_" + type_id + ".gd" )
		if plugin != null: interfaces_list[ type_id ] = plugin.new()
	set_process( false )

func _get_interfaces_list():
	print( interfaces_list.keys() )
	return interfaces_list.keys()

func _set_interface( index ):
	if index in range( interfaces_list.size() ):
		interface_index = index 
		interface = interfaces_list.values()[ index ]

func _get_interface():
	return interface_index