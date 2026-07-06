extends RefCounted
class_name SkillDataLoader

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")


static func all_skills() -> Array:
	_ensure_loaded()
	var skills: Array = []
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		skills.append(skill.duplicate(true))
	return skills


static func skill_by_id(skill_id: String) -> Dictionary:
	_ensure_loaded()
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			return skill.duplicate(true)
	return {}


static func supported_effect_types() -> Array[String]:
	return [
		"damage",
		"area_damage",
		"heal",
		"shield",
		"stun",
		"attack_buff",
		"slow",
		"modify_stat",
		"apply_status",
		"summon",
		"bonus_damage",
		"adjacent_guard",
		"side_move",
		"enemy_attack_delta",
		"adjacent_modify",
	]


static func _ensure_loaded() -> void:
	if DataLoaderScript.data.is_empty():
		DataLoaderScript.load_all()
