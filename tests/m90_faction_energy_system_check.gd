extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const FactionEnergySystemScript: GDScript = preload("res://scripts/battle/FactionEnergySystem.gd")
const FactionEnergySimulationV1Script: GDScript = preload("res://scripts/tools/FactionEnergySimulationV1.gd")


func _init() -> void:
	var failures: Array[String] = []
	_check_static_rules(failures)
	_check_caocao_condition_energy(failures)
	_check_xunyu_refund(failures)
	_check_zhaoyun_kill_energy_once(failures)
	_check_sunquan_skill_energy(failures)
	_check_yuanshao_death_energy(failures)
	_check_faction_energy_simulation(failures)
	if failures.is_empty():
		print("M90 faction energy system checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_static_rules(failures: Array[String]) -> void:
	var system = FactionEnergySystemScript.new()
	var validation: Dictionary = system.validate_energy_hero_limits()
	_expect(bool(validation.get("ok", false)), "each faction has at most 2 faction energy heroes", failures)
	var heroes: Dictionary = system.energy_heroes()
	_expect(heroes.keys().size() == 4, "four factions have faction energy configuration", failures)
	for faction in ["shu", "wei", "wu", "qun"]:
		var row: Dictionary = heroes.get(faction, {})
		_expect(not str(row.get("producer", "")).is_empty(), "%s has one producer" % faction, failures)
		_expect(not str(row.get("amplifier", "")).is_empty(), "%s has one amplifier" % faction, failures)
	var source := FileAccess.get_file_as_string("res://scripts/battle/FactionEnergySystem.gd").to_lower()
	_expect(not source.contains("draw"), "faction energy system does not draw cards", failures)
	_expect(not source.contains("percent") and not source.contains("multiplier") and not source.contains("chance"), "faction energy system has no percentage/multiplier/chance rules", failures)


func _check_caocao_condition_energy(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.set_star_power("left", 10)
	_expect(state.deploy_hero("caocao", "left", 2, 3).ok, "caocao deployed", failures)
	state.set_star_power("left", 5)
	var results: Array = state.start_faction_energy_side_turn("left")
	_expect(state.get_star_power("left") == 6, "caocao condition grants +1 star power", failures)
	_expect(_has_energy_result(results, "caocao", "condition", 1), "caocao condition source recorded", failures)


func _check_xunyu_refund(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.set_star_power("left", 10)
	_expect(state.deploy_hero("xunyu", "left", 2, 2).ok, "xunyu deployed", failures)
	state.set_star_power("left", 10)
	var result: Dictionary = state.deploy_hero("caocao", "left", 2, 3)
	_expect(result.ok, "cost 5 hero deployed beside xunyu", failures)
	_expect(state.get_star_power("left") == 6, "xunyu refunds 1 after first cost >=5 spend", failures)
	_expect(_has_energy_result(result.get("faction_energy_results", []), "xunyu", "refund", 1), "xunyu refund source recorded", failures)


func _check_zhaoyun_kill_energy_once(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.set_star_power("left", 10)
	var zr: Dictionary = state.deploy_hero("zhaoyun", "left", 2, 3)
	_expect(zr.ok, "zhaoyun deployed", failures)
	state.start_faction_energy_side_turn("left")
	state.set_star_power("left", 0)
	var first_target := _create_unit(state, "yellow_turban", "right", 8, 3)
	state.apply_damage_to_unit(first_target, 99, "true", zr.get("unit", {}))
	_expect(state.get_star_power("left") == 1, "zhaoyun first kill grants +1 star power", failures)
	var second_target := _create_unit(state, "yellow_turban", "right", 8, 4)
	state.apply_damage_to_unit(second_target, 99, "true", zr.get("unit", {}))
	_expect(state.get_star_power("left") == 1, "zhaoyun kill energy is once per side turn", failures)


func _check_sunquan_skill_energy(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.set_star_power("left", 10)
	var sr: Dictionary = state.deploy_hero("sunquan", "left", 2, 3)
	_expect(sr.ok, "sunquan deployed", failures)
	state.start_faction_energy_side_turn("left")
	state.set_star_power("left", 0)
	var dummy_skill := {"id": "dummy_skill"}
	state.on_skill_triggered(sr.get("unit", {}), dummy_skill)
	_expect(state.get_star_power("left") == 0, "sunquan waits for two skill triggers", failures)
	var results: Array = state.on_skill_triggered(sr.get("unit", {}), dummy_skill)
	_expect(state.get_star_power("left") == 1, "sunquan grants +1 after two skill triggers", failures)
	_expect(_has_energy_result(results, "sunquan", "skill", 1), "sunquan skill source recorded", failures)


func _check_yuanshao_death_energy(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.set_star_power("left", 10)
	var yr: Dictionary = state.deploy_hero("yuanshao", "left", 2, 3)
	_expect(yr.ok, "yuanshao deployed", failures)
	var attacker := _create_unit(state, "yellow_turban", "right", 8, 3)
	state.start_faction_energy_side_turn("left")
	state.set_star_power("left", 0)
	state.apply_damage_to_unit(yr.get("unit", {}), 99, "true", attacker)
	_expect(state.get_star_power("left") == 1, "yuanshao first own death grants +1 star power", failures)


func _check_faction_energy_simulation(failures: Array[String]) -> void:
	var report: Dictionary = FactionEnergySimulationV1Script.run(100)
	_expect(int(report.get("sample_count", 0)) == 100, "faction energy simulation runs 100 samples", failures)
	_expect(int(report.get("ended_count", 0)) == 100, "faction energy simulation finishes every sample", failures)
	_expect(int(report.get("timeouts", 0)) == 0, "faction energy simulation has no timeouts", failures)
	_expect(bool(report.get("faction_energy_hero_limit_clean", false)), "faction energy hero limit is clean", failures)
	_expect(bool(report.get("faction_energy_dominance_clean", false)), "no faction completely dominates energy gain", failures)
	_expect(bool(report.get("infinite_energy_loop_clean", false)), "no infinite energy loop detected", failures)
	_expect(bool(report.get("battle_pace_clean", false)), "battle pace remains in target range", failures)
	_expect(bool(report.get("class_balance_clean", false)), "class balance remains in target range", failures)


func _create_unit(state: BattleState, hero_id: String, side: String, column: int, row: int) -> Dictionary:
	var unit: Dictionary = state.build_unit_data(hero_id, state.get_hero_def(hero_id))
	unit["side"] = side
	var result: Dictionary = state.create_unit_instance(unit, side, column, row)
	return result.get("unit", {})


func _has_energy_result(results: Array, hero_id: String, source: String, amount: int) -> bool:
	for result: Dictionary in results:
		if str(result.get("hero_id", "")) == hero_id and str(result.get("source", "")) == source and int(result.get("amount", 0)) == amount:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
