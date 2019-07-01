extends Node

enum State { DISABLED, ENABLED, OFFSET, CALIBRATION, OPERATION }

const INTERFACE_TYPES = [ "joystick", "lanip", "bluetooth" ]

onready var input_device_class = preload( "res://Scripts/input_device.gd" )
onready var input_axis_class = preload( "res://Scripts/input_axis.gd" )

var interfaces_list = [] setget ,_get_interfaces_list
var input_devices_list = {}

func _ready():
	for type_id in INTERFACE_TYPES:
		var plugin = load( "res://Scripts/input_" + type_id + ".gd" )
		if plugin != null:
			interfaces_list.append( type_id ) 
			var interface = plugin.new()
			input_devices_list[ type_id ] = input_device_class.new( interface )

func _get_interfaces_list():
	print( interfaces_list )
	return interfaces_list

func get_interface_device( type_id ):
	return input_devices_list.get( type_id )

func get_device_axis( device, axis_index ):
	return input_axis_class.new( device, axis_index )