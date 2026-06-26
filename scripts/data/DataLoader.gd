extends RefCounted
class_name DataLoader

const DATA_PATHS := {
	"master_levels": "res://data/master_levels.json",
	"heroes": "res://data/heroes.json",
	"skills": "res://data/skills.json",
	"terrains": "res://data/terrains.json",
	"strategy_cards": "res://data/strategy_cards.json",
}

static var data := {}


static func load_all() -> Dictionary:
	data.clear()
	for key in DATA_PATHS:
		data[key] = load_json(DATA_PATHS[key])
	return data


static func load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing data file: %s" % path)
		return []

	var parse_result: Variant = JSON.parse_string(file.get_as_text())
	if parse_result == null:
		push_error("Invalid JSON data file: %s" % path)
		return []

	return parse_result
