class_name LootTable
extends RefCounted
## Rolls what a bite turns into. Pure logic with its own RNG so it can be tested.

const OUTCOME_FISH := "fish"
const OUTCOME_JUNK := "junk"
const OUTCOME_TREASURE := "treasure"
const OUTCOME_ESCAPE := "escape"

var rng := RandomNumberGenerator.new()
var _catalog: Catalog
var _outcomes: Dictionary
var _size: Dictionary


func _init(catalog: Catalog, outcome_weights: Dictionary, size_config: Dictionary) -> void:
	_catalog = catalog
	_outcomes = outcome_weights
	_size = size_config
	rng.randomize()


func roll_outcome(junk_multiplier := 1.0) -> String:
	var weights := _outcomes.duplicate()
	weights[OUTCOME_JUNK] = weights.get(OUTCOME_JUNK, 0.0) * junk_multiplier
	var total := 0.0
	for k in weights:
		total += weights[k]
	var r := rng.randf() * total
	for k in weights:
		r -= weights[k]
		if r <= 0.0:
			return k
	return OUTCOME_FISH


func roll_fish(luck := 0.0) -> ItemData:
	var total := 0.0
	for f in _catalog.fish:
		total += _catalog.effective_weight(f, luck)
	var r := rng.randf() * total
	for f in _catalog.fish:
		r -= _catalog.effective_weight(f, luck)
		if r <= 0.0:
			return f
	return _catalog.fish[0]


func roll_junk() -> ItemData:
	return _catalog.junk[rng.randi() % _catalog.junk.size()]


func roll_size() -> float:
	var base: Array = _size.get("base", [0.7, 1.2])
	var bonus := pow(rng.randf(), float(_size.get("bonus_power", 4.0))) * float(_size.get("bonus_max", 0.8))
	return snappedf(rng.randf_range(base[0], base[1]) + bonus, 0.01)
