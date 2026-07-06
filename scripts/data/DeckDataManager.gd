extends RefCounted
class_name DeckDataManager

const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")

const SAVE_PATH := "user://deck_builder.json"
const MAX_BATTLE_DECK_SIZE := 20
const MIN_BATTLE_DECK_SIZE := 5


static func default_player_deck() -> Array:
	var ids: Array = StarTrackSystemScript.unlocked_hero_ids()
	return ids.slice(0, mini(MAX_BATTLE_DECK_SIZE, ids.size()))


static func default_enemy_deck() -> Array:
	var ids: Array = HeroDataLoaderScript.all_hero_ids(false)
	ids.reverse()
	return ids.slice(0, mini(MAX_BATTLE_DECK_SIZE, ids.size()))


static func load_player_deck() -> Array:
	var data := load_data()
	return validate_deck(data.get("player_deck", []), default_player_deck())


static func save_player_deck(hero_ids: Array) -> bool:
	var clean := validate_deck(hero_ids, default_player_deck())
	var data := load_data()
	data["player_deck"] = clean
	data["updated_at"] = Time.get_datetime_string_from_system()
	return _write_data(data)


static func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _default_data()
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return _default_data()
	var data = json.get_data()
	if not (data is Dictionary):
		return _default_data()
	return data


static func validate_deck(hero_ids: Array, fallback: Array = []) -> Array:
	var result: Array = []
	var seen := {}
	for value in hero_ids:
		var hero_id := str(value)
		if seen.has(hero_id):
			continue
		if HeroDataLoaderScript.hero_by_id(hero_id).is_empty():
			continue
		if not StarTrackSystemScript.is_hero_unlocked(hero_id):
			continue
		seen[hero_id] = true
		result.append(hero_id)
		if result.size() >= MAX_BATTLE_DECK_SIZE:
			break
	if result.size() >= MIN_BATTLE_DECK_SIZE:
		return result
	if fallback.is_empty():
		return default_player_deck()
	return validate_deck(fallback, [])


static func _default_data() -> Dictionary:
	return {
		"version": 1,
		"player_deck": default_player_deck(),
	}


static func _write_data(data: Dictionary) -> bool:
	data["version"] = 1
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t", false))
	file.close()
	return true
