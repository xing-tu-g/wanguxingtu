extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	_check_zhaoyun_data_and_passive_text(failures)
	_check_zhaoyun_passes_blockers(failures)
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
	_expect(bool(zhaoyun.get("can_pass_blockers", false)), "Zhaoyun keeps blocker-pass movement trait", failures)
	_expect(zhaoyun.get("skill_ids", []).has("zhaoyun_dash"), "Zhaoyun uses the dash skill id", failures)
	var dash_skill := _find_skill(state, "zhaoyun_dash")
	_expect(str(dash_skill.get("name", "")) == "龙胆突进", "Zhaoyun dash skill has Chinese name", failures)
	_expect(str(dash_skill.get("description", "")).find("穿过前方阻挡单位") >= 0, "Zhaoyun dash description explains blocker pass", failures)


func _check_zhaoyun_passes_blockers(failures: Array[String]) -> void:
	var zhaoyun_state = BattleStateScript.new()
	var zhaoyun_def: Dictionary = zhaoyun_state.get_hero_def("zhaoyun")
	var zhaoyun_data: Dictionary = zhaoyun_state.build_unit_data("zhaoyun", zhaoyun_def)
	zhaoyun_data["instance_id"] = "zhaoyun_unit"
	zhaoyun_data["entry_order"] = zhaoyun_state.next_unit_sequence
	var zhaoyun: Dictionary = zhaoyun_state.create_unit_instance(zhaoyun_data, "left", 2, 3).unit
	_add_unit(zhaoyun_state, "front_blocker", "left", 3, 3)
	var zhaoyun_result: Dictionary = MovementSystemScript.move_unit_forward(zhaoyun_state, zhaoyun)
	_expect(zhaoyun_result.steps == 4, "Zhaoyun spends full move while passing blocker", failures)
	_expect(int(zhaoyun.column) == 6 and int(zhaoyun.row) == 3, "Zhaoyun lands beyond the occupied blocker", failures)
	_expect(str(zhaoyun_state.board.get_unit_at(3, 3).instance_id) == "front_blocker", "blocker remains on original cell", failures)

	var baseline_state = BattleStateScript.new()
	var baseline: Dictionary = _add_unit(baseline_state, "baseline", "left", 2, 3, {"move": 4})
	_add_unit(baseline_state, "baseline_blocker", "left", 3, 3)
	var baseline_result: Dictionary = MovementSystemScript.move_unit_forward(baseline_state, baseline)
	_expect(baseline_result.steps == 0, "normal warrior still stops at blocker", failures)
	_expect(int(baseline.column) == 2, "normal warrior remains before blocker", failures)


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
	_expect(screen.unit_detail_body.text.find("龙胆突进") >= 0, "Zhaoyun detail shows dash skill name", failures)
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