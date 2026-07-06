extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	_check_zhaoyun_data_and_passive_text(failures)
	_check_zhaoyun_stops_at_blockers(failures)
	_check_zhaoyun_fixed_bonus_damage(failures)
	_check_battle_screen_detail_text(failures)
	await process_frame

	if failures.is_empty():
		print("M14 Zhaoyun dash checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_zhaoyun_data_and_passive_text(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var zhaoyun: Dictionary = state.get_hero_def("zhaoyun")
	_expect(not bool(zhaoyun.get("can_pass_blockers", false)), "Zhaoyun no longer has blocker-pass movement trait", failures)
	_expect(zhaoyun.get("skill_ids", []).has("zhaoyun_dash"), "Zhaoyun uses the dash skill id", failures)
	var dash_skill := _find_skill(state, "zhaoyun_dash")
	_expect(str(dash_skill.get("name", "")).length() > 0, "Zhaoyun dash skill has display name", failures)
	_expect(str(dash_skill.get("description", "")).length() > 0, "Zhaoyun dash skill has description", failures)
	_expect(str(dash_skill.get("trigger", "")) == "attack_hit", "Zhaoyun dash triggers on attack hit", failures)
	_expect(str(dash_skill.get("effect_type", "")) == "bonus_damage", "Zhaoyun dash uses fixed bonus damage", failures)
	_expect(int(dash_skill.get("params", {}).get("damage", 0)) == 1, "Zhaoyun dash adds fixed 1 damage", failures)


func _check_zhaoyun_stops_at_blockers(failures: Array[String]) -> void:
	var zhaoyun_state = BattleStateScript.new()
	var zhaoyun_def: Dictionary = zhaoyun_state.get_hero_def("zhaoyun")
	var zhaoyun_data: Dictionary = zhaoyun_state.build_unit_data("zhaoyun", zhaoyun_def)
	zhaoyun_data["instance_id"] = "zhaoyun_unit"
	zhaoyun_data["entry_order"] = zhaoyun_state.next_unit_sequence
	var zhaoyun: Dictionary = zhaoyun_state.create_unit_instance(zhaoyun_data, "left", 2, 3).get("unit", {})
	_add_unit(zhaoyun_state, "front_blocker", "left", 3, 3)
	var zhaoyun_result: Dictionary = MovementSystemScript.move_unit_forward(zhaoyun_state, zhaoyun)
	_expect(zhaoyun_result.steps == 0, "Zhaoyun stops at a forward blocker", failures)
	_expect(int(zhaoyun.column) == 2 and int(zhaoyun.row) == 3, "Zhaoyun remains before the occupied blocker", failures)
	_expect(str(zhaoyun_state.board.get_unit_at(3, 3).instance_id) == "front_blocker", "blocker remains on original cell", failures)

	var baseline_state = BattleStateScript.new()
	var baseline: Dictionary = _add_unit(baseline_state, "baseline", "left", 2, 3, {"move": 4})
	_add_unit(baseline_state, "baseline_blocker", "left", 3, 3)
	var baseline_result: Dictionary = MovementSystemScript.move_unit_forward(baseline_state, baseline)
	_expect(baseline_result.steps == 0, "normal warrior still stops at blocker", failures)
	_expect(int(baseline.column) == 2, "normal warrior remains before blocker", failures)


func _check_zhaoyun_fixed_bonus_damage(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var zhaoyun_def: Dictionary = state.get_hero_def("zhaoyun")
	var zhaoyun_data: Dictionary = state.build_unit_data("zhaoyun", zhaoyun_def)
	zhaoyun_data["instance_id"] = "zhaoyun_unit"
	var zhaoyun: Dictionary = state.create_unit_instance(zhaoyun_data, "left", 4, 3).get("unit", {})
	var target: Dictionary = _add_unit(state, "target", "right", 5, 3, {"hp": 10, "max_hp": 10})
	var result: Dictionary = MovementSystemScript.act_unit(state, zhaoyun)
	_expect(result.action == "attack", "Zhaoyun attacks same-row target", failures)
	_expect(int(result.get("damage", 0)) == int(zhaoyun.get("attack", 0)), "Zhaoyun base attack damage is reported separately", failures)
	_expect(result.get("skill_results", []).size() == 1, "Zhaoyun dash emits one attack-hit skill result", failures)
	_expect(int(result.get("skill_results", [])[0].get("bonus_damage", 0)) == 1, "Zhaoyun dash applies fixed +1 damage", failures)
	_expect(int(target.get("hp", 0)) == 10 - int(zhaoyun.get("attack", 0)) - 1, "Zhaoyun target HP includes fixed bonus damage", failures)


func _check_battle_screen_detail_text(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.selected_hero_id = "zhaoyun"
	screen._deploy_selected_to_cell(2, 2)
	await process_frame
	screen._deploy_selected_to_cell(2, 2)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "Zhaoyun detail panel opens", failures)
	_expect(screen.unit_detail_body.text.length() > 0, "Zhaoyun detail shows unit text", failures)
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
	return result.get("unit", {})


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
