extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_initial_card_zone_summary(screen, failures)
	await _check_player_deploy_moves_card_to_discard(screen, failures)
	_check_reset_clears_discards(screen, failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M27 discard card zone checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_card_zone_summary(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	_expect(screen.player_hand.size() == 5, "initial player hand has five cards", failures)
	_expect(screen.player_discard.is_empty(), "initial player discard is empty", failures)
	_expect(screen.enemy_discard.is_empty(), "initial enemy discard is empty", failures)
	_expect(screen.card_zone_summary_label.text.contains("牌库剩余"), "card zone summary shows deck count", failures)


func _check_player_deploy_moves_card_to_discard(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var hero_id := str(screen.player_hand[0])
	screen._select_hero(hero_id)
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(not screen.player_hand.has(hero_id), "deployed player card leaves hand", failures)
	_expect(screen.player_discard.has(hero_id), "deployed player card enters discard", failures)


func _check_reset_clears_discards(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	_expect(screen.player_discard.is_empty(), "reset clears player discard", failures)
	_expect(screen.enemy_discard.is_empty(), "reset clears enemy discard", failures)


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
