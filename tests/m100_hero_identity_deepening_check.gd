extends SceneTree

const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const HeroIdentityDataScript: GDScript = preload("res://scripts/data/HeroIdentityData.gd")

const EXPECTED_PLAYABLE_HERO_COUNT := 55
const REQUIRED_LOW_PRESENCE := ["zhaoyun", "zhangfei", "machao", "huaxiong", "xusheng"]
const REQUIRED_FIELDS := ["tag", "rhythm", "risk", "role", "presence", "perception", "tuning_suggestion"]


func _init() -> void:
	var failures: Array[String] = []
	_check_deepening_config(failures)
	_check_deepening_doc(failures)
	_finish(failures)


func _check_deepening_config(failures: Array[String]) -> void:
	var rows: Dictionary = HeroIdentityDataScript.deepening_rows()
	var allowed: Array = HeroIdentityDataScript.allowed_deepening_tags()
	var playable_ids := _playable_hero_ids()
	_expect(playable_ids.size() == EXPECTED_PLAYABLE_HERO_COUNT, "playable hero count remains 55", failures)
	_expect(rows.size() == EXPECTED_PLAYABLE_HERO_COUNT, "deepening config covers exactly 55 heroes", failures)
	_expect(not rows.has("yellow_turban"), "deepening config excludes yellow_turban summon", failures)
	for hero_id in playable_ids:
		_expect(rows.has(hero_id), "deepening config covers hero %s" % hero_id, failures)
		var row: Dictionary = rows.get(hero_id, {})
		for field in REQUIRED_FIELDS:
			_expect(str(row.get(field, "")).strip_edges().length() > 0, "hero %s has %s" % [hero_id, field], failures)
		_expect(allowed.has(str(row.get("tag", ""))), "hero %s uses allowed hidden tag" % hero_id, failures)
	for hero_id in REQUIRED_LOW_PRESENCE:
		var row: Dictionary = rows.get(hero_id, {})
		_expect(str(row.get("presence", "")) == "low_watch", "hero %s remains on low presence watchlist" % hero_id, failures)
		_expect(str(row.get("tuning_suggestion", "")).contains("强化"), "hero %s has perceptibility-first suggestion" % hero_id, failures)
	_check_tag_distribution(rows, failures)


func _check_tag_distribution(rows: Dictionary, failures: Array[String]) -> void:
	var counts := {}
	for hero_id in rows.keys():
		var tag := str(rows.get(hero_id, {}).get("tag", ""))
		counts[tag] = int(counts.get(tag, 0)) + 1
	for tag in HeroIdentityDataScript.allowed_deepening_tags():
		_expect(int(counts.get(str(tag), 0)) > 0, "hidden tag %s is represented" % str(tag), failures)


func _check_deepening_doc(failures: Array[String]) -> void:
	var doc := FileAccess.get_file_as_string("res://docs/HERO_IDENTITY_DEEPENING_V1.md")
	_expect(doc.contains("Hero Identity Deepening Sprint v1"), "deepening doc records sprint name", failures)
	_expect(doc.contains("Reclassification Table"), "deepening doc has reclassification table", failures)
	_expect(doc.contains("Low Presence Watchlist"), "deepening doc has low presence watchlist", failures)
	_expect(doc.contains("Suggested Micro-Tuning Only"), "deepening doc limits future tuning scope", failures)
	for hero_id in _playable_hero_ids():
		_expect(doc.contains("| `%s` |" % hero_id), "deepening doc covers hero %s" % hero_id, failures)


func _playable_hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for hero: Dictionary in HeroDataLoaderScript.all_heroes(false):
		var hero_id := str(hero.get("id", ""))
		if bool(hero.get("is_summon", false)) or hero_id == "yellow_turban":
			continue
		ids.append(hero_id)
	return ids


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("M100 hero identity deepening checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
