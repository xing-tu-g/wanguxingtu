extends RefCounted
class_name BattleAI

const AttackShapeSystemScript: GDScript = preload("res://scripts/battle/AttackShapeSystem.gd")

static func select_nearest_enemy(unit: Dictionary, enemy_units: Array) -> Dictionary:
	var candidates: Array = []
	for enemy: Dictionary in enemy_units:
		if int(enemy.get("hp", 0)) > 0:
			candidates.append(enemy)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(left_enemy: Dictionary, right_enemy: Dictionary) -> bool:
		return _compare_nearest(unit, left_enemy, right_enemy)
	)
	return candidates[0]


static func move_toward_target(state, unit: Dictionary, target: Dictionary) -> Dictionary:
	# Combat Design Bible v1.0 forbids route search, side steps, and class-specific AI.
	# MovementSystem owns forward-only movement; this compatibility method intentionally waits.
	return _stationary_result(unit)


static func _best_next_cell(state, unit: Dictionary, target: Dictionary, current: Vector2i, remaining_move: int, can_pass: bool) -> Vector2i:
	return current


static func _movement_priority(side: String, current: Vector2i, target: Dictionary) -> Array[Vector2i]:
	var horizontal: int = AttackShapeSystemScript.forward_direction(side)
	return [Vector2i(horizontal, 0)]


static func _compare_nearest(unit: Dictionary, left_enemy: Dictionary, right_enemy: Dictionary) -> bool:
	var left_distance: int = AttackShapeSystemScript.target_distance(unit, left_enemy)
	var right_distance: int = AttackShapeSystemScript.target_distance(unit, right_enemy)
	if left_distance != right_distance:
		return left_distance < right_distance
	var side := str(unit.get("side", ""))
	var left_column := int(left_enemy.get("column", 0))
	var right_column := int(right_enemy.get("column", 0))
	if left_column != right_column:
		if side == "left":
			return left_column < right_column
		return left_column > right_column
	var left_hp := int(left_enemy.get("hp", 0))
	var right_hp := int(right_enemy.get("hp", 0))
	if left_hp != right_hp:
		return left_hp < right_hp
	return int(left_enemy.get("entry_order", 0)) < int(right_enemy.get("entry_order", 0))


static func _distance_units(left_unit: Dictionary, right_unit: Dictionary) -> int:
	return absi(int(left_unit.get("column", 0)) - int(right_unit.get("column", 0))) + absi(int(left_unit.get("row", 0)) - int(right_unit.get("row", 0)))


static func _distance_from_cell(cell: Vector2i, unit: Dictionary) -> int:
	return absi(cell.x - int(unit.get("column", 0))) + absi(cell.y - int(unit.get("row", 0)))


static func _stationary_result(unit: Dictionary) -> Dictionary:
	var position := Vector2i(int(unit.get("column", 0)), int(unit.get("row", 0)))
	return {"ok": true, "from": position, "to": position, "steps": 0}
