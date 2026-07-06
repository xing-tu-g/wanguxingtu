extends RefCounted
class_name AttackShapeSystem

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"

const SHAPE_SAME_ROW_FORWARD := "same_row_forward"
const SHAPE_SAME_ROW_PLUS_ADJACENT_FORWARD := "same_row_plus_adjacent_forward"
const SHAPE_FRONT_1 := "front_1"
const SHAPE_FRONT_LINE := "front_line"
const SHAPE_ROW_LINE := "row_line"
const SHAPE_COLUMN_LINE := "column_line"
const SHAPE_CROSS := "cross"
const SHAPE_RECTANGLE := "rectangle"
const SHAPE_FAN := "fan"
const SHAPE_SELF := "self"
const SHAPE_ALL_ENEMIES := "all_enemies"
const SHAPE_ALL_ALLIES := "all_allies"
const SHAPE_ALLY_NEAREST := "ally_nearest"

const MELEE_CLASSES := ["tank", "warrior", "assassin"]
const RANGED_CLASSES := ["archer", "mage"]
const ASSASSIN_BACKSTAB_BONUS_DAMAGE := 3


static func basic_attack_shape(unit: Dictionary) -> String:
	var unit_class := str(unit.get("class", ""))
	if unit_class in RANGED_CLASSES:
		return SHAPE_SAME_ROW_PLUS_ADJACENT_FORWARD
	return SHAPE_SAME_ROW_FORWARD


static func basic_attack_range(unit: Dictionary, terrain_system = null) -> int:
	var attack_range := int(unit.get("range", 1))
	if terrain_system != null:
		attack_range += int(terrain_system.get_range_delta(unit))
	return maxi(0, attack_range)


static func select_basic_attack_targets(attacker: Dictionary, enemy_units: Array, terrain_system = null) -> Array:
	var attack_shape := basic_attack_shape(attacker)
	var attack_range := basic_attack_range(attacker, terrain_system)
	var targets: Array = []
	for enemy: Dictionary in enemy_units:
		if int(enemy.get("hp", 0)) <= 0:
			continue
		if is_unit_in_shape(attacker, enemy, attack_shape, attack_range):
			targets.append(enemy)
			continue
		if is_backstab_target(attacker, enemy):
			targets.append(enemy)
	targets.sort_custom(func(left_unit: Dictionary, right_unit: Dictionary) -> bool:
		return compare_basic_attack_priority(attacker, left_unit, right_unit)
	)
	return targets


static func is_unit_in_shape(source: Dictionary, target: Dictionary, shape: String, attack_range: int) -> bool:
	if target.is_empty() or int(target.get("hp", 0)) <= 0:
		return false
	match shape:
		SHAPE_SAME_ROW_FORWARD:
			return _is_same_row_forward(source, target, attack_range)
		SHAPE_FRONT_1:
			return _is_same_row_forward(source, target, 1)
		SHAPE_SAME_ROW_PLUS_ADJACENT_FORWARD:
			return _is_adjacent_row_forward(source, target, attack_range)
		SHAPE_FRONT_LINE, SHAPE_ROW_LINE:
			return _is_same_row_forward(source, target, attack_range)
		SHAPE_COLUMN_LINE:
			return int(source.get("column", 0)) == int(target.get("column", 0)) and _row_distance(source, target) <= attack_range
		SHAPE_CROSS:
			return _is_same_row_forward(source, target, attack_range) or _is_same_column(source, target, attack_range)
		SHAPE_RECTANGLE, SHAPE_FAN:
			return _is_forward(source, target) and _horizontal_distance(source, target) <= attack_range and _row_distance(source, target) <= 1
		SHAPE_ALL_ENEMIES, SHAPE_ALL_ALLIES:
			return true
	return false


static func select_units(source: Dictionary, candidates: Array, shape: String, attack_range: int, terrain_system = null) -> Array:
	var effective_range := attack_range
	if terrain_system != null:
		effective_range += int(terrain_system.get_range_delta(source))
	var selected: Array = []
	for candidate: Dictionary in candidates:
		if int(candidate.get("hp", 0)) <= 0:
			continue
		if is_unit_in_shape(source, candidate, shape, effective_range):
			selected.append(candidate)
	selected.sort_custom(func(left_unit: Dictionary, right_unit: Dictionary) -> bool:
		return compare_basic_attack_priority(source, left_unit, right_unit)
	)
	return selected


