extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var battle_screen = BattleScreenScene.instantiate()
	root.add_child(battle_screen)
	await process_frame

	_expect(battle_screen.cell_buttons.size() == BoardModelScript.get_total_cell_count(), "battle screen builds the offset board", failures)
	_expect(not battle_screen.log_panel.visible, "battle screen keeps battle report drawer hidden by default", failures)
	battle_screen._toggle_battle_log()
	await process_frame
	_expect(not battle_screen.log_panel.visible, "battle screen cannot open battle report drawer", failures)
	_expect(not battle_screen.toggle_log_button.visible, "battle screen hides battle report button", failures)
	battle_screen._toggle_battle_log()
	await process_frame

	battle_screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	battle_screen._select_hero(_first_affordable_hand_hero(battle_screen))
	var deploy_cell := _first_deploy_cell(battle_screen)
	battle_screen._deploy_selected_to_cell(deploy_cell.x, deploy_cell.y)
	await process_frame
	_expect(battle_screen.battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).size() >= 1, "playthrough can deploy from battle screen", failures)

	battle_screen.battle_state.master_hp[BoardModelScript.SIDE_RIGHT] = 0
	var battle_result: Dictionary = battle_screen._check_battle_end()
	_expect(battle_result.get("outcome", "") == "left_wins", "finished battle produces left win result", failures)

	battle_screen.queue_free()
	if failures.is_empty():
		print("M7c routed playthrough checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _first_affordable_hand_hero(battle_screen: Control) -> String:
	for hero_id_value in battle_screen.player_hand:
		var hero_id := str(hero_id_value)
		if battle_screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return str(battle_screen.player_hand[0])


func _first_deploy_cell(battle_screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if battle_screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
