extends RefCounted
class_name BattleReportManager

const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const SkillDataLoaderScript: GDScript = preload("res://scripts/data/SkillDataLoader.gd")
const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")

const SAVE_PATH := "user://battle_reports.json"
const MAX_REPORTS := 20


static func record_report(result_payload: Dictionary) -> Dictionary:
	var report := build_report(result_payload)
	report["star_track_result"] = StarTrackSystemScript.apply_battle_result(str(report.get("outcome", "unknown")))
	var reports := load_reports()
	reports.push_front(report)
	while reports.size() > MAX_REPORTS:
		reports.pop_back()
	_write_reports(reports)
	return report


static func load_reports() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return []
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	var data = json.get_data()
	if data is Array:
		return data
	return []


static func latest_report() -> Dictionary:
	var reports := load_reports()
	if reports.is_empty():
		return {}
	return reports[0]


static func build_report(result_payload: Dictionary) -> Dictionary:
	var stats: Dictionary = result_payload.get("stats", {})
	var outcome := str(result_payload.get("outcome", "unknown"))
	var mvp_id := _mvp_from_stats(stats)
	return {
		"id": Time.get_datetime_string_from_system(),
		"outcome": outcome,
		"round_number": int(result_payload.get("round_number", 0)),
		"left_hp": int(result_payload.get("left_hp", 0)),
		"right_hp": int(result_payload.get("right_hp", 0)),
		"mvp": mvp_id,
		"mvp_reason": _mvp_reason(mvp_id, stats),
		"star_power": stats.get("faction_energy_heroes", {}),
		"star_power_lines": _hero_counter_lines(stats.get("faction_energy_heroes", {}), "星力"),
		"faction_performance_lines": _faction_performance_lines(stats),
		"skill_triggers": stats.get("skill_triggers", {}),
		"skill_trigger_lines": _skill_counter_lines(stats.get("skill_triggers", {})),
		"kills": stats.get("units_defeated", {}),
		"damage": _damage_summary(stats),
		"hero_contributions": _hero_contribution_lines(stats),
		"pace": _pace_summary(int(result_payload.get("round_number", 0))),
		"battle_log": _sanitize_log_lines(result_payload.get("battle_log", [])),
		"raw": result_payload.duplicate(true),
	}


static func _mvp_from_stats(stats: Dictionary) -> String:
	var scores := {}
	_accumulate_scores(scores, stats.get("hero_damage_dealt", {}), 1)
	_accumulate_skill_scores(scores, stats.get("skill_triggers", {}), 3)
	_accumulate_scores(scores, stats.get("hero_healing_done", {}), 1)
	_accumulate_scores(scores, stats.get("faction_energy_heroes", {}), 2)
	if scores.is_empty():
		return "暂未评定"
	var best_id := ""
	var best_score := -1
	for key in scores.keys():
		var score := int(scores.get(key, 0))
		if score > best_score:
			best_id = str(key)
			best_score = score
	return best_id


static func _accumulate_scores(scores: Dictionary, values, weight: int) -> void:
	if not (values is Dictionary):
		return
	for key in values.keys():
		var id := str(key)
		if id.is_empty() or id in ["left", "right"]:
			continue
		scores[id] = int(scores.get(id, 0)) + int(values.get(key, 0)) * weight


static func _accumulate_skill_scores(scores: Dictionary, values, weight: int) -> void:
	if not (values is Dictionary):
		return
	for key in values.keys():
		var owner_id := _skill_owner_id(str(key))
		if owner_id.is_empty():
			continue
		scores[owner_id] = int(scores.get(owner_id, 0)) + int(values.get(key, 0)) * weight


static func _damage_summary(stats: Dictionary) -> Dictionary:
	return {
		"left": int(stats.get("unit_damage_dealt", {}).get("left", 0)) + int(stats.get("master_damage_dealt", {}).get("left", 0)),
		"right": int(stats.get("unit_damage_dealt", {}).get("right", 0)) + int(stats.get("master_damage_dealt", {}).get("right", 0)),
	}


static func _mvp_reason(hero_id: String, stats: Dictionary) -> String:
	if hero_id.is_empty() or hero_id == "暂未评定":
		return "暂无足够贡献数据"
	var damage := int(stats.get("hero_damage_dealt", {}).get(hero_id, 0))
	var taken := int(stats.get("hero_damage_taken", {}).get(hero_id, 0))
	var healing := int(stats.get("hero_healing_done", {}).get(hero_id, 0))
	var energy := int(stats.get("faction_energy_heroes", {}).get(hero_id, 0))
	var triggers := _hero_skill_trigger_count(hero_id, stats.get("skill_triggers", {}))
	var parts: Array[String] = []
	if damage > 0:
		parts.append("伤害 %d" % damage)
	if triggers > 0:
		parts.append("技能 %d" % triggers)
	if energy > 0:
		parts.append("星力 %d" % energy)
	if healing > 0:
		parts.append("治疗 %d" % healing)
	if taken > 0:
		parts.append("承伤 %d" % taken)
	if parts.is_empty():
		return "综合贡献最高"
	return " - ".join(parts)


