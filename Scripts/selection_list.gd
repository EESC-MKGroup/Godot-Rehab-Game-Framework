extends MenuButton

signal entry_selected( index, entry_name )

var entries_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().add_font_override( "font", get_font( "font" ) )
	get_popup().connect( "index_pressed", self, "_on_index_pressed" )

func _refresh_list():
	get_popup().clear()
	print( entries_list )
	for entry_name in entries_list:
		get_popup().add_item( entry_name )
	#_on_index_pressed( 0 )

func list_entries( entries ):
	entries_list = entries
	_refresh_list()

func select_entry_index( index ):
	_on_index_pressed( index )

func select_entry_name( entry_name ):
	var index = entries_list.find( entry_name )
	_on_index_pressed( index if index != -1 else 0 )

func _on_index_pressed( index ):
	var entry_name = get_popup().get_item_text( index )
	text = entry_name
	emit_signal( "entry_selected", index, entry_name )
