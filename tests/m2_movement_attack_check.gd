extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const TargetingSystemScript: GDScript = preload("res://scripts/battle/TargetingSystem.gd")


func _init() -> void:
	var failures: Array[String] = []

	_check_front_to_back_order(failures)
	_check_blocked_movement(failures)
	_check_attack_before_move(failures)
	_check_attack_shape_targeting(failures)
	_check_master_attack(failures)

	if failures.is_empty():
		print("M2 movement and attack checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_front_to_back_order(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var rear: Dictionary = _add_unit(state, "rear", "left", 2, 2)
	var front: Dictionary = _add_unit(state, "front", "left", 5, 4)
	var same_column_first: Dictionary = _add_unit(state, "same_first", "left", 5, 1)
	var ordered: Array = MovementSystemScript.get_units_in_action_order(state, "left")
	_expect(ordered[0].instance_id == same_column_first.instance_id, "same front column uses lower row first", failures)
	_expect(ordered[1].instance_id == front.instance_id, "left side higher column acts before rear", failures)
	_expect(ordered[2].instance_id == rear.instance_id, "rear unit acts after front units", failures)


func _check_blocked_movement(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var mover: Dictionary = _add_unit(state, "mover", "left", 2, 3, {"move": 3})
	_add_unit(state, "blocker", "left", 3, 3)
	var result: Dictionary = MovementSystemScript.move_unit_forward(state, mover)
	_expect(result.steps == 0, "non-assassin stops at first occupied forward cell", failures)
	_expect(int(mover.column) == 2 and int(mover.row) == 3, "blocked unit remains in place", failures)

	var assassin: Dictionary = _add_unit(state, "assassin", "left", 2, 4, {"class": "assassin", "move": 3})
	_add_unit(state, "assassin_blocker", "right", 3, 4)
	var assassin_result: Dictionary = MovementSystemScript.move_unit_forward(state, assassin)
	_expect(assassin_result.steps == 0, "assassin stops at occupied forward cell", failures)
	_expect(int(assassin.column) == 2 and int(assassin.row) == 4, "assassin does not pass blockers", failures)


func _check_attack_before_move(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var attacker: Dictionary = _add_unit(state, "attacker", "left", 4, 2, {"attack": 3, "range": 1, "move": 3})
	var target: Dictionary = _add_unit(state, "target", "right", 5, 2, {"hp": 6})
	var result: Dictionary = MovementSystemScript.act_unit(state, attacker)
	_expect(result.action == "attack" and result.target_id == target.instance_id, "unit attacks in-range enemy before moving", failures)
	_expect(int(attacker.column) == 4, "attack-before-move keeps attacker in place", failures)
	_expect(int(target.hp) == 3, "attack applies damage to target unit", failures)


func _check_attack_shape_targeting(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var melee: Dictionary = _add_unit(state, "melee", "left", 5, 3, {"class": "warrior", "range": 3})
	var off_row: Dictionary = _add_unit(state, "off_row", "right", 6, 4)
	var same_row: Dictionary = _add_unit(state, "same_row", "right", 7, 3)
	var melee_selected: Dictionary = TargetingSystemScript.select_target(melee, state.get_enemy_units("left"))
	_expect(melee_selected.instance_id == same_row.instance_id, "melee attacks same-row target instead of closer adjacent-row target", failures)
	_expect(melee_selected.instance_id != off_row.instance_id, "melee ignores off-row target", failures)

	var ranged_state = BattleStateScript.new()
	var ranged: Dictionary = _add_unit(ranged_state, "ranged", "left", 5, 3, {"class": "archer", "range": 3})
	var adjacent_row: Dictionary = _add_unit(ranged_state, "adjacent_row", "right", 6, 4)
	var out_of_rows: Dictionary = _add_unit(ranged_state, "out_of_rows", "right", 6, 5)
	var far_same_row: Dictionary = _add_unit(ranged_state, "far_same_row", "right", 7, 3)
	var ranged_selected: Dictionary = TargetingSystemScript.select_target(ranged, ranged_state.get_enemy_units("left"))
	_expect(ranged_selected.instance_id == adjacent_row.instance_id, "ranged unit can attack adjacent row and picks nearest target", failures)
	_expect(ranged_selected.instance_id != out_of_rows.instance_id, "ranged unit ignores targets outside three-row band", failures)
	_expect(ranged_selected.instance_id != far_same_row.instance_id, "ranged nearest target wins over farther same-row target", failures)


func _check_master_attack(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var attacker: Dictionary = _add_unit(state, "master_hitter", "left", 10, 2, {"attack": 4, "range": 1})
	var result: Dictionary = MovementSystemScript.act_unit(state, attacker)
	_expect(result.target_type == "master", "unit attacks master when no enemy unit blocks", failures)
	_expect(state.get_master_hp("right") == 26, "master HP takes full attack damage", failures)

	var blocked_state = BattleStateScript.new()
	var blocked_attacker: Dictionary = _add_unit(blocked_state, "blocked_master_hitter", "left", 9, 2, {"attack": 4, "range": 1})
	_add_unit(blocked_state, "enemy_blocker", "right", 10, 2)
	var blocked_result: Dictionary = MovementSystemScript.act_unit(blocked_state, blocked_attacker)
	_expect(blocked_result.target_type != "master", "enemy unit in attack range prevents master attack", failures)


func _add_unit(state, unit_id: String, side: String, column: int, row: int, overrides: Dictionary = {}) -> Dictionary:
	var unit_data := {
		"instance_id": unit_id,
		"entry_order": state.next_unit_sequence,
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
	}
	for key in overrides:
		unit_data[key] = overrides[key]
	var result: Dictionary = state.create_unit_instance(unit_data, side, column, row)
	return result.get("unit", {})


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
