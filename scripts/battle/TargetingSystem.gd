extends RefCounted
class_name TargetingSystem

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const BOARD_LEFT_MASTER_COLUMN := 0
const BOARD_RIGHT_MASTER_COLUMN := 11


static func manhattan_distance(from_unit: Dictionary, to_unit: Dictionary) -> int:
	return absi(int(from_unit.get("column", 0)) - int(to_unit.get("column", 0))) + absi(int(from_unit.get("row", 0)) - int(to_unit.get("row", 0)))


static func select_target(attacker: Dictionary, enemy_units: Array, terrain_system = null) -> Dictionary:
	var attack_range := get_attack_range(attacker, terrain_system)
	var candidates: Array = []
	for enemy: Dictionary in enemy_units:
		if int(enemy.get("hp", 0)) > 0 and manhattan_distance(attacker, enemy) <= attack_range:
			candidates.append(enemy)

	if candidates.is_empty():
		return {}

	candidates.sort_custom(func(left_unit: Dictionary, right_unit: Dictionary) -> bool:
		return _compare_target_priority(attacker, left_unit, right_unit)
	)
	return candidates[0]


static func can_attack_master(attacker: Dictionary, enemy_units: Array, terrain_system = null) -> bool:
	if not select_target(attacker, enemy_units, terrain_system).is_empty():
		return false
	if _has_enemy_ahead(attacker, enemy_units):
		return false

	var attack_range := get_attack_range(attacker, terrain_system)
	var attacker_column := int(attacker.get("column", 0))
	if str(attacker.get("side", "")) == SIDE_LEFT:
		return BOARD_RIGHT_MASTER_COLUMN - attacker_column <= attack_range
	return attacker_column - BOARD_LEFT_MASTER_COLUMN <= attack_range


static func get_attack_range(attacker: Dictionary, terrain_system = null) -> int:
	var attack_range := int(attacker.get("range", 1))
	if terrain_system != null:
		attack_range += int(terrain_system.get_range_delta(attacker))
	return maxi(0, attack_range)


static func _compare_target_priority(attacker: Dictionary, left_unit: Dictionary, right_unit: Dictionary) -> bool:
	var attacker_side := str(attacker.get("side", ""))
	var left_column := int(left_unit.get("column", 0))
	var right_column := int(right_unit.get("column", 0))
	if left_column != right_column:
		if attacker_side == SIDE_LEFT:
			return left_column < right_column
		return left_column > right_column

	var left_hp := int(left_unit.get("hp", 0))
	var right_hp := int(right_unit.get("hp", 0))
	if left_hp != right_hp:
		return left_hp < right_hp

	var left_row := int(left_unit.get("row", 0))
	var right_row := int(right_unit.get("row", 0))
	if left_row != right_row:
		return left_row < right_row

	return int(left_unit.get("entry_order", 0)) < int(right_unit.get("entry_order", 0))


static func _has_enemy_ahead(attacker: Dictionary, enemy_units: Array) -> bool:
	var attacker_side := str(attacker.get("side", ""))
	var attacker_column := int(attacker.get("column", 0))
	var attacker_row := int(attacker.get("row", 0))
	for enemy: Dictionary in enemy_units:
		if int(enemy.get("hp", 0)) <= 0 or int(enemy.get("row", 0)) != attacker_row:
			continue
		var enemy_column := int(enemy.get("column", 0))
		if attacker_side == SIDE_LEFT and enemy_column > attacker_column:
			return true
		if attacker_side == SIDE_RIGHT and enemy_column < attacker_column:
			return true
	return false
