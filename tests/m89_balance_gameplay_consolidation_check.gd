extends SceneTree

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const BalanceSimulationV2Script: GDScript = preload("res://scripts/tools/BalanceSimulationV2.gd")

const SAMPLE_COUNT := 200
const REPORT_PATH := "D:/wanguxingtu/tmp/skill_balance/balance_simulation_v2_200.json"
const CLASS_MIN := 0.45
const CLASS_MAX := 0.55
const HERO_MIN := 0.35
const HERO_MAX := 0.65


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()
	_check_class_skill_distribution(failures)
	_check_balance_simulation(failures)
	if failures.is_empty():
		print("M89 balance gameplay consolidation checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_class_skill_distribution(failures: Array[String]) -> void:
	var heroes: Array = _playable_heroes()
	var skills_by_id: Dictionary = _skills_by_id()
	var thresholds := {
		"tank": ["guard", "shield", "protect", "defense", "tank"],
		"warrior": ["growth", "modify_stat", "attack_buff", "bonus_damage", "burst", "mobility", "control", "shield", "vanguard"],
		"archer": ["sustain", "pierce", "burn", "poison"],
		"mage": ["control", "area", "debuff", "burn", "summon", "side_buff", "stun", "heal", "buff", "support"],
		"assassin": ["backstab", "burst", "execute", "assassin"],
	}
	for class_id in thresholds.keys():
		var total := 0
		var matched := 0
		for hero: Dictionary in heroes:
			if str(hero.get("class", "")) != str(class_id):
				continue
			for skill_id_value in hero.get("skill_ids", []):
				var skill: Dictionary = skills_by_id.get(str(skill_id_value), {})
				if skill.is_empty():
					continue
				total += 1
				if _skill_matches(skill, thresholds[class_id]):
					matched += 1
		var ratio := 0.0 if total == 0 else float(matched) / float(total)
		_expect(ratio >= 0.70, "%s skill distribution is at least 70%% aligned" % str(class_id), failures)


func _check_balance_simulation(failures: Array[String]) -> void:
	var report: Dictionary = BalanceSimulationV2Script.run(SAMPLE_COUNT)
	var saved: bool = BalanceSimulationV2Script.save_report(report, REPORT_PATH)
	_expect(saved, "balance simulation v2 report is written", failures)
	_expect(int(report.get("sample_count", 0)) == SAMPLE_COUNT, "balance simulation runs 200 samples", failures)
	_expect(int(report.get("ended_count", 0)) == SAMPLE_COUNT, "balance simulation finishes every sample", failures)
	_expect(int(report.get("timeouts", 0)) == 0, "balance simulation has no timeouts", failures)
	_expect(report.get("anomalies", []).is_empty(), "balance simulation has no anomalies", failures)
	_expect(bool(report.get("class_balance_clean", false)), "all class win rates are between 45% and 55%", failures)
	_expect(bool(report.get("hero_balance_clean", false)), "no hero is above 65% or below 35%", failures)
	_expect(bool(report.get("battle_pace_clean", false)), "average round count stays in target pace", failures)
	for class_id in report.get("class", {}).keys():
		var win_rate := float(report.get("class", {}).get(class_id, {}).get("win_rate", 0.0))
		_expect(win_rate >= CLASS_MIN and win_rate <= CLASS_MAX, "class %s win rate is in target range" % str(class_id), failures)
	for hero_id in report.get("hero", {}).keys():
		var row: Dictionary = report.get("hero", {}).get(hero_id, {})
		var appearances := int(row.get("appearances", 0))
		if appearances < 20:
			continue
		var win_rate := float(row.get("win_rate", 0.0))
		_expect(win_rate >= HERO_MIN and win_rate <= HERO_MAX, "hero %s win rate is not extreme" % str(hero_id), failures)


func _playable_heroes() -> Array:
	var result: Array = []
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if bool(hero.get("is_summon", false)) or str(hero.get("id", "")) == "yellow_turban":
			continue
		result.append(hero)
	return result


func _skills_by_id() -> Dictionary:
	var result: Dictionary = {}
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		result[str(skill.get("id", ""))] = skill
	return result


func _skill_matches(skill: Dictionary, needles: Array) -> bool:
	var haystack := "%s,%s,%s,%s" % [
		str(skill.get("tags", [])).to_lower(),
		str(skill.get("effect_type", "")).to_lower(),
		str(skill.get("skill_type", "")).to_lower(),
		str(skill.get("description", "")).to_lower(),
	]
	for needle in needles:
		if haystack.contains(str(needle)):
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
