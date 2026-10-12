class_name Fisher
extends Sprite2D
## The angler. Runs the endless cast -> wait -> bite -> reel -> catch loop and
## reports results through signals; it never touches the UI or the save data.

signal status_changed(key: String, args: Dictionary)
signal bite_started(position: Vector2)
signal item_caught(item: ItemData, size: float, value: int, from: Vector2)
signal treasure_found(coins: int, from: Vector2)
signal escaped(from: Vector2)

enum Pose { THROW_BACK, THROW_FORWARD, IDLE, REEL }

const SHEET_ROW := 1
const FRAME_SIZE := 32
# Rod tip inside each 32x32 frame (unflipped sprite).
const ROD_TIP := {
	Pose.THROW_BACK: Vector2(29, 8),
	Pose.THROW_FORWARD: Vector2(1, 19),
	Pose.IDLE: Vector2(2, 14),
	Pose.REEL: Vector2(3.5, 12),
}

@export var line: FishingLine
@export var events: EventManager
@export var bobber_home := Vector2(220, 162)   ## where casts land (window pixels)

var _pose := Pose.IDLE
var _loot: LootTable
var _timing: Dictionary


func _ready() -> void:
	_timing = Config.game.timing
	_loot = LootTable.new(Config.catalog, Config.game.outcomes, Config.game.size)
	line.rod_tip_provider = rod_tip
	_set_pose(Pose.IDLE)
	_fish_loop()


func rod_tip() -> Vector2:
	var t: Vector2 = ROD_TIP[_pose]
	return position + Vector2(FRAME_SIZE - 1 - t.x, t.y) * scale # sprite is flipped


func _set_pose(pose: Pose) -> void:
	_pose = pose
	region_rect = Rect2(pose * FRAME_SIZE, SHEET_ROW * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


func _status(key: String, args := {}) -> void:
	status_changed.emit(key, args)


func _sleep(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _fish_loop() -> void:
	while true:
		await _cast()
		await _wait_for_bite()
		var outcome := _loot.roll_outcome(events.junk)
		await _bite()
		await _reel_in()
		await _resolve(outcome)
		await _sleep(Config.roll_range(_timing.pause_between_casts))


func _cast() -> void:
	_status("status.casting")
	_set_pose(Pose.THROW_BACK)
	await _sleep(_timing.cast_windup)
	_set_pose(Pose.THROW_FORWARD)
	await _sleep(_timing.cast_throw)
	var start := rod_tip()
	var target := bobber_home + Vector2(randf_range(-32, 32), randf_range(-12, 14))
	line.bobber_visible = true
	line.sag = 4.0
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		line.bobber = start.lerp(target, t) + Vector2(0, -sin(t * PI) * 55.0),
		0.0, 1.0, _timing.cast_flight)
	await tween.finished
	_set_pose(Pose.IDLE)
	line.sag = 10.0
	line.waiting = true


func _wait_for_bite() -> void:
	_status("status.waiting")
	var total := Config.roll_range(_timing.bite_wait) * events.bite_time
	var elapsed := 0.0
	while elapsed < total:
		var step := minf(Config.roll_range(_timing.nibble_gap), total - elapsed)
		await _sleep(step)
		elapsed += step
		if elapsed < total and randf() < _timing.nibble_chance:
			_nibble()


func _nibble() -> void:
	var tween := create_tween()
	tween.tween_property(line, "dip", 5.0, 0.1)
	tween.tween_property(line, "dip", 0.0, 0.2)


func _bite() -> void:
	line.waiting = false
	line.biting = true
	_status("status.bite")
	bite_started.emit(line.bobber)
	var tween := create_tween()
	for i in 4:
		tween.tween_property(line, "dip", 11.0, 0.07)
		tween.tween_property(line, "dip", 2.0, 0.07)
	await tween.finished
	line.biting = false


func _reel_in() -> void:
	_set_pose(Pose.REEL)
	_status("status.reeling")
	line.sag = 2.0
	var from := line.bobber
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		line.bobber = from.lerp(rod_tip(), t) + Vector2(0, -sin(t * PI) * 18.0),
		0.0, 1.0, _timing.reel)
	await tween.finished
	line.bobber_visible = false
	line.dip = 0.0


func _resolve(outcome: String) -> void:
	_set_pose(Pose.IDLE)
	var from := rod_tip() + Vector2(24, -8)
	match outcome:
		LootTable.OUTCOME_ESCAPE:
			_status("status.escaped")
			escaped.emit(from)
		LootTable.OUTCOME_JUNK:
			await _catch(_loot.roll_junk(), 1.0, from)
		LootTable.OUTCOME_TREASURE:
			_status("status.treasure")
			var coins := roundi(Config.roll_range(Config.game.treasure.coins) * events.value)
			treasure_found.emit(coins, from)
			await _sleep(_timing.treasure_display)
		_:
			await _catch(_loot.roll_fish(events.luck), _loot.roll_size(), from)


func _catch(item: ItemData, size: float, from: Vector2) -> void:
	var value := maxi(1, roundi(item.value * size * events.value))
	_status("status.caught", {"name": item.display_name()})
	item_caught.emit(item, size, value, from)
	await _sleep(_timing.catch_display)
