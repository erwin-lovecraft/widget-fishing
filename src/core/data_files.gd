class_name DataFiles
extends RefCounted
## Loaders for the game's data files: JSON for nested config, CSV for tables.


## Reads a .json file through Godot's JSON resource (works in exported builds).
static func read_json(path: String) -> Variant:
	var res := load(path) as JSON
	if res == null:
		push_error("DataFiles: cannot load JSON %s" % path)
		return null
	return res.data


## Reads a .csv table. The first row is the header; every other row becomes a
## Dictionary of header -> string. Blank rows and rows starting with # are skipped.
static func read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataFiles: cannot open CSV %s" % path)
		return rows
	var header := file.get_csv_line()
	while not file.eof_reached():
		var cells := file.get_csv_line()
		if cells.size() == 0 or (cells.size() == 1 and cells[0].is_empty()) or cells[0].begins_with("#"):
			continue
		var row := {}
		for i in header.size():
			row[header[i].strip_edges()] = cells[i].strip_edges() if i < cells.size() else ""
		rows.append(row)
	return rows
