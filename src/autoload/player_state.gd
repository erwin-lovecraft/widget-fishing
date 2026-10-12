extends Node
## Autoload "PlayerState": progress, user settings and save/load.

signal coins_changed
signal basket_changed

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var coins := 0
var basket: Dictionary = {}       # item id -> count currently in the basket
var basket_value := 0             # total coin value of the basket
var collection: Dictionary = {}   # item id -> lifetime count
var total_catches := 0

# Settings
var language := ""                # empty = follow the system language
var show_pond := true
var always_on_top := true
var window_pos := Vector2i(-1, -1)


func _ready() -> void:
	load_save()


func basket_count() -> int:
	var n := 0
	for id in basket:
		n += basket[id]
	return n


func basket_capacity() -> int:
	return int(Config.game.basket_capacity)


func is_basket_full() -> bool:
	return basket_count() >= basket_capacity()


func add_to_basket(id: String, value: int) -> void:
	basket[id] = basket.get(id, 0) + 1
	basket_value += value
	collection[id] = collection.get(id, 0) + 1
	total_catches += 1
	basket_changed.emit()


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit()


## Empties the basket into coins; returns the amount earned.
func sell_basket() -> int:
	var earned := basket_value
	basket.clear()
	basket_value = 0
	coins += earned
	basket_changed.emit()
	coins_changed.emit()
	return earned


func reset() -> void:
	coins = 0
	basket.clear()
	basket_value = 0
	collection.clear()
	total_catches = 0
	save()
	basket_changed.emit()
	coins_changed.emit()


func save() -> void:
	var data := {
		"version": SAVE_VERSION,
		"coins": coins,
		"basket": basket,
		"basket_value": basket_value,
		"collection": collection,
		"total_catches": total_catches,
		"language": language,
		"show_pond": show_pond,
		"always_on_top": always_on_top,
		"window_pos": [window_pos.x, window_pos.y],
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return
	coins = int(parsed.get("coins", 0))
	basket_value = int(parsed.get("basket_value", 0))
	total_catches = int(parsed.get("total_catches", 0))
	language = str(parsed.get("language", ""))
	show_pond = bool(parsed.get("show_pond", true))
	always_on_top = bool(parsed.get("always_on_top", true))
	basket = _to_int_dict(parsed.get("basket", {}))
	collection = _to_int_dict(parsed.get("collection", {}))
	var wp: Array = parsed.get("window_pos", [-1, -1])
	window_pos = Vector2i(int(wp[0]), int(wp[1]))


func _to_int_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out
