extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")


func _init() -> void:
	var failures: Array[String] = []
	_check_sunshangxiang_data(failures)
	_check_combo_applies_sustain_damage(failures)
	_check_combo_skips_defeated_target(failures)

	if failures.is_empty():
		print("M16 Sunshangxiang combo checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_sunshangxiang_data(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	var hero_def: Dictionary = state.get_hero_def("sunshangxiang")
	_expect(hero_def.get("skill_ids", []).has("sunshangxiang_combo"), "Sunshangxiang uses the combo skill id", failures)
	var combo_skill := _find_skill(state, "sunshangxiang_combo")
	_expect(str(combo_skill.get("name", "")).length() > 0, "combo skill has display name", failures)
	_expect(str(combo_skill.get("trigger", "")) == "attack_hit", "combo triggers on attack hit", failures)
	_expect(str(combo_skill.get("effect_type", "")) == "apply_status", "combo uses sustain status effect", failures)
	_expect(str(combo_skill.get("params", {}).get("status_id", "")) == "burn", "combo applies burn status", failures)
	_expect(int(combo_skill.get("params", {}).get("value", 0)) == 1, "combo burn damage is one", failures)


func _check_combo_applies_sustain_damage(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	var sunshangxiang: Dictionary = _add_unit(state, "sun_unit", "left", 4, 3, {
		"hero_id": "sunshangxiang",
		"class": "archer",
		"attack": 3,
		"range": 4,
		"skill_ids": ["sunshangxiang_combo"],
	})
	var target: Dictionary = _add_unit(state, "target", "right", 7, 3, {"hp": 10, "max_hp": 10})
	var attack_result: Dictionary = MovementSystemScript.act_unit(state, sunshangxiang)
	_expect(str(attack_result.get("action", "")) == "attack", "Sunshangxiang attacks target in range", failures)
	_expect(int(attack_result.get("damage", 0)) == 3, "base attack damage remains three", failures)
	_expect(attack_result.get("skill_results", []).size() == 1, "combo produces one skill result", failures)
	var combo_result: Dictionary = attack_result.get("skill_results", [])[0]
	_expect(str(combo_result.get("skill_id", "")) == "sunshangxiang_combo", "combo skill result id is present", failures)
	_expect(str(combo_result.get("status_id", "")) == "burn", "combo applies burn status", failures)
	_expect(int(target.get("hp", 0)) == 7, "target HP only includes base damage before end turn", failures)
	state.process_end_turn_statuses()
	_expect(int(target.get("hp", 0)) == 6, "target HP includes delayed sustain damage after end turn", failures)


func _check_combo_skips_defeated_target(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	var sunshangxiang: Dictionary = _add_unit(state, "finisher", "left", 4, 3, {
		"hero_id": "sunshangxiang",
		"class": "archer",
		"attack": 4,
		"range": 4,
		"skill_ids": ["sunshangxiang_combo"],
	})
	_add_unit(state, "low_hp_target", "right", 7, 3, {"hp": 3, "max_hp": 3})
	var attack_result: Dictionary = MovementSystemScript.act_unit(state, sunshangxiang)
	_expect(int(attack_result.get("damage", 0)) == 4, "base attack defeats low HP target", failures)
	_expect(attack_result.get("skill_results", []).size() == 1, "combo still reports one skill attempt", failures)
	var combo_result: Dictionary = attack_result.get("skill_results", [])[0]
	_expect(not bool(combo_result.get("ok", false)), "combo does not damage already defeated target", failures)
	_expect(str(combo_result.get("reason", "")) == "missing_target", "defeated target is reported as missing", failures)


func _find_skill(state: BattleState, skill_id: String) -> Dictionary:
	for skill_def: Dictionary in state.get_skill_defs():
		if str(skill_def.get("id", "")) == skill_id:
			return skill_def
	return {}


func _add_unit(state: BattleState, unit_id: String, side: String, column: int, row: int, overrides: Dictionary = {}) -> Dictionary:
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


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
