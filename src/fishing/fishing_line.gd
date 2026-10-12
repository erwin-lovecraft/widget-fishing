class_name FishingLine
extends Control
## Draws the fishing line, bobber and water ripples. Driven by Fisher.

const LINE_COLOR := Color(1, 1, 1, 0.85)

var bobber := Vector2.ZERO
var bobber_visible := false:
	set(v):
		bobber_visible = v
		queue_redraw()
var dip := 0.0           # vertical offset used for nibbles and bites
var sag := 8.0           # how much the line droops
var waiting := false     # idle bobbing + ripples
var biting := false
var rod_tip_provider: Callable

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if bobber_visible:
		queue_redraw()


func _draw() -> void:
	if not bobber_visible or not rod_tip_provider.is_valid():
		return
	var b := bobber + Vector2(0, dip + (sin(_time * 2.6) * 1.5 if waiting else 0.0))
	var tip: Vector2 = rod_tip_provider.call()
	var points := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var p := tip.lerp(b, t)
		p.y += sin(t * PI) * sag
		points.append(p)
	draw_polyline(points, LINE_COLOR, 1.0, true)
	if waiting or biting:
		draw_set_transform(b + Vector2(0, 4), 0.0, Vector2(1.0, 0.35))
		for k in 2:
			var r := fmod(_time * 9.0 + k * 7.0, 14.0)
			draw_arc(Vector2.ZERO, 4.0 + r, 0.0, TAU, 24, Color(1, 1, 1, 0.6 * (1.0 - r / 14.0)), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(b, 5.0, Color.WHITE)
	draw_circle(b + Vector2(0, -2), 3.6, Color(0.92, 0.16, 0.16))
