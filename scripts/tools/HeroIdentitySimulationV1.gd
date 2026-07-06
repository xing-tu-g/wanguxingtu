extends RefCounted
class_name HeroIdentitySimulationV1

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const SkillCompletionSimulatorScript: GDScript = preload("res://scripts/tools/SkillCompletionSimulator.gd")

const SAMPLE_COUNT := 100
const LOW_PRESENCE_COUNT := 10
const HIGH_PRESENCE_COUNT := 10


static func run(sample_count: int = SAMPLE_COUNT) -> Dictionary:
	var report: Dictionary = SkillCompletionSimulatorScript.run(sample_count)
	_enrich(report)
	return report


static func save_report(report: Dictionary, output_path: String) -> bool:
	return SkillCompletionSimulatorScript.save_report(report, output_path)


static func _enrich(report: Dictionary) -> void:
	DataLoaderScript.load_all()
	var heroes: Array = _playable_heroes()
	var skills_by_id: Dictionary = _skills_by_id()
	var rows: Array = []
	var untriggered: Array[String] = []

	for hero: Dictionary in heroes:
		var hero_id := str(hero.get("id", ""))
		var skill_id := _first_skill_id(hero)
		var appearances := int(report.get("hero", {}).get(hero_id, {}).get("appearances", 0))
		var triggers := int(report.get("skill_triggers", {}).get(skill_id, 0))
		var damage := int(report.get("hero_damage_dealt", {}).get(hero_id, 0))
		var healing := int(report.get("hero_healing_done", {}).get(hero_id, 0))
		var tanking := int(report.get("hero_damage_taken", {}).get(hero_id, 0))
		var presence_score := triggers + damage + healing + int(round(float(tanking) * 0.5))
		if triggers <= 0:
			untriggered.append(skill_id)
		rows.append({
			"hero_id": hero_id,
			"name": str(hero.get("name", hero_id)),
			"faction": str(hero.get("faction", "")),
			"class": str(hero.get("class", hero.get("profession", ""))),
			"skill_id": skill_id,
			"skill_name": str(skills_by_id.get(skill_id, {}).get("name", skill_id)),
			"appearances": appearances,
			"skill_triggers": triggers,
			"trigger_per_appearance": 0.0 if appearances <= 0 else float(triggers) / float(appearances),
			"damage": damage,
			"healing": healing,
			"tanking": tanking,
			"presence_score": presence_score,
		})

	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("presence_score", 0)) < int(right.get("presence_score", 0))
	)

	report["hero_identity_rows"] = rows
	report["low_presence_heroes"] = rows.slice(0, mini(LOW_PRESENCE_COUNT, rows.size()))
	var high_rows := rows.duplicate(true)
	high_rows.reverse()
	report["high_presence_heroes"] = high_rows.slice(0, mini(HIGH_PRESENCE_COUNT, high_rows.size()))
	report["duplicate_skill_signature_groups"] = _duplicate_skill_signature_groups(heroes, skills_by_id)
	report["untriggered_playable_skills"] = untriggered
	report["hero_identity_simulation_clean"] = int(report.get("sample_count", 0)) == SAMPLE_COUNT \
		and int(report.get("ended_count", 0)) == SAMPLE_COUNT \
		and int(report.get("timeouts", 0)) == 0 \
		and report.get("anomalies", []).is_empty() \
		and report.get("duplicate_skill_signature_groups", []).is_empty() \
		and report.get("untriggered_playable_skills", []).is_empty()


static func _playable_heroes() -> Array:
	var result: Array = []
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if bool(hero.get("is_summon", false)) or str(hero.get("id", "")) == "yellow_turban":
			continue
		result.append(hero)
	return result


static func _skills_by_id() -> Dictionary:
	var result: Dictionary = {}
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		result[str(skill.get("id", ""))] = skill
	return result


static func _first_skill_id(hero: Dictionary) -> String:
	var skill_ids: Array = hero.get("skill_ids", [])
	if skill_ids.is_empty():
		return ""
	return str(skill_ids[0])


static func _duplicate_skill_signature_groups(heroes: Array, skills_by_id: Dictionary) -> Array:
	var groups: Dictionary = {}
	for hero: Dictionary in heroes:
		var skill_id := _first_skill_id(hero)
		var skill: Dictionary = skills_by_id.get(skill_id, {})
		var signature := _skill_signature(skill)
		if not groups.has(signature):
			groups[signature] = []
		groups[signature].append({
			"hero_id": str(hero.get("id", "")),
			"name": str(hero.get("name", "")),
			"skill_id": skill_id,
		})

	var duplicates: Array = []
	for signature in groups.keys():
		var members: Array = groups.get(signature, [])
		if members.size() > 1:
			duplicates.append({
				"signature": str(signature),
				"members": members,
			})
	return duplicates


static func _skill_signature(skill: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|duration=%d" % [
		str(skill.get("trigger", "")),
		str(skill.get("effect_type", "")),
		str(skill.get("attack_shape", "")),
		str(skill.get("target_filter", "")),
		JSON.stringify(skill.get("params", {})),
		int(skill.get("duration_turns", 0)),
	]
