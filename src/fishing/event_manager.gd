class_name EventManager
extends Node
## Schedules random events from Config.events and exposes the active modifiers.

signal changed(event: EventData, seconds_left: int)
signal ended

var active: EventData
var time_left := 0.0

var bite_time: float:
	get: return active.bite_time if active else 1.0
var luck: float:
	get: return active.luck if active else 0.0
var value: float:
	get: return active.value if active else 1.0
var junk: float:
	get: return active.junk if active else 1.0

var _next_in := 0.0
var _last_seconds := -1


func _ready() -> void:
	_next_in = Config.roll_range(Config.event_schedule.first_delay)


func _process(delta: float) -> void:
	if Config.events.is_empty():
		return
	if active:
		time_left -= delta
		if time_left <= 0.0:
			active = null
			_next_in = Config.roll_range(Config.event_schedule.interval)
			ended.emit()
			return
		var seconds := ceili(time_left)
		if seconds != _last_seconds:
			_last_seconds = seconds
			changed.emit(active, seconds)
	else:
		_next_in -= delta
		if _next_in <= 0.0:
			start(_pick())


func start(event: EventData) -> void:
	active = event
	time_left = event.duration
	_last_seconds = -1


func _pick() -> EventData:
	var total := 0.0
	for e in Config.events:
		total += e.weight
	var r := randf() * total
	for e in Config.events:
		r -= e.weight
		if r <= 0.0:
			return e
	return Config.events[0]
