extends RefCounted
class_name FactionEnergySimulationV1

const SkillCompletionSimulatorScript: GDScript = preload("res://scripts/tools/SkillCompletionSimulator.gd")
const FactionEnergySystemScript: GDScript = preload("res://scripts/battle/FactionEnergySystem.gd")

const SAMPLE_COUNT := 100
const TARGET_MIN_AVERAGE_ROUNDS := 10.0
const TARGET_MAX_AVERAGE_ROUNDS := 20.0
const MAX_FACTION_AVERAGE_GAP := 4.0
const MAX_SAMPLE_FACTION_ENERGY := 18
const MIN_CLASS_WIN_RATE := 0.45
const MAX_CLASS_WIN_RATE := 0.55


static func run(sample_count: int = SAMPLE_COUNT) -> Dictionary:
	var report: Dictionary = SkillCompletionSimulatorScript.run(sample_count)
	_enrich(report)
	return report


static func save_report(report: Dictionary, output_path: String) -> bool:
	return SkillCompletionSimulatorScript.save_report(report, output_path)


static func _enrich(report: Dictionary) -> void:
	var sample_count := int(report.get("sample_count", 0))
	report["average_rounds"] = _average_rounds(report.get("samples", []))
	report["faction_energy_heroes"] = FactionEnergySystemScript.new().energy_heroes()
	report["faction_energy_hero_limit_clean"] = bool(FactionEnergySystemScript.new().validate_energy_hero_limits().get("ok", false))
	report["faction_energy_average"] = _faction_energy_average(report.get("faction_energy_gained", {}), sample_count)
	report["faction_energy_source_distribution"] = report.get("faction_energy_sources", {}).duplicate(true)
	report["faction_energy_total"] = _faction_energy_total(report.get("faction_energy_gained", {}))
	report["faction_energy_dominance_clean"] = _dominance_clean(report.get("faction_energy_average", {}))
	report["infinite_energy_loop_clean"] = _infinite_loop_clean(report.get("samples", []))
	report["battle_pace_clean"] = float(report.get("average_rounds", 0.0)) >= TARGET_MIN_AVERAGE_ROUNDS and float(report.get("average_rounds", 0.0)) <= TARGET_MAX_AVERAGE_ROUNDS
	report["class_balance_clean"] = _class_balance_clean(report.get("class", {}))
	report["faction_energy_simulation_clean"] = bool(report.get("faction_energy_hero_limit_clean", false)) \
		and bool(report.get("faction_energy_dominance_clean", false)) \
		and bool(report.get("infinite_energy_loop_clean", false)) \
		and bool(report.get("battle_pace_clean", false)) \
		and bool(report.get("class_balance_clean", false)) \
		and int(report.get("timeouts", 0)) == 0 \
		and report.get("anomalies", []).is_empty()


static func _faction_energy_average(rows: Dictionary, sample_count: int) -> Dictionary:
	var result := {}
	for faction in ["shu", "wei", "wu", "qun"]:
		var total := 0
		var row: Dictionary = rows.get(faction, {})
		for value in row.values():
			total += int(value)
		result[faction] = 0.0 if sample_count <= 0 else float(total) / float(sample_count)
	return result


static func _average_rounds(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var total := 0.0
	for sample: Dictionary in samples:
		total += float(sample.get("round_number", 0))
	return total / float(samples.size())


static func _faction_energy_total(rows: Dictionary) -> Dictionary:
	var result := {}
	for faction in ["shu", "wei", "wu", "qun"]:
		var total := 0
		var row: Dictionary = rows.get(faction, {})
		for value in row.values():
			total += int(value)
		result[faction] = total
	return result


static func _dominance_clean(averages: Dictionary) -> bool:
	var min_value := 999999.0
	var max_value := 0.0
	for faction in ["shu", "wei", "wu", "qun"]:
		var value := float(averages.get(faction, 0.0))
		min_value = minf(min_value, value)
		max_value = maxf(max_value, value)
	return max_value - min_value <= MAX_FACTION_AVERAGE_GAP


static func _infinite_loop_clean(samples: Array) -> bool:
	for sample: Dictionary in samples:
		var stats: Dictionary = sample.get("stats", {})
		var gained: Dictionary = stats.get("faction_energy_gained", {})
		for faction in gained.keys():
			var row: Dictionary = gained.get(faction, {})
			for amount in row.values():
				if int(amount) > MAX_SAMPLE_FACTION_ENERGY:
					return false
	return true


static func _class_balance_clean(class_rows: Dictionary) -> bool:
	for class_id in class_rows.keys():
		var win_rate := float(class_rows.get(class_id, {}).get("win_rate", 0.0))
		if win_rate < MIN_CLASS_WIN_RATE or win_rate > MAX_CLASS_WIN_RATE:
			return false
	return true
