class_name Hud
extends Control
## Coins, basket counter, status line and event banner. Display only.

@onready var _coin_label: Label = %CoinLabel
@onready var _basket_icon: Sprite2D = %BasketIcon
@onready var _basket_label: Label = %BasketLabel
@onready var _status_label: Label = %StatusLabel
@onready var _banner_label: Label = %BannerLabel

var _status_key := ""
var _status_args := {}
var _event: EventData
var _event_seconds := 0
var _basket_scale := Vector2.ONE


func _ready() -> void:
	_basket_scale = _basket_icon.scale
	_basket_icon.texture = Config.catalog.icon(Config.catalog.basket_cell)
	PlayerState.coins_changed.connect(_refresh_counters)
	PlayerState.basket_changed.connect(_refresh_counters)
	_refresh_counters()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_status()
		_refresh_banner()


## Center of the basket icon in window coordinates.
func basket_center() -> Vector2:
	return _basket_icon.position


func basket_hit_rect() -> Rect2:
	return Rect2(_basket_icon.position - Vector2(24, 24), Vector2(48, 60))


func coin_anchor() -> Vector2:
	return _coin_label.position + Vector2(20, 12)


func pulse_basket() -> void:
	var tween := create_tween()
	tween.tween_property(_basket_icon, "scale", _basket_scale * 1.28, 0.08)
	tween.tween_property(_basket_icon, "scale", _basket_scale, 0.15)


func set_status(key: String, args := {}) -> void:
	_status_key = key
	_status_args = args
	_refresh_status()


func show_event(event: EventData, seconds_left: int) -> void:
	_event = event
	_event_seconds = seconds_left
	_refresh_banner()


func hide_event() -> void:
	_event = null
	_banner_label.visible = false


func _refresh_counters() -> void:
	_coin_label.text = str(PlayerState.coins)
	_basket_label.text = "%d/%d" % [PlayerState.basket_count(), PlayerState.basket_capacity()]
	_basket_label.add_theme_color_override(
		"font_color", Color("ff8a8a") if PlayerState.is_basket_full() else Color.WHITE)


func _refresh_status() -> void:
	_status_label.text = tr(_status_key).format(_status_args) if not _status_key.is_empty() else ""


func _refresh_banner() -> void:
	if _event == null:
		return
	_banner_label.text = tr("ui.event_banner").format(
		{"text": _event.display_text(), "seconds": _event_seconds})
	_banner_label.add_theme_color_override("font_color", _event.color)
	_banner_label.visible = true
