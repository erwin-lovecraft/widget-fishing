class_name Catalog
extends RefCounted
## Fish, junk and rarity tiers loaded from config/*.csv and config/catalog.json.

var sheet: Texture2D
var cell_size := 16
var basket_cell := Vector2i.ZERO
var chest_cells: Array[Vector2i] = []
var rarities: Dictionary = {}          # id -> {color: Color, luck_rank: int, celebrate: bool}
var fish: Array[ItemData] = []
var junk: Array[ItemData] = []

var _by_id: Dictionary = {}
var _icons: Dictionary = {}


## Loads catalog.json (sprite sheet info) + rarities/fish/junk CSV tables from `dir`.
static func load_from(dir := "res://config/") -> Catalog:
	var meta: Variant = DataFiles.read_json(dir + "catalog.json")
	return build(
		meta if meta is Dictionary else {},
		DataFiles.read_csv(dir + "rarities.csv"),
		DataFiles.read_csv(dir + "fish.csv"),
		DataFiles.read_csv(dir + "junk.csv"))


static func build(meta: Dictionary, rarity_rows: Array, fish_rows: Array, junk_rows: Array) -> Catalog:
	var c := Catalog.new()
	c.cell_size = int(meta.get("cell_size", 16))
	var sheet_path := str(meta.get("sheet", ""))
	if ResourceLoader.exists(sheet_path):
		c.sheet = load(sheet_path)
	else:
		push_error("Catalog: sprite sheet not found: %s" % sheet_path)
	c.basket_cell = _cell(meta.get("basket_icon", [0, 0]))
	for chest in meta.get("chest_icons", []):
		c.chest_cells.append(_cell(chest))

	for r in rarity_rows:
		c.rarities[r.id] = {
			"color": Color.html(r.get("color", "#ffffff")),
			"luck_rank": int(r.get("luck_rank", "0")),
			"celebrate": r.get("celebrate", "false").to_lower() == "true",
		}
	for r in fish_rows:
		var item := c._make_item(r, false)
		if item.weight <= 0.0:
			push_warning("Catalog: fish '%s' has weight <= 0 and will never spawn" % item.id)
		c.fish.append(item)
	for r in junk_rows:
		c.junk.append(c._make_item(r, true))
	return c


func _make_item(row: Dictionary, as_junk: bool) -> ItemData:
	var item := ItemData.new()
	item.id = row.get("id", "")
	item.is_junk = as_junk
	item.rarity = "junk" if as_junk else row.get("rarity", "")
	item.cell = Vector2i(int(row.get("icon_col", "0")), int(row.get("icon_row", "0")))
	item.weight = float(row.get("weight", "0"))
	item.value = int(row.get("value", "1"))
	if not rarities.has(item.rarity):
		push_warning("Catalog: '%s' uses unknown rarity '%s'" % [item.id, item.rarity])
	if _by_id.has(item.id):
		push_warning("Catalog: duplicate item id '%s'" % item.id)
	_by_id[item.id] = item
	return item


static func _cell(v: Variant) -> Vector2i:
	if v is Array and v.size() >= 2:
		return Vector2i(int(v[0]), int(v[1]))
	return Vector2i.ZERO


func get_item(id: String) -> ItemData:
	return _by_id.get(id)


func icon(cell: Vector2i) -> AtlasTexture:
	if not _icons.has(cell):
		var t := AtlasTexture.new()
		t.atlas = sheet
		t.region = Rect2(cell.x * cell_size, cell.y * cell_size, cell_size, cell_size)
		_icons[cell] = t
	return _icons[cell]


func item_icon(item: ItemData) -> AtlasTexture:
	return icon(item.cell)


func rarity_color(rarity: String) -> Color:
	return rarities.get(rarity, {}).get("color", Color.WHITE)


func luck_rank(rarity: String) -> int:
	return rarities.get(rarity, {}).get("luck_rank", 0)


func is_celebrated(rarity: String) -> bool:
	return rarities.get(rarity, {}).get("celebrate", false)


## weight * (1 + luck * luck_rank): luck makes rarer tiers more likely.
func effective_weight(item: ItemData, luck := 0.0) -> float:
	return item.weight * (1.0 + luck * luck_rank(item.rarity))


## Spawn chance of a fish in percent among all fish catches.
func chance_percent(item: ItemData, luck := 0.0) -> float:
	var total := 0.0
	for f in fish:
		total += effective_weight(f, luck)
	return effective_weight(item, luck) / total * 100.0 if total > 0.0 else 0.0
