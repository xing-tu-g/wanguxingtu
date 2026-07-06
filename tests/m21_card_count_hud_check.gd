extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_initial_deck_hand_status(screen, failures)
	await _check_deploy_refills_player_hand_status(screen, failures)
	_check_reset_hidden_but_restores_hand_status(screen, failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M21 card count HUD checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_deck_hand_status(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	var expected_reserve: int = screen._player_battle_hero_ids().size() - 5
	_expect(screen.player_hand.size() == 5, "initial player hand has five cards", failures)
	_expect(screen.player_deck.size() == expected_reserve, "initial player deck keeps configured reserve cards", failures)
	_expect(screen.enemy_hand.size() == 5, "initial enemy hand has five cards", failures)
	_expect(screen.enemy_deck.size() == expected_reserve, "initial enemy deck keeps configured reserve cards", failures)
	_expect(screen.player_hud_label.text.length() > 0, "initial player HUD has text", failures)
	_expect(screen.enemy_hud_label.text.length() > 0, "initial enemy HUD has text", failures)


func _check_deploy_refills_player_hand_status(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var deck_before: int = screen.player_deck.size()
	var hero_id := str(screen.player_hand[0])
	screen._select_hero(hero_id)
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(not screen.player_hand.has(hero_id), "deployed player card leaves hand", failures)
	_expect(screen.player_hand.size() == 5, "player deployment refills hand from deck", failures)
	_expect(screen.player_deck.size() == deck_before - 1, "player deployment consumes one reserve deck card", failures)


func _check_reset_hidden_but_restores_hand_status(screen: Control, failures: Array[String]) -> void:
	var reset_button: Button = screen.get_node("BottomHand/Controls/ResetButton")
	_expect(not reset_button.visible, "reset button is hidden in normal battle UI", failures)
	screen._reset_debug_battle()
	var expected_reserve: int = screen._player_battle_hero_ids().size() - 5
	_expect(screen.player_hand.size() == 5 and screen.player_deck.size() == expected_reserve, "reset restores player deck and hand count", failures)
	_expect(screen.enemy_hand.size() == 5 and screen.enemy_deck.size() == expected_reserve, "reset restores enemy deck and hand count", failures)


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
