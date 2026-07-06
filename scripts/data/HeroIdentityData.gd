extends RefCounted
class_name HeroIdentityData

const IDENTITY_PATH := "res://docs/HERO_IDENTITY_BIBLE.md"
const DEEPENING_PATH := "res://data/hero_identity_deepening.json"


static func identity_for(hero_id: String) -> Dictionary:
	var rows := _identity_rows()
	if rows.has(hero_id):
		return rows[hero_id]
	return {
		"positioning": "独特战斗定位待整理",
		"playstyle": "围绕当前技能与职业承担战斗职责。",
		"tags": "待补充",
	}


static func deepening_for(hero_id: String) -> Dictionary:
	var rows := deepening_rows()
	return rows.get(hero_id, {})


static func deepening_rows() -> Dictionary:
	var parsed := _load_deepening_data()
	var heroes: Dictionary = parsed.get("heroes", {})
	return heroes


static func allowed_deepening_tags() -> Array:
	var parsed := _load_deepening_data()
	return parsed.get("allowed_identity_tags", [])


static func _identity_rows() -> Dictionary:
	var result := {}
	var text := FileAccess.get_file_as_string(IDENTITY_PATH)
	if text.is_empty():
		return result
	for raw_line in text.split("\n"):
		var line := String(raw_line).strip_edges()
		if not line.begins_with("| `"):
			continue
		var cells := line.split("|")
		if cells.size() < 8:
			continue
		var hero_id := String(cells[1]).replace("`", "").strip_edges()
		if hero_id.is_empty() or hero_id == "id":
			continue
		result[hero_id] = {
			"positioning": String(cells[5]).strip_edges(),
			"playstyle": String(cells[6]).strip_edges(),
			"tags": String(cells[7]).strip_edges(),
		}
	return result


static func _load_deepening_data() -> Dictionary:
	var text := FileAccess.get_file_as_string(DEEPENING_PATH)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
