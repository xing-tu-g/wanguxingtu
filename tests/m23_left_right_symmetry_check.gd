extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const TargetingSystemScript: GDScript = preload("res://scripts/battle/TargetingSystem.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")

const MVP_HERO_IDS := ["guanyu", "zhaoyun", "sunshangxiang", "zhangfei", "zhouyu", "zhangjiao"]


func _init() -> void:
	var failures: Array[String] = []
	_check_deployment_columns_are_mirrored(failures)
	_check_forward_movement_is_mirrored(failures)
	_check_action_order_is_mirrored(failures)
	_check_target_selection_is_mirrored(failures)
	_check_master_attack_is_mirrored(failures)
	_check_m22_hero_pools_are_consistent(failures)
	await process_frame

	if failures.is_empty():
		print("M23 left/right symmetry checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_deployment_columns_are_mirrored(failures: Array[String]) -> void:
	_expect(_mirror_columns([1, 2, 3]) == [10, 9, 8], "left deployment zone mirrors right deployment zone", failures)
	_expect(_mirror_columns([3, 2, 1]) == [8, 9, 10], "front-first left deployment scan mirrors front-first right scan", failures)


func _check_forward_movement_is_mirrored(failures: Array[String]) -> void:
	var left_state = BattleStateScript.new()
	var right_state = BattleStateScript.new()
	left_state.terrain_system.generate_deterministic(1)
	right_state.terrain_system.generate_deterministic(1)

	var left_unit: Dictionary = _deploy(left_state, "guanyu", BoardModelScript.SIDE_LEFT, 3, 3)
	var right_unit: Dictionary = _deploy(right_state, "guanyu", BoardModelScript.SIDE_RIGHT, 8, 3)
	var left_move: Dictionary = MovementSystemScript.move_unit_forward(left_state, left_unit)
	var right_move: Dictionary = MovementSystemScript.move_unit_forward(right_state, right_unit)

	_expect(_cell_from(left_move.get("to", Vector2i.ZERO)) == Vector2i(6, 3), "left unit moves forward toward higher columns", failures)
	_expect(_cell_from(right_move.get("to", Vector2i.ZERO)) == Vector2i(5, 3), "right unit moves forward toward lower columns", failures)
	_expect(_mirror_cell(_cell_from(left_move.get("to", Vector2i.ZERO))) == _cell_from(right_move.get("to", Vector2i.ZERO)), "forward movement endpoints are mirrored", failures)
	_expect(int(left_move.get("steps", 0)) == int(right_move.get("steps", 0)), "mirrored movement spends equal steps", failures)


func _check_action_order_is_mirrored(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.create_unit_instance(state.build_unit_data("guanyu", state.get_hero_def("guanyu")), BoardModelScript.SIDE_LEFT, 1, 2)
	state.create_unit_instance(state.build_unit_data("zhouyu", state.get_hero_def("zhouyu")), BoardModelScript.SIDE_LEFT, 3, 1)
	state.create_unit_instance(state.build_unit_data("zhangfei", state.get_hero_def("zhangfei")), BoardModelScript.SIDE_RIGHT, 10, 2)
	state.create_unit_instance(state.build_unit_data("zhaoyun", state.get_hero_def("zhaoyun")), BoardModelScript.SIDE_RIGHT, 8, 1)

	var left_order: Array = MovementSystemScript.get_units_in_action_order(state, BoardModelScript.SIDE_LEFT)
	var right_order: Array = MovementSystemScript.get_units_in_action_order(state, BoardModelScript.SIDE_RIGHT)
	_expect(str(left_order[0].get("hero_id", "")) == "zhouyu", "left front unit acts before back unit", failures)
	_expect(str(right_order[0].get("hero_id", "")) == "zhaoyun", "right front unit acts before back unit", failures)
	_expect(int(left_order[0].get("column", 0)) == _mirror_column(int(right_order[0].get("column", 0))), "front action priority is mirrored by column", failures)


func _check_target_selection_is_mirrored(failures: Array[String]) -> void:
	var left_attacker := _unit_literal(BoardModelScript.SIDE_LEFT, 4, 3, 3, 1, 1)
	var left_close := _unit_literal(BoardModelScript.SIDE_RIGHT, 6, 3, 4, 1, 2)
	var left_far := _unit_literal(BoardModelScript.SIDE_RIGHT, 7, 3, 2, 1, 3)
	var right_attacker := _unit_literal(BoardModelScript.SIDE_RIGHT, 7, 3, 3, 1, 1)
	var right_close := _unit_literal(BoardModelScript.SIDE_LEFT, 5, 3, 4, 1, 2)
	var right_far := _unit_literal(BoardModelScript.SIDE_LEFT, 4, 3, 2, 1, 3)

	var left_target: Dictionary = TargetingSystemScript.select_target(left_attacker, [left_far, left_close])
	var right_target: Dictionary = TargetingSystemScript.select_target(right_attacker, [right_far, right_close])
	_expect(int(left_target.get("column", 0)) == 6, "left target priority selects nearest/front enemy column", failures)
	_expect(int(right_target.get("column", 0)) == 5, "right target priority selects mirrored nearest/front enemy column", failures)
	_expect(_mirror_column(int(left_target.get("column", 0))) == int(right_target.get("column", 0)), "target priority columns are mirrored", failures)


func _check_master_attack_is_mirrored(failures: Array[String]) -> void:
	var left_attacker := _unit_literal(BoardModelScript.SIDE_LEFT, 10, 3, 3, 1, 1)
	var right_attacker := _unit_literal(BoardModelScript.SIDE_RIGHT, 1, 3, 3, 1, 1)
	_expect(TargetingSystemScript.can_attack_master(left_attacker, []), "left unit can attack right master from mirrored edge", failures)
	_expect(TargetingSystemScript.can_attack_master(right_attacker, []), "right unit can attack left master from mirrored edge", failures)


func _check_m22_hero_pools_are_consistent(failures: Array[String]) -> void:
	var m22_script := FileAccess.get_file_as_string("res://tests/m22_pacing_multi_sample_check.gd")
	var expected := "const ENEMY_DEFAULT_IDS := HERO_IDS"
	_expect(m22_script.contains(expected), "M22 uses the same MVP hero pool order for both sides before comparing side advantage", failures)


func _deploy(state, hero_id: String, side: String, column: int, row: int) -> Dictionary:
	state.set_star_power(side, 10)
	var result: Dictionary = state.deploy_hero(hero_id, side, column, row)
	assert(bool(result.get("ok", false)), "test deployment must succeed")
	return result.get("unit", {})


func _unit_literal(side: String, column: int, row: int, attack_range: int, hp: int, entry_order: int) -> Dictionary:
	return {
		"side": side,
		"column": column,
		"row": row,
		"range": attack_range,
		"hp": hp,
		"entry_order": entry_order,
	}


func _mirror_columns(columns: Array) -> Array[int]:
	var mirrored: Array[int] = []
	for column_value in columns:
		mirrored.append(_mirror_column(int(column_value)))
	return mirrored


func _mirror_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(_mirror_column(cell.x), cell.y)


func _mirror_column(column: int) -> int:
	return BoardModelScript.COLUMNS + 1 - column


func _cell_from(value) -> Vector2i:
	if value is Vector2i:
		return value
	return Vector2i.ZERO


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
