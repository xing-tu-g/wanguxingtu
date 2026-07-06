extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	await _check_hand_card_opens_detail(screen, failures)
	await _check_selection_keeps_deploy_flow(screen, failures)
	await _check_board_unit_detail_overrides_card_detail(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M44 hand card detail overlay checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hand_card_opens_detail(screen: Control, failures: Array[String]) -> void:
	var hero_id := _first_hand_hero(screen)
	screen.hero_buttons[hero_id].pressed.emit()
	await process_frame
	_expect(screen.selected_hero_id == hero_id, "clicking bottom hand card still selects hero", failures)
	_expect(screen.selected_card_hero_id == hero_id, "clicking bottom hand card syncs inspected card", failures)
	_expect(screen.unit_detail_panel.visible, "clicking bottom hand card opens detail overlay", failures)
	_expect(not screen.unit_detail_title.text.contains("*5") and not screen.unit_detail_title.text.contains("★"), "detail title avoids star rarity", failures)
	_expect(screen.unit_detail_body.text.length() > 0 and not screen.unit_detail_body.text.contains("★"), "card detail shows readable body without star rarity", failures)


func _check_selection_keeps_deploy_flow(screen: Control, failures: Array[String]) -> void:
	var hero_id: String = screen.selected_hero_id
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	var unit_data: Dictionary = screen.battle_state.board.get_unit_at(cell.x, cell.y)
	_expect(unit_data.get("hero_id", "") == hero_id, "selected card can still deploy after detail opens", failures)
	_expect(not screen.player_hand.has(hero_id), "deployed hand card leaves hand", failures)


func _check_board_unit_detail_overrides_card_detail(screen: Control, failures: Array[String]) -> void:
	var unit_pos := _first_left_unit_cell(screen)
	screen._deploy_selected_to_cell(unit_pos.x, unit_pos.y)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "clicking occupied board cell opens unit detail", failures)
	_expect(screen.unit_detail_title.text.length() > 0, "board unit detail replaces card detail title", failures)
	_expect(screen.unit_detail_body.text.length() > 0, "board unit detail shows body", failures)


func _first_hand_hero(screen: Control) -> String:
	return str(screen.player_hand[0])


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _first_left_unit_cell(screen: Control) -> Vector2i:
	for unit_data: Dictionary in screen.battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT):
		return Vector2i(int(unit_data.get("column", 1)), int(unit_data.get("row", 1)))
	return Vector2i(1, 1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
