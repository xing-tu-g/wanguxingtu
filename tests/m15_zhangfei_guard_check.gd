extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	_check_zhangfei_data_and_passive_text(failures)
	_check_adjacent_guard_reduces_non_true_damage(failures)
	_check_guard_requires_adjacency_and_living_guardian(failures)
	_check_battle_screen_detail_text(failures)
	await process_frame

	if failures.is_empty():
		print("M15 Zhangfei guard checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_zhangfei_data_and_passive_text(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var zhangfei: Dictionary = state.get_hero_def("zhangfei")
	_expect(zhangfei.get("skill_ids", []).has("zhangfei_guard"), "Zhangfei uses the guard skill id", failures)
	var guard_skill := _find_skill(state, "zhangfei_guard")
	_expect(str(guard_skill.get("name", "")) == "燕人守护", "Zhangfei guard skill has Chinese name", failures)
	_expect(str(guard_skill.get("description", "")).find("相邻友军") >= 0, "Zhangfei guard description explains adjacency", failures)
	_expect(int(guard_skill.get("params", {}).get("damage_reduction", 0)) == 2, "Zhangfei guard reduces damage by two", failures)


func _check_adjacent_guard_reduces_non_true_damage(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var target: Dictionary = _add_unit(state, "protected_ally", "left", 4, 3, {"hp": 10, "max_hp": 10})
	_add_unit(state, "zhangfei_guardian", "left", 4, 4, {"hero_id": "zhangfei", "name": "张飞", "skill_ids": ["zhangfei_guard"]})
	var physical_damage: int = state.apply_damage_to_unit(target, 5, "physical")
	_expect(physical_damage == 3, "adjacent Zhangfei reduces physical damage by two", failures)
	_expect(int(target.hp) == 7, "protected ally loses reduced physical damage", failures)

	var magic_damage: int = state.apply_damage_to_unit(target, 4, "magic")
	_expect(magic_damage == 2, "adjacent Zhangfei reduces magic damage by two", failures)
	_expect(int(target.hp) == 5, "protected ally loses reduced magic damage", failures)

	var true_damage: int = state.apply_damage_to_unit(target, 3, "true")
	_expect(true_damage == 3, "guard does not reduce true damage", failures)
	_expect(int(target.hp) == 2, "true damage bypasses guard reduction", failures)


func _check_guard_requires_adjacency_and_living_guardian(failures: Array[String]) -> void:
	var distant_state = BattleStateScript.new()
	var distant_target: Dictionary = _add_unit(distant_state, "distant_target", "left", 4, 3, {"hp": 10, "max_hp": 10})
	_add_unit(distant_state, "distant_guardian", "left", 6, 3, {"skill_ids": ["zhangfei_guard"]})
	var distant_damage: int = distant_state.apply_damage_to_unit(distant_target, 5, "physical")
	_expect(distant_damage == 5, "non-adjacent Zhangfei does not reduce damage", failures)

	var dead_state = BattleStateScript.new()
	var dead_target: Dictionary = _add_unit(dead_state, "dead_guard_target", "left", 4, 3, {"hp": 10, "max_hp": 10})
	_add_unit(dead_state, "dead_guardian", "left", 4, 4, {"hp": 0, "max_hp": 10, "skill_ids": ["zhangfei_guard"]})
	var dead_guard_damage: int = dead_state.apply_damage_to_unit(dead_target, 5, "physical")
	_expect(dead_guard_damage == 5, "defeated Zhangfei does not reduce damage", failures)


func _check_battle_screen_detail_text(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.selected_hero_id = "zhangfei"
	screen._deploy_selected_to_cell(2, 2)
	await process_frame
	screen._deploy_selected_to_cell(2, 2)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "Zhangfei detail panel opens", failures)
	_expect(screen.unit_detail_body.text.find("燕人守护") >= 0, "Zhangfei detail shows guard skill name", failures)
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