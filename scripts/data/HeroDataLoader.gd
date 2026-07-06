extends RefCounted
class_name HeroDataLoader

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")


static func all_heroes(include_summons: bool = false) -> Array:
	_ensure_loaded()
	var heroes: Array = []
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if not include_summons and (str(hero.get("rarity", "")) == "summon" or bool(hero.get("is_summon", false))):
			continue
		heroes.append(_normalized_hero(hero))
	return heroes


static func all_hero_ids(include_summons: bool = false) -> Array:
	var ids: Array = []
	for hero: Dictionary in all_heroes(include_summons):
		var hero_id := str(hero.get("id", ""))
		if not hero_id.is_empty():
			ids.append(hero_id)
	return ids


static func hero_by_id(hero_id: String) -> Dictionary:
	_ensure_loaded()
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if str(hero.get("id", "")) == hero_id:
			return _normalized_hero(hero)
	return {}


static func missing_resource_report(include_summons: bool = false) -> Array:
	var missing: Array = []
	for hero: Dictionary in all_heroes(include_summons):
		var hero_id := str(hero.get("id", ""))
		for key in ["hero_master", "portrait", "battle_idle", "battle_attack", "battle_skill"]:
			var path := str(hero.get(key, ""))
			if path.is_empty() or not FileAccess.file_exists(path):
				missing.append({
					"hero_id": hero_id,
					"key": key,
					"path": path,
				})
	return missing


static func _ensure_loaded() -> void:
	if DataLoaderScript.data.is_empty():
		DataLoaderScript.load_all()


static func _normalized_hero(hero: Dictionary) -> Dictionary:
	var normalized := hero.duplicate(true)
	if not normalized.has("profession"):
		normalized["profession"] = str(normalized.get("class", ""))
	if not normalized.has("class"):
		normalized["class"] = str(normalized.get("profession", ""))
	if not normalized.has("hp"):
		normalized["hp"] = int(normalized.get("max_hp", 1))
	if not normalized.has("max_hp"):
		normalized["max_hp"] = int(normalized.get("hp", 1))
	if not normalized.has("hero_master"):
		normalized["hero_master"] = str(normalized.get("portrait", ""))
	if not normalized.has("portrait"):
		normalized["portrait"] = str(normalized.get("hero_master", ""))
	return normalized
