class_name Effects
extends Control
## Floating text, flying sprites and particle bursts drawn above everything.


func float_text(text: String, color: Color, pos: Vector2, font_size := 14) -> void:
	var label := Label.new()
	label.theme_type_variation = &"OutlinedLabel"
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text = text
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", pos.y - 28.0, 1.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(1.4)
	tween.tween_callback(label.queue_free)


## Pops a sprite up out of the water, then carries it into the basket.
func fly_to(texture: Texture2D, from: Vector2, to: Vector2) -> void:
	var sprite := _spawn_sprite(texture, from)
	var tween := _rise(sprite, from)
	tween.tween_property(sprite, "position", to, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", sprite.scale * 0.45, 0.45)
	await tween.finished
	sprite.queue_free()


## Pops a sprite up, grows and fades it (used for treasure chests).
func pop(texture: Texture2D, from: Vector2) -> void:
	var sprite := _spawn_sprite(texture, from)
	var tween := _rise(sprite, from)
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	sprite.queue_free()


func burst(pos: Vector2, color: Color, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 130.0
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	add_child(p)
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


func _spawn_sprite(texture: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	var px := float(Config.game.ui.pixel_scale)
	s.scale = Vector2(px, px)
	s.position = pos
	add_child(s)
	return s


func _rise(sprite: Sprite2D, from: Vector2) -> Tween:
	var tween := create_tween()
	tween.tween_property(sprite, "position", from + Vector2(0, -42), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.25)
	return tween
