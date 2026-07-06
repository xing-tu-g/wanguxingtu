extends RefCounted
class_name BoardModel

# ── 偏移网格常量：9-10-9-10-9 交错布局 ──
const ROWS := 5
const COLUMNS := 10
const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const ZONE_LEFT_DEPLOYMENT := "left_deployment"
const ZONE_PUBLIC := "public"
const ZONE_RIGHT_DEPLOYMENT := "right_deployment"

var occupied_cells: Dictionary = {}
var unit_cells: Dictionary = {}


func reset() -> void:
	occupied_cells.clear()
	unit_cells.clear()


## 返回指定行的列数：奇数行 9 格，偶数行 10 格（9-10-9-10-9）
static func get_cols_for_row(row: int) -> int:
	if row < 1 or row > ROWS:
		return 0
	return 9 if row % 2 == 1 else 10


static func get_total_cell_count() -> int:
	var count := 0
	for row in range(1, ROWS + 1):
		count += get_cols_for_row(row)
	return count


func is_in_bounds(column: int, row: int) -> bool:
	var max_cols := get_cols_for_row(row)
	return column >= 1 and column <= max_cols and row >= 1 and row <= ROWS


static func get_deployment_width_for_row(row: int) -> int:
	var max_cols := get_cols_for_row(row)
	if max_cols <= 0:
		return 0
	return 2 if max_cols == 9 else 3


func get_zone_for_column(column: int, row: int = -1) -> String:
	var max_cols := get_cols_for_row(row) if row >= 1 and row <= ROWS else 10
	var deploy_width := get_deployment_width_for_row(row) if row >= 1 and row <= ROWS else 3
	var blue_end := deploy_width
	var red_start := max_cols - deploy_width + 1

	if column >= 1 and column <= blue_end:
		return ZONE_LEFT_DEPLOYMENT
	if column > blue_end and column < red_start:
		return ZONE_PUBLIC
	if column >= red_start and column <= max_cols:
		return ZONE_RIGHT_DEPLOYMENT
	return ""


func is_deployment_cell(side: String, column: int, row: int) -> bool:
	if not is_in_bounds(column, row):
		return false
	if side == SIDE_LEFT:
		return get_zone_for_column(column, row) == ZONE_LEFT_DEPLOYMENT
	if side == SIDE_RIGHT:
		return get_zone_for_column(column, row) == ZONE_RIGHT_DEPLOYMENT
	return false


func is_occupied(column: int, row: int) -> bool:
	return occupied_cells.has(_cell_key(column, row))


func get_unit_at(column: int, row: int) -> Dictionary:
	return occupied_cells.get(_cell_key(column, row), {})


func validate_deployment(side: String, column: int, row: int) -> Dictionary:
	if not is_in_bounds(column, row):
		return {"ok": false, "reason": "cell_out_of_bounds"}
	if not is_deployment_cell(side, column, row):
		return {"ok": false, "reason": "not_own_deployment_zone"}
	if is_occupied(column, row):
		return {"ok": false, "reason": "cell_occupied"}
	return {"ok": true, "reason": ""}


func can_deploy(side: String, column: int, row: int) -> bool:
	return validate_deployment(side, column, row).ok


func place_unit(unit_data: Dictionary, side: String, column: int, row: int) -> Dictionary:
	var validation := validate_deployment(side, column, row)
	if not validation.ok:
		return validation

	return place_unit_anywhere(unit_data, side, column, row)


func place_unit_anywhere(unit_data: Dictionary, side: String, column: int, row: int) -> Dictionary:
	if not is_in_bounds(column, row):
		return {"ok": false, "reason": "cell_out_of_bounds"}
	if is_occupied(column, row):
		return {"ok": false, "reason": "cell_occupied"}

	var unit_instance := unit_data.duplicate(true)
	var unit_id := str(unit_instance.get("instance_id", ""))
	if unit_id.is_empty():
		return {"ok": false, "reason": "missing_unit_id"}

	unit_instance["side"] = side
	unit_instance["column"] = column
	unit_instance["row"] = row

	var cell_key := _cell_key(column, row)
	occupied_cells[cell_key] = unit_instance
	unit_cells[unit_id] = cell_key
	return {"ok": true, "reason": "", "unit": unit_instance}


func move_unit(unit_id: String, column: int, row: int) -> Dictionary:
	if not unit_cells.has(unit_id):
		return {"ok": false, "reason": "unknown_unit"}
	if not is_in_bounds(column, row):
		return {"ok": false, "reason": "cell_out_of_bounds"}
	if is_occupied(column, row):
		return {"ok": false, "reason": "cell_occupied"}

	var old_cell_key: String = unit_cells[unit_id]
	var unit_data: Dictionary = occupied_cells[old_cell_key]
	occupied_cells.erase(old_cell_key)

	unit_data["column"] = column
	unit_data["row"] = row
	var new_cell_key := _cell_key(column, row)
	occupied_cells[new_cell_key] = unit_data
	unit_cells[unit_id] = new_cell_key
	return {"ok": true, "reason": "", "unit": unit_data}


func remove_unit(unit_id: String) -> bool:
	if not unit_cells.has(unit_id):
		return false

	var cell_key: String = unit_cells[unit_id]
	unit_cells.erase(unit_id)
	occupied_cells.erase(cell_key)
	return true


func remove_unit_at(column: int, row: int) -> bool:
	var cell_key := _cell_key(column, row)
	if not occupied_cells.has(cell_key):
		return false

	var unit_data: Dictionary = occupied_cells[cell_key]
	var unit_id := str(unit_data.get("instance_id", ""))
	if not unit_id.is_empty():
		unit_cells.erase(unit_id)
	occupied_cells.erase(cell_key)
	return true


func _cell_key(column: int, row: int) -> String:
	return "%d,%d" % [column, row]
