extends SceneTree
## Headless test runner (no addon needed):
##   godot --headless --path . -s tests/run_tests.gd
## Exits with code 1 if any check fails.

var _failed := 0
var _passed := 0


func _initialize() -> void:
	_test_data_files()
	_test_catalog()
	_test_loot_table()
	_test_locales()
	print("\n%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: ", label)


func _test_data_files() -> void:
	var game: Variant = DataFiles.read_json("res://config/game.json")
	_check(game is Dictionary and game.has("outcomes"), "game.json loads")
	var events: Variant = DataFiles.read_json("res://config/events.json")
	_check(events is Dictionary and events.events.has("storm"), "events.json loads")
	var rows := DataFiles.read_csv("res://config/fish.csv")
	_check(rows.size() > 0 and rows[0].has("weight"), "fish.csv loads with header keys")
	_check(rows[0].id == "grey_minnow" and rows[0].value == "4", "fish.csv row values")


func _test_catalog() -> void:
	var catalog := Catalog.load_from()
	_check(catalog.fish.size() > 0, "fish loaded")
	_check(catalog.junk.size() > 0, "junk loaded")
	_check(catalog.sheet != null, "sprite sheet loaded")
	var ids := {}
	for item in catalog.fish + catalog.junk:
		_check(not ids.has(item.id), "unique id " + item.id)
		ids[item.id] = true
		_check(catalog.rarities.has(item.rarity), "known rarity for " + item.id)
		_check(item.value > 0, "positive value for " + item.id)
	for f in catalog.fish:
		_check(f.weight > 0.0, "positive weight for " + f.id)
	var total := 0.0
	for f in catalog.fish:
		total += catalog.chance_percent(f)
	_check(is_equal_approx(total, 100.0), "chances sum to 100")
	# Rarer tiers must pay more than common ones.
	var best_common := 0
	var worst_legendary := 1 << 30
	for f in catalog.fish:
		if f.rarity == "common":
			best_common = maxi(best_common, f.value)
		if f.rarity == "legendary":
			worst_legendary = mini(worst_legendary, f.value)
	_check(worst_legendary > best_common, "legendary is worth more than common")


func _test_loot_table() -> void:
	var catalog := Catalog.load_from()
	var game: Dictionary = DataFiles.read_json("res://config/game.json")
	var loot := LootTable.new(catalog, game.outcomes, game.size)
	loot.rng.seed = 12345
	var runs := 40000
	var counts := {}
	for i in runs:
		var f := loot.roll_fish()
		counts[f.id] = counts.get(f.id, 0) + 1
	var grey := catalog.get_item("grey_minnow")
	var observed: float = counts.get("grey_minnow", 0) * 100.0 / runs
	_check(absf(observed - catalog.chance_percent(grey)) < 1.0, "common fish frequency matches config (%.2f%%)" % observed)
	_check(counts.get("golden_marlin", 0) < counts.get("grey_minnow", 0) / 10, "legendary far rarer than common")
	# Luck must shift weight toward rarer tiers.
	var shark := catalog.get_item("blue_shark")
	_check(catalog.chance_percent(shark, 3.0) > catalog.chance_percent(shark) * 3.0, "luck boosts legendary")
	var outcomes := {}
	for i in 20000:
		var o := loot.roll_outcome()
		outcomes[o] = outcomes.get(o, 0) + 1
	_check(outcomes.get("fish", 0) > outcomes.get("escape", 0), "fish outcome most common")
	_check(outcomes.has("treasure"), "treasure can happen")
	var size := loot.roll_size()
	_check(size >= 0.7 and size <= 2.0, "size within range")


func _test_locales() -> void:
	var catalog := Catalog.load_from()
	var events: Dictionary = DataFiles.read_json("res://config/events.json")
	var required: Array[String] = ["meta.name"]
	for item in catalog.fish + catalog.junk:
		required.append("item." + item.id)
	for r in catalog.rarities:
		required.append("rarity." + r)
	for id in events.events:
		required.append("event." + id)
	var rows := DataFiles.read_csv("res://locales/translations.csv")
	var by_key := {}
	for row in rows:
		by_key[row.keys] = row
	for key in required:
		_check(by_key.has(key), "translations.csv has key " + key)
	var langs: Array = rows[0].keys().filter(func(k): return k != "keys")
	_check("en" in langs, "English column exists")
	for row in rows:
		for lang in langs:
			_check(not row[lang].is_empty(), "%s has a '%s' translation" % [row.keys, lang])
	# Godot must have imported every language column.
	for lang in langs:
		_check(TranslationServer.get_loaded_locales().has(lang), "locale '%s' is registered in project settings" % lang)
