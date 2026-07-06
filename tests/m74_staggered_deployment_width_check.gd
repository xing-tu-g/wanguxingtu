extends SceneTree

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var board = BoardModelScript.new()

	for row in [1, 3, 5]:
		_expect(BoardModelScript.get_cols_for_row(row) == 9, "odd row has 9 cells", failures)
		_expect(BoardModelScript.get_deployment_width_for_row(row) == 2, "9-cell row deploy width is 2", failures)
		_expect(board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 1, row), "left edge deploys on 9-cell row", failures)
		_expect(board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 2, row), "left second cell deploys on 9-cell row", failures)
		_expect(not board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 3, row), "left third cell is public on 9-cell row", failures)
		_expect(board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 9, row), "right edge deploys on 9-cell row", failures)
		_expect(board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 8, row), "right second cell deploys on 9-cell row", failures)
		_expect(not board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 7, row), "right third cell is public on 9-cell row", failures)

	for row in [2, 4]:
		_expect(BoardModelScript.get_cols_for_row(row) == 10, "even row has 10 cells", failures)
		_expect(BoardModelScript.get_deployment_width_for_row(row) == 3, "10-cell row deploy width is 3", failures)
		_expect(board.is_deployment_cell(BoardModelScript.SIDE_LEFT, 3, row), "left third cell deploys on 10-cell row", failures)
		_expect(board.is_deployment_cell(BoardModelScript.SIDE_RIGHT, 8, row), "right third cell deploys on 10-cell row", failures)

	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var row1_col3 := screen.cell_buttons["3,1"].get_node("GridBackplate") as TextureRect
	var row1_col8 := screen.cell_buttons["8,1"].get_node("GridBackplate") as TextureRect
	var row2_col3 := screen.cell_buttons["3,2"].get_node("GridBackplate") as TextureRect
	_expect(row1_col3.texture.resource_path.ends_with("grid_mid_idle.png"), "row 1 col 3 renders as mid zone", failures)
	_expect(row1_col8.texture.resource_path.ends_with("grid_red_idle.png"), "row 1 col 8 renders as red deploy zone", failures)
	_expect(row2_col3.texture.resource_path.ends_with("grid_blue_idle.png") or row2_col3.texture.resource_path.ends_with("grid_blue_hover.png"), "row 2 col 3 renders as blue deploy zone", failures)
	screen.queue_free()

	if failures.is_empty():
		print("M78 staggered deployment width checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
