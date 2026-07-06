extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")


func _init() -> void:
	var failures: Array[String] = []

	_check_initial_star_power(failures)
	_check_side_switching(failures)
	_check_restore_cap(failures)
	_check_star_tide_restore_after_three_rounds(failures)
	_check_master_damage_bonus_at_round_eight(failures)
	_check_m1_m2_compatibility(failures)

	if failures.is_empty():
		print("M3 turn flow checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_star_power(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	_expect(state.get_star_power("left") == 5, "first side initial star power is 5", failures)
	_expect(state.get_star_power("right") == 6, "second side initial star power is 6", failures)


func _check_side_switching(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var turns = TurnControllerScript.new(state, "left")
	_expect(turns.current_side == "left", "first side starts current", failures)
	turns.start_side_turn()
	turns.end_side_turn()
	_expect(turns.current_side == "right", "ending first side switches to second side", failures)
	_expect(turns.turn_number == 1, "round does not advance until second side ends", failures)
	turns.start_side_turn()
	turns.end_side_turn()
	_expect(turns.current_side == "left", "ending second side switches back to first side", failures)
	_expect(turns.turn_number == 2, "round advances after both sides act", failures)
	_expect(turns.side_turns == 2, "side turn counter increments per side turn", failures)


func _check_restore_cap(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.set_star_power("left", 9)
	var turns = TurnControllerScript.new(state, "left")
	var result: Dictionary = turns.start_side_turn()
	_expect(result.star_restore == 2, "base restore is 2 before star tide", failures)
	_expect(state.get_star_power("left") == 10, "star restore is capped at 10", failures)


func _check_star_tide_restore_after_three_rounds(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var turns = TurnControllerScript.new(state, "left")
	for round_index in range(3):
		turns.start_side_turn()
		turns.end_side_turn()
		turns.start_side_turn()
		turns.end_side_turn()
	_expect(turns.turn_number == 4, "three complete rounds advance to round 4", failures)
	_expect(turns.get_star_tide_restore_bonus() == 1, "star tide restore bonus increases after three complete rounds", failures)
	_expect(turns.get_star_restore_amount() == 3, "future star restore is base 2 plus tide bonus 1", failures)


func _check_master_damage_bonus_at_round_eight(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var turns = TurnControllerScript.new(state, "left")
	turns.turn_number = 8
	state.star_tide_master_damage_bonus = turns.get_star_tide_master_damage_bonus()
	var applied_damage: int = state.apply_master_damage("right", 4)
	_expect(turns.get_star_tide_master_damage_bonus() == 1, "round 8 star tide master damage bonus is 1", failures)
	_expect(applied_damage == 5, "master damage includes round 8 star tide bonus", failures)
	_expect(state.get_master_hp("right") == 25, "master HP reflects damage plus tide bonus", failures)


func _check_m1_m2_compatibility(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var deploy_result: Dictionary = state.deploy_hero("guanyu", "left", 2, 3)
	_expect(deploy_result.ok, "M1 valid deployment still succeeds", failures)
	_expect(state.get_star_power("left") == 0, "M1 deployment cost still spends star power", failures)

	var movement_state = BattleStateScript.new()
	var attacker: Dictionary = _add_unit(movement_state, "attacker", "left", 10, 2, {"attack": 4, "range": 1})
	var move_result: Dictionary = MovementSystemScript.act_unit(movement_state, attacker)
	_expect(move_result.target_type == "master", "M2 master targeting still works without controller", failures)
	_expect(movement_state.get_master_hp("right") == 26, "M2 direct movement damage has no tide bonus by default", failures)


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

