extends Node

const GAMES_PATH = "res://Scenes/Games"
const GAME_EXT = ".tscn"

func list_games():
	var games_list = []
	var games_dir = Directory.new()
	games_dir.open( GAMES_PATH )
	games_dir.list_dir_begin()
	while true:
		var file = games_dir.get_next()
		if file == "": break
		elif file.ends_with( GAME_EXT ):
			games_list.append( file.get_basename() )
	games_dir.list_dir_end()
	return games_list

func select( game_name ):
	get_tree().change_scene( GAMES_PATH + "/" + game_name + GAME_EXT )