static func select_area_units(center: Dictionary, candidates: Array, shape: String, radius: int) -> Array:
	var selected: Array = []
	for candidate: Dictionary in candidates:
		if int(candidate.get("hp", 0)) <= 0:
			continue
		match shape:
			SHAPE_CROSS:
				if _same_row_from_center(center, candidate, radius) or _same_column_from_center(center, candidate, radius):
					selected.append(candidate)
			SHAPE_RECTANGLE:
				if absi(int(candidate.get("column", 0)) - int(center.get("column", 0))) <= radius and absi(int(candidate.get("row", 0)) - int(center.get("row", 0))) <= radius:
					selected.append(candidate)
			_:
				var distance := absi(int(candidate.get("column", 0)) - int(center.get("column", 0))) + absi(int(candidate.get("row", 0)) - int(center.get("row", 0)))
				if distance <= radius:
					selected.append(candidate)
	return selected


static func adjacent_cells(source: Dictionary) -> Array[Vector2i]:
	var column := int(source.get("column", 0))
	var row := int(source.get("row", 0))
	return [
		Vector2i(column + 1, row),
		Vector2i(column - 1, row),
		Vector2i(column, row - 1),
		Vector2i(column, row + 1),
	]


static func compare_basic_attack_priority(attacker: Dictionary, left_unit: Dictionary, right_unit: Dictionary) -> bool:
	var left_distance := target_distance(attacker, left_unit)
	var right_distance := target_distance(attacker, right_unit)
	if left_distance != right_distance:
		return left_distance < right_distance

	var left_same_row := int(left_unit.get("row", 0)) == int(attacker.get("row", 0))
	var right_same_row := int(right_unit.get("row", 0)) == int(attacker.get("row", 0))
	if left_same_row != right_same_row:
		return left_same_row

	var left_row_offset := absi(int(left_unit.get("row", 0)) - int(attacker.get("row", 0)))
	var right_row_offset := absi(int(right_unit.get("row", 0)) - int(attacker.get("row", 0)))
	if left_row_offset != right_row_offset:
		return left_row_offset < right_row_offset

	var left_row := int(left_unit.get("row", 0))
	var right_row := int(right_unit.get("row", 0))
	if left_row != right_row:
		return left_row < right_row

	var left_hp := int(left_unit.get("hp", 0))
	var right_hp := int(right_unit.get("hp", 0))
	if left_hp != right_hp:
		return left_hp < right_hp

	return int(left_unit.get("entry_order", 0)) < int(right_unit.get("entry_order", 0))


static func target_distance(source: Dictionary, target: Dictionary) -> int:
	return absi(int(target.get("column", 0)) - int(source.get("column", 0)))


static func is_backstab_target(attacker: Dictionary, target: Dictionary) -> bool:
	if str(attacker.get("class", "")) != "assassin":
		return false
	if int(target.get("hp", 0)) <= 0:
		return false
	if int(attacker.get("row", 0)) != int(target.get("row", 0)):
		return false
	var direction := forward_direction(str(attacker.get("side", "")))
	return int(target.get("column", 0)) == int(attacker.get("column", 0)) - direction


static func forward_direction(side: String) -> int:
	if side == SIDE_RIGHT:
		return -1
	return 1


static func _is_same_row_forward(source: Dictionary, target: Dictionary, attack_range: int) -> bool:
	if int(source.get("row", 0)) != int(target.get("row", 0)):
		return false
	return _is_forward(source, target) and _horizontal_distance(source, target) <= attack_range


static func _is_adjacent_row_forward(source: Dictionary, target: Dictionary, attack_range: int) -> bool:
	if _row_distance(source, target) > 1:
		return false
	return _is_forward(source, target) and _horizontal_distance(source, target) <= attack_range


static func _is_forward(source: Dictionary, target: Dictionary) -> bool:
	var direction := forward_direction(str(source.get("side", "")))
	var delta := int(target.get("column", 0)) - int(source.get("column", 0))
	return delta * direction > 0


static func _horizontal_distance(source: Dictionary, target: Dictionary) -> int:
	return absi(int(target.get("column", 0)) - int(source.get("column", 0)))


static func _row_distance(source: Dictionary, target: Dictionary) -> int:
	return absi(int(target.get("row", 0)) - int(source.get("row", 0)))


static func _is_same_column(source: Dictionary, target: Dictionary, attack_range: int) -> bool:
	if int(source.get("column", 0)) != int(target.get("column", 0)):
		return false
	return _row_distance(source, target) <= attack_range


static func _same_row_from_center(center: Dictionary, target: Dictionary, radius: int) -> bool:
	return int(center.get("row", 0)) == int(target.get("row", 0)) and absi(int(target.get("column", 0)) - int(center.get("column", 0))) <= radius


static func _same_column_from_center(center: Dictionary, target: Dictionary, radius: int) -> bool:
	return int(center.get("column", 0)) == int(target.get("column", 0)) and absi(int(target.get("row", 0)) - int(center.get("row", 0))) <= radius
