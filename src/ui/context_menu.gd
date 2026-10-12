class_name ContextMenu
extends PopupMenu
## Right-click menu. Rebuilt on every open so text, counts and check marks are current.

signal sell_requested
signal collection_requested
signal pond_toggled
signal always_on_top_toggled
signal reset_requested
signal quit_requested
signal language_selected(code: String)

enum Id { SELL, COLLECTION, POND, ALWAYS_ON_TOP, RESET, QUIT }

var _languages := PopupMenu.new()


func _ready() -> void:
	_languages.name = "Languages"
	_languages.index_pressed.connect(_on_language_pressed)
	add_child(_languages)
	id_pressed.connect(_on_id_pressed)


func open_at(pos: Vector2i) -> void:
	_rebuild()
	position = pos
	popup()


func _rebuild() -> void:
	clear()
	add_item(tr("menu.sell").format({"value": PlayerState.basket_value}), Id.SELL)
	add_item(tr("menu.collection"), Id.COLLECTION)
	add_separator()
	add_check_item(tr("menu.show_pond"), Id.POND)
	set_item_checked(get_item_index(Id.POND), PlayerState.show_pond)
	add_check_item(tr("menu.always_on_top"), Id.ALWAYS_ON_TOP)
	set_item_checked(get_item_index(Id.ALWAYS_ON_TOP), PlayerState.always_on_top)

	_languages.clear()
	for code in Localization.available:
		_languages.add_radio_check_item(Localization.available[code])
		var idx := _languages.item_count - 1
		_languages.set_item_metadata(idx, code)
		_languages.set_item_checked(idx, code == Localization.current_language())
	add_submenu_node_item(tr("menu.language"), _languages)

	add_separator()
	add_item(tr("menu.reset"), Id.RESET)
	add_item(tr("menu.quit"), Id.QUIT)


func _on_id_pressed(id: int) -> void:
	match id:
		Id.SELL:
			sell_requested.emit()
		Id.COLLECTION:
			collection_requested.emit()
		Id.POND:
			pond_toggled.emit()
		Id.ALWAYS_ON_TOP:
			always_on_top_toggled.emit()
		Id.RESET:
			reset_requested.emit()
		Id.QUIT:
			quit_requested.emit()


func _on_language_pressed(index: int) -> void:
	language_selected.emit(_languages.get_item_metadata(index))
