extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BattleScreenScript: GDScript = preload("res://scripts/ui/BattleScreen.gd")
const ResultScreenScript: GDScript = preload("res://scripts/ui/ResultScreen.gd")


func _init() -> void:
	var failures: Array[String] = []
	_check_battle_state_stats(failures)
	_check_result_payload_and_screen(failures)

	if failures.is_empty():
		print("M18 battle stats checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_battle_state_stats(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.set_star_power("left", 10)
	var deploy_result: Dictionary = state.deploy_hero("guanyu", "left", 2, 3)
	_expect(deploy_result.ok, "deployment succeeds for stats test", failures)
	var attacker: Dictionary = deploy_result.get("unit", {})
	var target: Dictionary = _add_unit(state, "target", "right", 4, 3, {"hp": 4, "max_hp": 4})
	var unit_damage: int = state.apply_damage_to_unit(target, 3, "physical", attacker)
	var defeat_damage: int = state.apply_damage_to_unit(target, 3, "physical", attacker)
	var master_damage: int = state.apply_master_damage("right", 5, -1, attacker)
	var stats: Dictionary = state.battle_stats.snapshot()
	_expect(_stat_value(stats, "deployments", "left") == 1, "left deployment count is recorded", failures)
	_expect(unit_damage == 3 and defeat_damage == 3, "unit damage calls return applied damage", failures)
	_expect(_stat_value(stats, "unit_damage_dealt", "left") == 6, "left unit damage total is recorded", failures)
	_expect(_stat_value(stats, "units_defeated", "left") == 1, "left defeated unit count is recorded", failures)
	_expect(master_damage == 5, "master damage call returns applied damage", failures)
	_expect(_stat_value(stats, "master_damage_dealt", "left") == 5, "left master damage total is recorded", failures)

	state.reset()
	var reset_stats: Dictionary = state.battle_stats.snapshot()
	_expect(_stat_value(reset_stats, "deployments", "left") == 0, "stats reset with battle state", failures)


func _check_result_payload_and_screen(failures: Array[String]) -> void:
	var battle_screen: Control = BattleScreenScript.new()
	battle_screen.battle_state.set_star_power("left", 10)
	battle_screen.battle_state.deploy_hero("guanyu", "left", 2, 3)
	battle_screen.battle_state.master_hp["right"] = 0
	var battle_result: Dictionary = battle_screen._check_battle_end()
	_expect(battle_result.has("stats"), "battle result carries stats snapshot", failures)
	_expect(_stat_value(battle_result.stats, "deployments", "left") == 1, "battle result stats include deployment count", failures)

	var result_screen: Control = ResultScreenScript.new()
	_expect(result_screen != null, "result screen script can instantiate", failures)
	result_screen.free()
	battle_screen.free()


func _add_unit(state, unit_id: String, side: String, column: int, row: int, overrides: Dictionary = {}) -> Dictionary:
	var unit_data := {
		"instance_id": unit_id,
		"entry_order": state.next_unit_sequence,
		"hero_id": unit_id,
		"name": unit_id,
		"max_hp": 10,
		"hp": 10,
		"attack": 2,
		"range": 1,
		"move": 1,
		"class": "warrior",
		"physical_block": 0,
		"magic_block": 0,
		"damage_type": "physical",
		"skill_ids": [],
		"statuses": {},
		"stats": {},
	}
	for key in overrides:
		unit_data[key] = overrides[key]
	var result: Dictionary = state.create_unit_instance(unit_data, side, column, row)
	return result.get("unit", {})


func _stat_value(stats: Dictionary, section: String, side: String) -> int:
	var section_data = stats.get(section, {})
	if section_data is Dictionary:
		return int(section_data.get(side, 0))
	return 0


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)

