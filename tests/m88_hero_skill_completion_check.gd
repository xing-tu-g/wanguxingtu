extends SceneTree

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const SkillDataLoaderScript: GDScript = preload("res://scripts/data/SkillDataLoader.gd")
const AttackShapeSystemScript: GDScript = preload("res://scripts/battle/AttackShapeSystem.gd")
const SkillCompletionSimulatorScript: GDScript = preload("res://scripts/tools/SkillCompletionSimulator.gd")

const EXPECTED_PLAYABLE_HERO_COUNT := 55
const EXPECTED_SIMULATION_COUNT := 100
const SIMULATION_REPORT_PATH := "D:/wanguxingtu/tmp/skill_completion/simulation_100.json"

const ALLOWED_CLASSES := ["mage", "warrior", "tank", "assassin", "archer"]
const ALLOWED_SHAPES := [
	AttackShapeSystemScript.SHAPE_SAME_ROW_FORWARD,
	AttackShapeSystemScript.SHAPE_SAME_ROW_PLUS_ADJACENT_FORWARD,
	AttackShapeSystemScript.SHAPE_FRONT_1,
	AttackShapeSystemScript.SHAPE_FRONT_LINE,
	AttackShapeSystemScript.SHAPE_ROW_LINE,
	AttackShapeSystemScript.SHAPE_COLUMN_LINE,
	AttackShapeSystemScript.SHAPE_CROSS,
	AttackShapeSystemScript.SHAPE_RECTANGLE,
	AttackShapeSystemScript.SHAPE_FAN,
	AttackShapeSystemScript.SHAPE_SELF,
	AttackShapeSystemScript.SHAPE_ALL_ENEMIES,
	AttackShapeSystemScript.SHAPE_ALL_ALLIES,
	AttackShapeSystemScript.SHAPE_ALLY_NEAREST,
]
const FORBIDDEN_TEXT := ["%", "％", "百分比", "百分", "倍率", "双倍", "暴击率", "概率"]
const FORBIDDEN_KEYS := ["percent", "percentage", "pct", "multiplier", "chance", "crit_rate"]


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()

	var heroes: Array = _playable_heroes()
	var skills: Array = SkillDataLoaderScript.all_skills()
	var skills_by_id: Dictionary = _index_by_id(skills)
	var heroes_by_id: Dictionary = _index_by_id(heroes)

	_check_roster_skill_integrity(heroes, skills_by_id, failures)
	_check_skill_schema(heroes_by_id, skills, failures)
	_check_class_skill_directions(heroes, skills_by_id, failures)
	_check_no_hero_specific_skill_logic(failures)
	_check_simulation(failures)

	if failures.is_empty():
		print("M88 hero skill completion checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _playable_heroes() -> Array:
	var result: Array = []
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if bool(hero.get("is_summon", false)) or str(hero.get("id", "")) == "yellow_turban":
			continue
		result.append(hero)
	return result


func _index_by_id(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		result[str(row.get("id", ""))] = row
	return result


func _check_roster_skill_integrity(heroes: Array, skills_by_id: Dictionary, failures: Array[String]) -> void:
	_expect(heroes.size() == EXPECTED_PLAYABLE_HERO_COUNT, "playable hero count is 55", failures)
	for hero: Dictionary in heroes:
		var hero_id: String = str(hero.get("id", ""))
		var hero_class: String = str(hero.get("class", hero.get("profession", "")))
		_expect(hero_class in ALLOWED_CLASSES, "hero %s uses one of five classes" % hero_id, failures)
		var skill_ids: Array = hero.get("skill_ids", [])
		_expect(not skill_ids.is_empty(), "hero %s has at least one skill_id" % hero_id, failures)
		for skill_id_value in skill_ids:
			var skill_id: String = str(skill_id_value)
			_expect(skills_by_id.has(skill_id), "hero %s skill_id %s exists in skill config" % [hero_id, skill_id], failures)


func _check_skill_schema(heroes_by_id: Dictionary, skills: Array, failures: Array[String]) -> void:
	var supported_effects: Array[String] = SkillDataLoaderScript.supported_effect_types()
	for skill: Dictionary in skills:
		var skill_id: String = str(skill.get("id", ""))
		_expect(not skill_id.is_empty(), "skill has id", failures)
		_expect(heroes_by_id.has(str(skill.get("owner_hero_id", ""))) or str(skill.get("owner_hero_id", "")) == "yellow_turban", "skill %s owner exists" % skill_id, failures)
		_expect(str(skill.get("effect_type", "")) in supported_effects, "skill %s effect_type is supported" % skill_id, failures)
		_expect(str(skill.get("attack_shape", "")) in ALLOWED_SHAPES, "skill %s attack_shape is legal" % skill_id, failures)
		_expect(str(skill.get("description", "")).length() <= 60, "skill %s description stays short" % skill_id, failures)
		_expect(not _contains_forbidden_text(skill), "skill %s does not use percent/double/probability text" % skill_id, failures)
		_expect(not _contains_forbidden_key(skill), "skill %s does not use percentage-like fields" % skill_id, failures)


func _check_class_skill_directions(heroes: Array, skills_by_id: Dictionary, failures: Array[String]) -> void:
	var class_tags: Dictionary = {
		"tank": ["tank", "guard", "shield", "protect", "defense", "adjacent_guard"],
		"warrior": ["warrior", "growth", "bonus_damage", "attack"],
		"archer": ["archer", "burn", "poison", "pierce", "bonus_damage", "sustain"],
		"mage": ["mage", "damage", "area", "heal", "stun", "debuff", "burn", "summon", "attack_buff"],
		"assassin": ["assassin", "burst", "backstab", "execute", "bonus_damage"],
	}
	var seen: Dictionary = {
		"tank": false,
		"warrior": false,
		"archer": false,
		"mage": false,
		"assassin": false,
	}
	for hero: Dictionary in heroes:
		var hero_class: String = str(hero.get("class", hero.get("profession", "")))
		for skill_id_value in hero.get("skill_ids", []):
			var skill: Dictionary = skills_by_id.get(str(skill_id_value), {})
			if skill.is_empty():
				continue
			var haystack: String = _skill_direction_text(skill)
			for tag in class_tags.get(hero_class, []):
				if haystack.contains(str(tag)):
					seen[hero_class] = true
	for hero_class in seen.keys():
		_expect(bool(seen[hero_class]), "class %s has at least one matching MVP skill direction" % str(hero_class), failures)


func _check_no_hero_specific_skill_logic(failures: Array[String]) -> void:
	var paths: Array[String] = [
		"res://scripts/battle/SkillSystem.gd",
	]
	for path in paths:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		_expect(file != null, "can read %s" % path, failures)
		if file == null:
			continue
		var source: String = file.get_as_text()
		file.close()
		_expect(not source.contains("== \"") or not source.contains("hero_id"), "%s avoids direct hero_id equality branches" % path, failures)
		_expect(source.count("hero_id") <= 1, "%s has no large hero_id hardcoding" % path, failures)


func _check_simulation(failures: Array[String]) -> void:
	var report: Dictionary = SkillCompletionSimulatorScript.run(EXPECTED_SIMULATION_COUNT)
	var saved: bool = SkillCompletionSimulatorScript.save_report(report, SIMULATION_REPORT_PATH)
	_expect(saved, "100-game simulation report is written", failures)
	_expect(int(report.get("sample_count", 0)) == EXPECTED_SIMULATION_COUNT, "simulation runs 100 samples", failures)
	_expect(int(report.get("ended_count", 0)) == EXPECTED_SIMULATION_COUNT, "simulation finishes every sample", failures)
	_expect(int(report.get("timeouts", 0)) == 0, "simulation has no timeout/dead loop", failures)
	_expect(report.get("anomalies", []).is_empty(), "simulation reports no skill/deployment anomalies", failures)


func _contains_forbidden_text(value) -> bool:
	if value is Dictionary:
		for key in value.keys():
			if _contains_forbidden_text(str(key)) or _contains_forbidden_text(value[key]):
				return true
		return false
	if value is Array:
		for item in value:
			if _contains_forbidden_text(item):
				return true
		return false
	var text: String = str(value)
	for forbidden in FORBIDDEN_TEXT:
		if text.contains(str(forbidden)):
			return true
	return false


func _contains_forbidden_key(value) -> bool:
	if value is Dictionary:
		for key in value.keys():
			var key_text: String = str(key).to_lower()
			for forbidden in FORBIDDEN_KEYS:
				if key_text == str(forbidden) or key_text.ends_with("_%s" % str(forbidden)) or key_text.begins_with("%s_" % str(forbidden)):
					return true
			if _contains_forbidden_key(value[key]):
				return true
	if value is Array:
		for item in value:
			if _contains_forbidden_key(item):
				return true
	return false


func _skill_direction_text(skill: Dictionary) -> String:
	return "%s %s %s %s %s" % [
		str(skill.get("skill_type", "")).to_lower(),
		str(skill.get("effect_type", "")).to_lower(),
		str(skill.get("target", "")).to_lower(),
		str(skill.get("tags", [])).to_lower(),
		str(skill.get("description", "")).to_lower(),
	]


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
