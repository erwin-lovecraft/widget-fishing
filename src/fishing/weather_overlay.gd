class_name WeatherOverlay
extends Control
## Draws rain while the active event asks for it.

@export var events: EventManager

var _time := 0.0
var _was_raining := false


func _process(delta: float) -> void:
	_time += delta
	var raining := events != null and events.active != null and events.active.rain
	if raining or _was_raining:
		queue_redraw()
	_was_raining = raining


func _draw() -> void:
	if events == null or events.active == null or not events.active.rain:
		return
	for i in 45:
		var x := fmod(i * 37.0 + _time * 25.0, size.x)
		var y := fmod(i * 53.0 + _time * 280.0, size.y)
		draw_line(Vector2(x, y), Vector2(x - 3, y + 9), Color(0.75, 0.88, 1.0, 0.55), 1.0)
