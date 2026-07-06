extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen._select_hero(_first_affordable_hand_hero(screen))
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(not screen.unit_detail_panel.visible, "detail panel stays hidden after deploying to an empty cell", failures)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "clicking an occupied cell opens the unit detail panel", failures)
	_expect(screen.unit_detail_title.text.length() > 0 or screen.unit_detail_body.text.length() > 0, "detail panel has readable content", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M11 unit detail overlay checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return str(screen.player_hand[0])


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
