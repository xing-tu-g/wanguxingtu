extends RefCounted
class_name MovementSystem

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const TargetingSystemScript: GDScript = preload("res://scripts/battle/TargetingSystem.gd")
const BattleAIScript: GDScript = preload("res://scripts/battle/BattleAI.gd")
const AttackShapeSystemScript: GDScript = preload("res://scripts/battle/AttackShapeSystem.gd")

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const DAMAGE_TARGET_UNIT := "unit"
const DAMAGE_TARGET_MASTER := "master"

static func get_units_in_action_order(state, side: String) -> Array:
	var units: Array = state.get_units_by_side(side)
	units.sort_custom(func(left_unit: Dictionary, right_unit: Dictionary) -> bool:
		return _compare_action_order(side, left_unit, right_unit)
	)
	return units

static func act_side(state, side: String) -> Array:
	var results: Array = []
	for unit: Dictionary in get_units_in_action_order(state, side):
		if int(unit.get("hp", 0)) > 0:
			results.append(act_unit(state, unit))
	return results

static func act_unit(state, unit: Dictionary) -> Dictionary:
	if _is_stunned(unit):
		return {"action": "stunned", "move": _stationary_result(unit), "reason": "stunned"}

	var enemy_units: Array = state.get_enemy_units(str(unit.get("side", "")))
	var target: Dictionary = TargetingSystemScript.select_target(unit, enemy_units, state.terrain_system)
	if not target.is_empty():
		return _attack_unit(state, unit, target)

	var move_result: Dictionary = {}
	move_result = move_unit_forward(state, unit)
	enemy_units = state.get_enemy_units(str(unit.get("side", "")))
	target = TargetingSystemScript.select_target(unit, enemy_units, state.terrain_system)
	if not target.is_empty():
		var attack_result := _attack_unit(state, unit, target)
		attack_result["move"] = move_result
		return attack_result

	if TargetingSystemScript.can_attack_master(unit, enemy_units, state.terrain_system):
		var enemy_side: String = state.get_enemy_side(str(unit.get("side", "")))
		var damage: int = state.apply_master_damage(enemy_side, state.get_unit_attack(unit), -1, unit)
		return {
			"action": "attack",
			"target_type": DAMAGE_TARGET_MASTER,
			"damage": damage,
			"move": move_result,
		}

	return {"action": "move", "move": move_result}

static func move_unit_forward(state, unit: Dictionary) -> Dictionary:
	var move_value: int = mini(1, state.get_unit_move(unit))
	if move_value <= 0:
		return {"ok": true, "from": _unit_position(unit), "to": _unit_position(unit), "steps": 0}

	var direction := _forward_direction(str(unit.get("side", "")))
	var origin_column := int(unit.get("column", 0))
	var origin_row := int(unit.get("row", 0))
	var final_column := origin_column

	var movement_spent := 0
	for step in range(1, move_value + 1):
		var next_column := origin_column + (direction * step)
		if not state.board.is_in_bounds(next_column, origin_row):
			break

		if state.board.is_occupied(next_column, origin_row):
			break

		var movement_cost: int = state.get_movement_cost(unit, next_column, origin_row)
		if movement_spent + movement_cost > move_value:
			break
		movement_spent += movement_cost
		final_column = next_column

	if final_column == origin_column:
		return {"ok": true, "from": Vector2i(origin_column, origin_row), "to": Vector2i(origin_column, origin_row), "steps": 0}

	var result: Dictionary = state.move_unit(unit, final_column, origin_row)
	result["from"] = Vector2i(origin_column, origin_row)
	result["to"] = Vector2i(final_column, origin_row)
	result["steps"] = absi(final_column - origin_column)
	result["movement_spent"] = movement_spent
	if result.get("ok", false):
		var moved_unit: Dictionary = result.get("unit", unit)
		pass  # EventBus emit moved to BattleScreen
	return result

static func _attack_unit(state, attacker: Dictionary, target: Dictionary) -> Dictionary:
	var target_snapshot := target.duplicate(true)
	var backstab_bonus := AttackShapeSystemScript.ASSASSIN_BACKSTAB_BONUS_DAMAGE if AttackShapeSystemScript.is_backstab_target(attacker, target) else 0
	var damage: int = state.apply_damage_to_unit(target, state.get_unit_attack(attacker) + backstab_bonus, str(attacker.get("damage_type", "physical")), attacker)
	var skill_results: Array = state.trigger_skill_event("attack_hit", {
		"source_unit": attacker,
		"target_unit": target,
		"damage": damage,
	})
	return {
		"action": "attack",
		"target_type": DAMAGE_TARGET_UNIT,
		"target_id": str(target.get("instance_id", "")),
		"target_snapshot": target_snapshot,
		"damage": damage,
		"backstab_bonus_damage": backstab_bonus,
		"skill_results": skill_results,
	}

static func _compare_action_order(side: String, left_unit: Dictionary, right_unit: Dictionary) -> bool:
	var left_column := int(left_unit.get("column", 0))
	var right_column := int(right_unit.get("column", 0))
	if left_column != right_column:
		if side == SIDE_LEFT:
			return left_column > right_column
		return left_column < right_column

	var left_row := int(left_unit.get("row", 0))
	var right_row := int(right_unit.get("row", 0))
	if left_row != right_row:
		return left_row < right_row

	return int(left_unit.get("entry_order", 0)) < int(right_unit.get("entry_order", 0))

static func _forward_direction(side: String) -> int:
	if side == SIDE_RIGHT:
		return -1
	return 1

static func _unit_position(unit: Dictionary) -> Vector2i:
	return Vector2i(int(unit.get("column", 0)), int(unit.get("row", 0)))


static func _stationary_result(unit: Dictionary) -> Dictionary:
	var position := _unit_position(unit)
	return {"ok": true, "from": position, "to": position, "steps": 0}


static func _is_stunned(unit: Dictionary) -> bool:
	var statuses = unit.get("statuses", {})
	return statuses is Dictionary and statuses.has("stun")
