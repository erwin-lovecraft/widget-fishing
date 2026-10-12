extends Control
## Composition root: window setup, input, and wiring signals between the
## fisher, the player's progress and the UI. Game rules live elsewhere.

const CollectionPanelScene := preload("res://src/ui/collection_panel.tscn")

@onready var _pond: Panel = %Pond
@onready var _fisher: Fisher = %Fisher
@onready var _events: EventManager = %EventManager
@onready var _hud: Hud = %Hud
@onready var _effects: Effects = %Effects
@onready var _menu: ContextMenu = %ContextMenu
@onready var _reset_dialog: ConfirmationDialog = %ResetDialog
@onready var _autosave: Timer = %AutosaveTimer

var _collection: CollectionPanel


func _ready() -> void:
	_setup_window()
	_pond.visible = PlayerState.show_pond

	_fisher.status_changed.connect(_hud.set_status)
	_fisher.bite_started.connect(_on_bite_started)
	_fisher.item_caught.connect(_on_item_caught)
	_fisher.treasure_found.connect(_on_treasure_found)
	_fisher.escaped.connect(_on_escaped)

	_events.changed.connect(_hud.show_event)
	_events.ended.connect(_hud.hide_event)

	_menu.sell_requested.connect(_sell_basket)
	_menu.collection_requested.connect(_toggle_collection)
	_menu.pond_toggled.connect(_toggle_pond)
	_menu.always_on_top_toggled.connect(_toggle_always_on_top)
	_menu.reset_requested.connect(_reset_dialog.popup_centered)
	_menu.quit_requested.connect(_quit)
	_menu.language_selected.connect(Localization.set_language)

	_reset_dialog.confirmed.connect(PlayerState.reset)
	Localization.language_changed.connect(_refresh_texts)
	_refresh_texts()

	_autosave.wait_time = Config.game.autosave_seconds
	_autosave.timeout.connect(_save)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()


func _setup_window() -> void:
	get_window().transparent = true
	get_viewport().transparent_bg = true
	_apply_always_on_top()
	# Wayland compositors do not let apps place their own window.
	if DisplayServer.get_name() != "Wayland" and PlayerState.window_pos.x >= 0:
		DisplayServer.window_set_position(PlayerState.window_pos)


func _apply_always_on_top() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, PlayerState.always_on_top)


func _refresh_texts() -> void:
	_reset_dialog.dialog_text = tr("ui.reset_confirm")


func _save() -> void:
	PlayerState.window_pos = DisplayServer.window_get_position()
	PlayerState.save()


func _quit() -> void:
	_save()
	get_tree().quit()


# ------------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if _hud.basket_hit_rect().has_point(event.position):
				_toggle_collection()
			else:
				DisplayServer.window_start_drag()
		MOUSE_BUTTON_RIGHT:
			_menu.open_at(Vector2i(event.position))


func _toggle_pond() -> void:
	PlayerState.show_pond = not PlayerState.show_pond
	_pond.visible = PlayerState.show_pond


func _toggle_always_on_top() -> void:
	PlayerState.always_on_top = not PlayerState.always_on_top
	_apply_always_on_top()


func _toggle_collection() -> void:
	if is_instance_valid(_collection):
		_collection.queue_free()
		return
	_collection = CollectionPanelScene.instantiate()
	_collection.sell_requested.connect(_sell_basket)
	add_child(_collection)


# ------------------------------------------------------------ fishing results

func _on_bite_started(pos: Vector2) -> void:
	_effects.float_text("!", Color("ffe14d"), pos + Vector2(-4, -34), 26)


func _on_escaped(from: Vector2) -> void:
	_effects.float_text(tr("status.escaped"), Color("b8b8b8"), from + Vector2(-14, -22), 13)


func _on_item_caught(item: ItemData, size: float, value: int, from: Vector2) -> void:
	var catalog := Config.catalog
	await _effects.fly_to(catalog.item_icon(item), from, _hud.basket_center())
	PlayerState.add_to_basket(item.id, value)
	_hud.pulse_basket()

	var color := catalog.rarity_color(item.rarity)
	var args := {
		"name": item.display_name(),
		"rarity": item.rarity_name(),
		"size": "%.2f" % size,
		"value": value,
	}
	var text := tr("ui.catch_junk").format(args)
	if not item.is_junk:
		text = item.display_name() + "\n" + tr("ui.catch_fish_detail").format(args)
	_effects.float_text(text, color, _hud.basket_center() + Vector2(-110, 40), 13)
	if catalog.is_celebrated(item.rarity):
		_effects.burst(_hud.basket_center(), color, 40)
	if PlayerState.is_basket_full():
		await get_tree().create_timer(0.6).timeout
		_sell_basket(true)


func _on_treasure_found(coins: int, from: Vector2) -> void:
	var chest: Vector2i = Config.catalog.chest_cells.pick_random()
	await _effects.pop(Config.catalog.icon(chest), from)
	PlayerState.add_coins(coins)
	_effects.burst(from + Vector2(0, -40), Color("ffd23f"), 50)
	_effects.float_text(tr("ui.treasure").format({"coins": coins}), Color("ffd23f"), from + Vector2(-34, -60), 15)


func _sell_basket(auto := false) -> void:
	var earned := PlayerState.sell_basket()
	if earned <= 0:
		return
	var key := "ui.basket_full" if auto else "ui.sold"
	_effects.burst(_hud.coin_anchor(), Color("ffd23f"), 24)
	_effects.float_text(tr(key).format({"amount": earned}), Color("ffd23f"), Vector2(30, 36), 14)
