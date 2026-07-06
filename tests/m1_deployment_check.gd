extends SceneTree

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")


func _init() -> void:
	var failures: Array[String] = []
	var state = BattleStateScript.new()

	_expect(state.board.COLUMNS == 10, "board has 10 max columns", failures)
	_expect(state.board.ROWS == 5, "board has 5 rows", failures)
	_expect(BoardModelScript.get_total_cell_count() == 47, "board has 47 cells in 9-10-9-10-9 layout", failures)
	_expect(BoardModelScript.get_cols_for_row(1) == 9 and BoardModelScript.get_cols_for_row(2) == 10, "board rows alternate 9 and 10 cells", failures)
	_expect(BoardModelScript.get_deployment_width_for_row(1) == 2, "9-cell rows use two deployment cells per side", failures)
	_expect(BoardModelScript.get_deployment_width_for_row(2) == 3, "10-cell rows use three deployment cells per side", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 1, 1), "left side can deploy in row 1 nearest columns", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 2, 1), "left side can deploy in row 1 second nearest column", failures)
	_expect(not state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 3, 1), "left side cannot deploy in row 1 third column", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 3, 2), "left side can deploy in row 2 third column", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 9, 5), "right side can deploy at row 5 right edge", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 8, 5), "right side can deploy in row 5 second nearest column", failures)
	_expect(not state.board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 7, 5), "right side cannot deploy in row 5 third from edge", failures)
	_expect(not state.board.is_in_bounds(10, 5), "odd rows do not expose a phantom tenth cell", failures)
	_expect(not state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 5, 3), "public zone deployment rejected by board", failures)
	_expect(not state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 9, 3), "enemy zone deployment rejected by board", failures)

	var valid_result: Dictionary = state.deploy_hero("guanyu", BoardModelScript.SIDE_LEFT, 2, 3)
	_expect(valid_result.ok, "valid left deployment succeeds", failures)
	_expect(state.get_star_power(BoardModelScript.SIDE_LEFT) == 0, "hero cost deducted from star power", failures)
	_expect(state.board.is_occupied(2, 3), "placed unit occupies target cell", failures)

	var occupied_result: Dictionary = state.deploy_hero("guanyu", BoardModelScript.SIDE_LEFT, 2, 3)
	_expect(not occupied_result.ok and occupied_result.reason == "cell_occupied", "occupied deployment rejected", failures)

	var public_result: Dictionary = state.deploy_hero("guanyu", BoardModelScript.SIDE_RIGHT, 5, 3)
	_expect(not public_result.ok and public_result.reason == "not_own_deployment_zone", "public-zone deployment rejected", failures)

	var low_power_result: Dictionary = state.deploy_hero("guanyu", BoardModelScript.SIDE_LEFT, 1, 1)
	_expect(not low_power_result.ok and low_power_result.reason == "not_enough_star_power", "insufficient star power rejected", failures)

	if failures.is_empty():
		print("M1 deployment checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