static func _faction_performance_lines(stats: Dictionary) -> Array[String]:
	var damage := _damage_summary(stats)
	var kills: Dictionary = stats.get("units_defeated", {})
	var lines: Array[String] = []
	lines.append("我方 - 伤害 %d - 击杀 %d" % [int(damage.get("left", 0)), int(kills.get("left", 0))])
	lines.append("敌方 - 伤害 %d - 击杀 %d" % [int(damage.get("right", 0)), int(kills.get("right", 0))])
	var healing: Dictionary = stats.get("hero_healing_done", {})
	var left_healing := 0
	var right_healing := 0
	for hero_id in healing.keys():
		var side := _hero_side_from_stats(str(hero_id), stats)
		if side == "right":
			right_healing += int(healing.get(hero_id, 0))
		else:
			left_healing += int(healing.get(hero_id, 0))
	lines.append("治疗 - 我方 %d - 敌方 %d" % [left_healing, right_healing])
	return lines


static func _hero_contribution_lines(stats: Dictionary) -> Array[String]:
	var hero_ids := {}
	for section in ["hero_damage_dealt", "hero_damage_taken", "hero_healing_done", "faction_energy_heroes"]:
		var values = stats.get(section, {})
		if values is Dictionary:
			for key in values.keys():
				var hero_id := str(key)
				if not hero_id.is_empty() and not (hero_id in ["left", "right"]):
					hero_ids[hero_id] = true
	var skill_triggers = stats.get("skill_triggers", {})
	if skill_triggers is Dictionary:
		for skill_id in skill_triggers.keys():
			var owner_id := _skill_owner_id(str(skill_id))
			if not owner_id.is_empty():
				hero_ids[owner_id] = true

	var rows: Array[Dictionary] = []
	for hero_id in hero_ids.keys():
		var damage := int(stats.get("hero_damage_dealt", {}).get(hero_id, 0))
		var taken := int(stats.get("hero_damage_taken", {}).get(hero_id, 0))
		var healing := int(stats.get("hero_healing_done", {}).get(hero_id, 0))
		var energy := int(stats.get("faction_energy_heroes", {}).get(hero_id, 0))
		var triggers := _hero_skill_trigger_count(str(hero_id), skill_triggers)
		var score := damage + taken + healing + energy * 2 + triggers * 3
		rows.append({
			"hero_id": str(hero_id),
			"score": score,
			"line": "%s - 伤害 %d - 承伤 %d - 治疗 %d - 技能 %d - 星力 %d" % [
				_hero_name(str(hero_id)),
				damage,
				taken,
				healing,
				triggers,
				energy,
			],
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	var lines: Array[String] = []
	for row in rows:
		lines.append(str(row.get("line", "")))
	return lines


static func _hero_counter_lines(values, label: String) -> Array[String]:
	var lines: Array[String] = []
	if not (values is Dictionary):
		return lines
	for key in values.keys():
		lines.append("%s - %s %d" % [_hero_name(str(key)), label, int(values.get(key, 0))])
	return lines


static func _skill_counter_lines(values) -> Array[String]:
	var lines: Array[String] = []
	if not (values is Dictionary):
		return lines
	for key in values.keys():
		var skill_id := str(key)
		lines.append("%s - %d" % [_skill_display_name(skill_id), int(values.get(key, 0))])
	return lines


static func _hero_skill_trigger_count(hero_id: String, values) -> int:
	if not (values is Dictionary):
		return 0
	var total := 0
	for skill_id in values.keys():
		if _skill_owner_id(str(skill_id)) == hero_id:
			total += int(values.get(skill_id, 0))
	return total


static func _skill_display_name(skill_id: String) -> String:
	var skill: Dictionary = SkillDataLoaderScript.skill_by_id(skill_id)
	if skill.is_empty():
		return _clean_id(skill_id)
	var owner_name := _hero_name(str(skill.get("owner_hero_id", "")))
	var skill_name := str(skill.get("name", skill_id))
	if owner_name.is_empty() or owner_name == "暂未评定":
		return skill_name
	return "%s·%s" % [owner_name, skill_name]


static func _skill_owner_id(skill_id: String) -> String:
	var skill: Dictionary = SkillDataLoaderScript.skill_by_id(skill_id)
	return str(skill.get("owner_hero_id", ""))


static func _hero_name(hero_id: String) -> String:
	if hero_id.is_empty() or hero_id == "暂未评定":
		return "暂未评定"
	var hero: Dictionary = HeroDataLoaderScript.hero_by_id(hero_id)
	return str(hero.get("name", _clean_id(hero_id)))


static func _hero_side_from_stats(hero_id: String, stats: Dictionary) -> String:
	var raw: Dictionary = stats.get("hero_sides", {})
	return str(raw.get(hero_id, "left"))


static func _sanitize_log_lines(value) -> Array[String]:
	var lines: Array[String] = []
	if not (value is Array):
		return lines
	for item in value:
		lines.append(_sanitize_text(str(item)))
	return lines


static func _sanitize_text(text: String) -> String:
	var result := text
	for skill: Dictionary in SkillDataLoaderScript.all_skills():
		var skill_id := str(skill.get("id", ""))
		if not skill_id.is_empty():
			result = result.replace(skill_id, _skill_display_name(skill_id))
	result = result.replace("：", ": ")
	result = result.replace("（", "(")
	result = result.replace("）", ")")
	result = result.replace("，", ", ")
	return result


static func _clean_id(value: String) -> String:
	return value.replace("_", " ")


static func _pace_summary(round_number: int) -> String:
	if round_number <= 3:
		return "前期速战"
	if round_number <= 10:
		return "中期技能爆发"
	return "后期收割"


static func _write_reports(reports: Array) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(reports, "\t", false))
	file.close()
	return true
