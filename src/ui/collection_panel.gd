class_name CollectionPanel
extends PanelContainer
## Basket summary plus a collection list: every fish with its spawn chance, value and count.

signal sell_requested

@onready var _title: Label = %Title
@onready var _sell_button: Button = %SellButton
@onready var _close_button: Button = %CloseButton
@onready var _list: VBoxContainer = %List


func _ready() -> void:
	_title.text = tr("ui.basket_title").format({
		"count": PlayerState.basket_count(),
		"capacity": PlayerState.basket_capacity(),
		"value": PlayerState.basket_value,
	})
	_sell_button.text = tr("ui.sell")
	_close_button.text = tr("ui.close")
	_sell_button.pressed.connect(func() -> void:
		sell_requested.emit()
		queue_free())
	_close_button.pressed.connect(queue_free)
	for item in Config.catalog.fish:
		_list.add_child(_make_row(item))


func _make_row(item: ItemData) -> HBoxContainer:
	var found: int = PlayerState.collection.get(item.id, 0)
	var row := HBoxContainer.new()

	var icon := TextureRect.new()
	icon.texture = Config.catalog.item_icon(item)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if found > 0 else Color(0, 0, 0, 0.75)
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = item.display_name() if found > 0 else tr("ui.unknown_item")
	name_label.add_theme_color_override("font_color", Config.catalog.rarity_color(item.rarity))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var info := Label.new()
	info.text = tr("ui.collection_row").format({
		"chance": "%.1f" % Config.catalog.chance_percent(item),
		"value": item.value,
		"count": found,
	})
	info.add_theme_font_size_override("font_size", 12)
	row.add_child(info)
	return row
