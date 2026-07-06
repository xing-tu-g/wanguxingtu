extends RefCounted
class_name TerrainSystem

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const TERRAIN_GRASS := "grass"
const TERRAIN_SWAMP := "swamp"
const TERRAIN_RIVER := "river"
const TERRAIN_HIGHLAND := "highland"

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const ZONE_LEFT_DEPLOYMENT := "left_deployment"
const ZONE_PUBLIC := "public"
const ZONE_RIGHT_DEPLOYMENT := "right_deployment"

const ROWS := BoardModelScript.ROWS

var terrain_cells: Dictionary = {}


func reset() -> void:
	terrain_cells.clear()


func set_terrain(column: int, row: int, terrain_id: String) -> bool:
	if not is_in_bounds(column, row):
		return false
	var cell_key := _cell_key(column, row)
	if terrain_id == TERRAIN_GRASS or terrain_id.is_empty():
		terrain_cells.erase(cell_key)
	else:
		terrain_cells[cell_key] = terrain_id
	return true


func get_terrain(column: int, row: int) -> String:
	if not is_in_bounds(column, row):
		return TERRAIN_GRASS
	var terrain_value = terrain_cells.get(_cell_key(column, row), TERRAIN_GRASS)
	if terrain_value == null:
		return TERRAIN_GRASS
	return str(terrain_value)


func generate_deterministic(seed_value: int = 1) -> Dictionary:
	reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var terrains := [
		TERRAIN_SWAMP,
		TERRAIN_RIVER,
		TERRAIN_HIGHLAND,
		TERRAIN_SWAMP,
		TERRAIN_RIVER,
	]
	_shuffle_with_rng(terrains, rng)

	var cells := [
		_pick_cell_in_columns(rng, 1, 3),
		_pick_cell_in_columns(rng, 8, 10),
		_pick_cell_in_columns(rng, 4, 7),
		_pick_cell_in_columns(rng, 4, 7),
		_pick_cell_in_columns(rng, 4, 7),
	]

	var used_cells: Dictionary = {}
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		while used_cells.has(_cell_key(cell.x, cell.y)):
			cell = _pick_cell_in_columns(rng, 4, 7)
		used_cells[_cell_key(cell.x, cell.y)] = true
		set_terrain(cell.x, cell.y, terrains[index])

	return terrain_cells.duplicate(true)


func get_zone_for_column(column: int, row: int = -1) -> String:
	var max_cols: int = BoardModelScript.get_cols_for_row(row) if row >= 1 and row <= ROWS else 10
	var deploy_width: int = BoardModelScript.get_deployment_width_for_row(row) if row >= 1 and row <= ROWS else 3
	var blue_end: int = deploy_width
	var red_start: int = max_cols - deploy_width + 1

	if column >= 1 and column <= blue_end:
		return ZONE_LEFT_DEPLOYMENT
	if column > blue_end and column < red_start:
		return ZONE_PUBLIC
	if column >= red_start and column <= max_cols:
		return ZONE_RIGHT_DEPLOYMENT
	return ""


func get_movement_cost(unit: Dictionary, column: int, row: int) -> int:
	var terrain_id := get_terrain(column, row)
	if terrain_id == TERRAIN_SWAMP and not _ignores_swamp(unit):
		return 2
	return 1


func get_attack_delta(unit: Dictionary) -> int:
	if get_terrain(int(unit.get("column", 0)), int(unit.get("row", 0))) == TERRAIN_RIVER:
		return -1
	return 0


func get_incoming_damage_delta(target: Dictionary) -> int:
	if get_terrain(int(target.get("column", 0)), int(target.get("row", 0))) == TERRAIN_RIVER:
		return 1
	return 0


func get_master_damage_delta(attacker: Dictionary) -> int:
	if get_terrain(int(attacker.get("column", 0)), int(attacker.get("row", 0))) == TERRAIN_RIVER:
		return -1
	return 0


func get_range_delta(unit: Dictionary) -> int:
	if get_terrain(int(unit.get("column", 0)), int(unit.get("row", 0))) != TERRAIN_HIGHLAND:
		return 0
	var unit_class := str(unit.get("class", ""))
	if unit_class == "archer" or unit_class == "mage":
		return 1
	return 0


func is_in_bounds(column: int, row: int) -> bool:
	var max_cols: int = BoardModelScript.get_cols_for_row(row)
	return column >= 1 and column <= max_cols and row >= 1 and row <= ROWS


func _pick_cell_in_columns(rng: RandomNumberGenerator, min_column: int, max_column: int) -> Vector2i:
	var row := rng.randi_range(1, ROWS)
	var row_cols: int = BoardModelScript.get_cols_for_row(row)
	var clamped_max := mini(max_column, row_cols)
	if clamped_max < min_column:
		clamped_max = min_column
	return Vector2i(rng.randi_range(min_column, clamped_max), row)


func _shuffle_with_rng(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var current_value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value


func _ignores_swamp(unit: Dictionary) -> bool:
	var unit_class := str(unit.get("class", ""))
	return unit_class == "assassin" or unit_class == "warrior"


func _cell_key(column: int, row: int) -> String:
	return "%d,%d" % [column, row]
