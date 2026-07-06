extends RefCounted
class_name BalanceSimulationV2

const SkillCompletionSimulatorScript: GDScript = preload("res://scripts/tools/SkillCompletionSimulator.gd")

const MIN_CLASS_WIN_RATE := 0.45
const MAX_CLASS_WIN_RATE := 0.55
const MIN_HERO_WIN_RATE := 0.35
const MAX_HERO_WIN_RATE := 0.65
const MIN_HERO_APPEARANCES_FOR_EXTREME := 20
const ONE_SIDED_MASTER_HP_GAP := 25
const ONE_SIDED_MAX_ROUND := 10


static func run(sample_count: int = 200) -> Dictionary:
	var report: Dictionary = SkillCompletionSimulatorScript.run(sample_count)
	_enrich(report)
	return report


static func save_report(report: Dictionary, output_path: String) -> bool:
	return SkillCompletionSimulatorScript.save_report(report, output_path)


static func _enrich(report: Dictionary) -> void:
	var samples: Array = report.get("samples", [])
	report["average_rounds"] = _average_rounds(samples)
	report["hero_top_10"] = _hero_rank(report.get("hero", {}), true, 10)
	report["hero_bottom_10"] = _hero_rank(report.get("hero", {}), false, 10)
	report["one_sided_battles"] = _one_sided_battles(samples)
	report["unanswerable_heroes"] = _hero_extremes(report.get("hero", {}), true)
	report["underpowered_heroes"] = _hero_extremes(report.get("hero", {}), false)
	report["class_balance_clean"] = _class_balance_clean(report.get("class", {}))
	report["hero_balance_clean"] = report.get("unanswerable_heroes", []).is_empty() and report.get("underpowered_heroes", []).is_empty()
	report["battle_pace_clean"] = float(report.get("average_rounds", 0.0)) >= 8.0 and float(report.get("average_rounds", 0.0)) <= 25.0
	report["one_sided_count"] = report.get("one_sided_battles", []).size()


static func _average_rounds(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var total := 0.0
	for sample: Dictionary in samples:
		total += float(sample.get("round_number", 0))
	return total / float(samples.size())


static func _hero_rank(hero_rows: Dictionary, descending: bool, limit: int) -> Array:
	var rows: Array = []
	for hero_id in hero_rows.keys():
		var row: Dictionary = hero_rows.get(hero_id, {})
		rows.append({
			"hero_id": str(hero_id),
			"appearances": int(row.get("appearances", 0)),
			"wins": int(row.get("wins", 0)),
			"win_rate": float(row.get("win_rate", 0.0)),
		})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if float(left.get("win_rate", 0.0)) == float(right.get("win_rate", 0.0)):
			return str(left.get("hero_id", "")) < str(right.get("hero_id", ""))
		if descending:
			return float(left.get("win_rate", 0.0)) > float(right.get("win_rate", 0.0))
		return float(left.get("win_rate", 0.0)) < float(right.get("win_rate", 0.0))
	)
	return rows.slice(0, mini(limit, rows.size()))


static func _hero_extremes(hero_rows: Dictionary, high: bool) -> Array:
	var result: Array = []
	for hero_id in hero_rows.keys():
		var row: Dictionary = hero_rows.get(hero_id, {})
		var appearances := int(row.get("appearances", 0))
		if appearances < MIN_HERO_APPEARANCES_FOR_EXTREME:
			continue
		var win_rate := float(row.get("win_rate", 0.0))
		if high and win_rate > MAX_HERO_WIN_RATE:
			result.append({"hero_id": str(hero_id), "win_rate": win_rate, "appearances": appearances})
		if not high and win_rate < MIN_HERO_WIN_RATE:
			result.append({"hero_id": str(hero_id), "win_rate": win_rate, "appearances": appearances})
	return result


static func _class_balance_clean(class_rows: Dictionary) -> bool:
	for class_id in class_rows.keys():
		var win_rate := float(class_rows.get(class_id, {}).get("win_rate", 0.0))
		if win_rate < MIN_CLASS_WIN_RATE or win_rate > MAX_CLASS_WIN_RATE:
			return false
	return true


static func _one_sided_battles(samples: Array) -> Array:
	var result: Array = []
	for sample: Dictionary in samples:
		var gap := absi(int(sample.get("left_hp", 0)) - int(sample.get("right_hp", 0)))
		if gap < ONE_SIDED_MASTER_HP_GAP:
			continue
		if int(sample.get("round_number", 0)) > ONE_SIDED_MAX_ROUND:
			continue
		result.append({
			"index": int(sample.get("index", -1)),
			"outcome": str(sample.get("outcome", "")),
			"round_number": int(sample.get("round_number", 0)),
			"left_hp": int(sample.get("left_hp", 0)),
			"right_hp": int(sample.get("right_hp", 0)),
			"master_hp_gap": gap,
		})
	return result
