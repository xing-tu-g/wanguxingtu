extends SceneTree

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")


func _init() -> void:
	var failures: Array[String] = []
	var state = BattleStateScript.new()

	_expect(state.board.COLUMNS == 10, "board has 10 columns", failures)
	_expect(state.board.ROWS == 5, "board has 5 rows", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 1, 1), "left side can deploy in columns 1-3", failures)
	_expect(state.board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 10, 5), "right side can deploy in columns 8-10", failures)
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
