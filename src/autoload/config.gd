extends Node
## Autoload "Config": loads the data files in res://config once at startup.
## Edit config/*.json (settings) and config/*.csv (fish tables) to tune the game.

const GAME_PATH := "res://config/game.json"
const EVENTS_PATH := "res://config/events.json"

## Used for any key missing from game.json.
const GAME_DEFAULTS := {
	"basket_capacity": 25,
	"autosave_seconds": 15.0,
	"ui": {"pixel_scale": 3},
	"outcomes": {"fish": 78.0, "junk": 8.0, "treasure": 2.0, "escape": 12.0},
	"timing": {
		"cast_windup": 0.3,
		"cast_throw": 0.15,
		"cast_flight": 0.55,
		"bite_wait": [4.0, 12.0],
		"nibble_gap": [1.0, 2.5],
		"nibble_chance": 0.45,
		"reel": 0.7,
		"catch_display": 1.05,
		"treasure_display": 1.4,
		"pause_between_casts": [1.0, 2.5],
	},
	"size": {"base": [0.7, 1.2], "bonus_max": 0.8, "bonus_power": 4.0},
	"treasure": {"coins": [80, 300]},
}
const SCHEDULE_DEFAULTS := {"first_delay": [25, 70], "interval": [30, 90]}

var game: Dictionary = {}
var catalog: Catalog
var events: Array[EventData] = []
var event_schedule: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	var loaded: Variant = DataFiles.read_json(GAME_PATH)
	game = _merge(GAME_DEFAULTS, loaded if loaded is Dictionary else {})
	catalog = Catalog.load_from()
	_load_events()


func _load_events() -> void:
	events.clear()
	var data: Variant = DataFiles.read_json(EVENTS_PATH)
	if not data is Dictionary:
		data = {}
	event_schedule = _merge(SCHEDULE_DEFAULTS, data.get("schedule", {}))
	var defs: Dictionary = data.get("events", {})
	for id in defs:
		events.append(EventData.from_dict(id, defs[id]))


## Random float inside a [min, max] config range.
func roll_range(range_value: Array) -> float:
	return randf_range(float(range_value[0]), float(range_value[1]))


static func _merge(base: Dictionary, override: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for k in override:
		if out.get(k) is Dictionary and override[k] is Dictionary:
			out[k] = _merge(out[k], override[k])
		else:
			out[k] = override[k]
	return out
