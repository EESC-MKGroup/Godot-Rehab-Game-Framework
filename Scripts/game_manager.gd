extends Node

const GAMES_PATH = "res://Scenes/Games"
const GAME_EXT = ".tscn"

var game_instace = null

var player_controls = {}

func list_files( dir_path, file_ext ):
	var files_list = []
	var files_dir = Directory.new()
	files_dir.open( dir_path )
	files_dir.list_dir_begin()
	while true:
		var file = files_dir.get_next()
		if file == "": break
		elif file.ends_with( file_ext ):
			files_list.append( file.get_basename() )
	files_dir.list_dir_end()
	return files_list

func list_games():
	return list_files( GAMES_PATH, GAME_EXT )

func _get_game_path( game_name ):
	return GAMES_PATH + "/" + game_name + GAME_EXT

func load_game( game_name ):
	get_tree().change_scene( _get_game_path( game_name ) )

func list_game_variables( game_name ):
	if game_instace != null: game_instace.free()
	game_instace = load( _get_game_path( game_name ) ).instance()
	print( game_instace.get_player_variables() )
	return game_instace.get_player_variables()

func get_player_control( variable_name ):
	var player_control = player_controls.get( variable_name )
	if player_control == null: player_control = InputManager.get_null_axis()
	return player_control
