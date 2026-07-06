extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")


func _init() -> void:
	var failures: Array[String] = []

	_check_guanyu_growth(failures)
	_check_zhouyu_burn_damage_and_expiry(failures)
	_check_zhangjiao_summons_empty_cells_only(failures)
	_check_m1_to_m4_regressions(failures)

	if failures.is_empty():
		print("M5 skill sample checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_guanyu_growth(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var deploy_result: Dictionary = state.deploy_hero("guanyu", "left", 2, 3)
	var guanyu: Dictionary = deploy_result.get("unit", {})
	guanyu["hp"] = 5

	var turns = TurnControllerScript.new(state, "left")
	var start_result: Dictionary = turns.start_side_turn()
	_expect(start_result.skill_results.size() == 1, "turn_start skill triggers for Guanyu", failures)
	_expect(int(guanyu.attack) == 5, "Guanyu gains attack +1", failures)
	_expect(int(guanyu.max_hp) == 11, "Guanyu gains max HP +3", failures)
	_expect(int(guanyu.hp) == 8, "Guanyu heals 3 capped by max HP", failures)


func _check_zhouyu_burn_damage_and_expiry(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var zhouyu: Dictionary = _add_unit(state, "zhouyu_unit", "left", 4, 3, {
		"hero_id": "zhouyu",
		"attack": 3,
		"range": 3,
		"damage_type": "magic",
		"skill_ids": ["zhouyu_burn"],
	})
	var target: Dictionary = _add_unit(state, "target", "right", 6, 3, {"hp": 10, "max_hp": 10})

	var attack_result: Dictionary = MovementSystemScript.act_unit(state, zhouyu)
	_expect(attack_result.damage == 3, "Zhouyu attack still deals normal damage", failures)
	_expect(target.get("statuses", {}).has("burn"), "Zhouyu applies burn on attack hit", failures)

	var status_results: Array = state.process_end_turn_statuses()
	_expect(status_results.size() == 1 and status_results[0].damage == 3, "burn deals 3 damage at turn end", failures)
	_expect(int(target.hp) == 4, "target HP includes attack and burn damage", failures)
	_expect(not target.get("statuses", {}).has("burn"), "burn expires after processing", failures)


func _check_zhangjiao_summons_empty_cells_only(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	_add_unit(state, "occupied_a", "left", 3, 3)
	_add_unit(state, "occupied_b", "left", 2, 2)
	state.set_star_power("left", 10)

	var deploy_result: Dictionary = state.deploy_hero("zhangjiao", "left", 2, 3)
	_expect(deploy_result.ok, "Zhangjiao deployment succeeds", failures)

	var summons: Array = []
	for unit: Dictionary in state.get_units_by_side("left"):
		if str(unit.get("hero_id", "")) == "yellow_turban":
			summons.append(unit)

	_expect(summons.size() == 2, "Zhangjiao summons only into adjacent empty cells", failures)
	_expect(state.board.is_occupied(1, 3), "left adjacent empty cell receives summon", failures)
	_expect(state.board.is_occupied(2, 4), "lower adjacent empty cell receives summon", failures)
	_expect(str(state.board.get_unit_at(3, 3).hero_id) != "yellow_turban", "occupied adjacent cell is not replaced", failures)


func _check_m1_to_m4_regressions(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var deploy_result: Dictionary = state.deploy_hero("guanyu", "left", 2, 3)
	_expect(deploy_result.ok, "M1 valid deployment still succeeds", failures)
	_expect(state.get_star_power("left") == 0, "M1 deployment cost still spends star power", failures)

	var movement_state = BattleStateScript.new()
	var attacker: Dictionary = _add_unit(movement_state, "attacker", "left", 4, 2, {"attack": 3, "range": 1, "move": 3})
	var target: Dictionary = _add_unit(movement_state, "target", "right", 5, 2, {"hp": 6})
	var attack_result: Dictionary = MovementSystemScript.act_unit(movement_state, attacker)
	_expect(attack_result.action == "attack" and int(target.hp) == 3, "M2 attack-before-move still works", failures)

	var turn_state = BattleStateScript.new()
	var turns = TurnControllerScript.new(turn_state, "left")
	turns.start_side_turn()
	turns.end_side_turn()
	_expect(turns.current_side == "right" and turns.turn_number == 1, "M3 side switching still works", failures)

	var terrain_state = BattleStateScript.new()
	terrain_state.terrain_system.set_terrain(5, 3, "river")
	_expect(terrain_state.terrain_system.get_terrain(5, 3) == "river", "M4 terrain assignment still works", failures)


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

