extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	_check_sunshangxiang_data_and_passive_text(failures)
	_check_combo_adds_bonus_damage(failures)
	_check_combo_skips_defeated_target(failures)
	_check_battle_screen_detail_and_log_text(failures)
	await process_frame

	if failures.is_empty():
		print("M16 Sunshangxiang combo checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_sunshangxiang_data_and_passive_text(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var sunshangxiang: Dictionary = state.get_hero_def("sunshangxiang")
	_expect(sunshangxiang.get("skill_ids", []).has("sunshangxiang_combo"), "Sunshangxiang uses the combo skill id", failures)
	var combo_skill := _find_skill(state, "sunshangxiang_combo")
	_expect(str(combo_skill.get("name", "")) == "枭姬连弩", "Sunshangxiang combo skill has Chinese name", failures)
	_expect(str(combo_skill.get("trigger", "")) == "attack_hit", "combo triggers on attack hit", failures)
	_expect(str(combo_skill.get("effect_type", "")) == "bonus_damage", "combo uses bonus damage effect", failures)
	_expect(int(combo_skill.get("params", {}).get("damage", 0)) == 2, "combo bonus damage is two", failures)


func _check_combo_adds_bonus_damage(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var sunshangxiang: Dictionary = _add_unit(state, "sun_unit", "left", 4, 3, {
		"hero_id": "sunshangxiang",
		"name": "孙尚香",
		"attack": 4,
		"range": 4,
		"skill_ids": ["sunshangxiang_combo"],
	})
	var target: Dictionary = _add_unit(state, "target", "right", 7, 3, {"hp": 10, "max_hp": 10})
	var attack_result: Dictionary = MovementSystemScript.act_unit(state, sunshangxiang)
	_expect(attack_result.action == "attack", "Sunshangxiang attacks target in range", failures)
	_expect(int(attack_result.damage) == 4, "base attack damage remains four", failures)
	_expect(attack_result.get("skill_results", []).size() == 1, "combo produces one skill result", failures)
	var combo_result: Dictionary = attack_result.skill_results[0]
	_expect(str(combo_result.get("skill_id", "")) == "sunshangxiang_combo", "combo skill result id is present", failures)
	_expect(int(combo_result.get("bonus_damage", 0)) == 2, "combo adds two bonus damage", failures)
	_expect(int(target.hp) == 4, "target HP includes base and combo damage", failures)


func _check_combo_skips_defeated_target(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var sunshangxiang: Dictionary = _add_unit(state, "finisher", "left", 4, 3, {
		"hero_id": "sunshangxiang",
		"name": "孙尚香",
		"attack": 4,
		"range": 4,
		"skill_ids": ["sunshangxiang_combo"],
	})
	_add_unit(state, "low_hp_target", "right", 7, 3, {"hp": 3, "max_hp": 3})
	var attack_result: Dictionary = MovementSystemScript.act_unit(state, sunshangxiang)
	_expect(attack_result.damage == 4, "base attack defeats low HP target", failures)
	_expect(attack_result.get("skill_results", []).size() == 1, "combo still reports one skill attempt", failures)
	var combo_result: Dictionary = attack_result.skill_results[0]
	_expect(not bool(combo_result.get("ok", false)), "combo does not damage already defeated target", failures)
	_expect(str(combo_result.get("reason", "")) == "missing_target", "defeated target is reported as missing", failures)


func _check_battle_screen_detail_and_log_text(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.selected_hero_id = "sunshangxiang"
	screen._deploy_selected_to_cell(2, 2)
	await process_frame
	screen._deploy_selected_to_cell(2, 2)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "Sunshangxiang detail panel opens", failures)
	_expect(screen.unit_detail_body.text.find("枭姬连弩") >= 0, "Sunshangxiang detail shows combo skill name", failures)
	var summary: String = screen._skill_result_summary({
		"ok": true,
		"skill_id": "sunshangxiang_combo",
		"target_id": "unit_test",
		"bonus_damage": 2,
	})
	_expect(summary.find("枭姬连弩") >= 0, "combo log summary includes skill name", failures)
	_expect(summary.find("追加 2 点伤害") >= 0, "combo log summary includes bonus damage", failures)
	screen.queue_free()


func _find_skill(state, skill_id: String) -> Dictionary:
	for skill_def: Dictionary in state.get_skill_defs():
		if str(skill_def.get("id", "")) == skill_id:
			return skill_def
	return {}


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
	return result.unit


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)