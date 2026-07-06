extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	await _check_card_detail_density(screen, failures)
	await _check_unit_detail_density(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M60 detail density feedback checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_card_detail_density(screen: Control, failures: Array[String]) -> void:
	var hero_id := str(screen.player_hand[0])
	screen.hero_buttons[hero_id].pressed.emit()
	await process_frame
	_expect(screen.unit_detail_panel.visible, "hand card opens detail panel", failures)
	_expect(screen.unit_detail_title.text.length() > 0, "card detail title is readable", failures)
	_expect(not screen.unit_detail_title.text.contains("*5") and not screen.unit_detail_title.text.contains("★"), "card detail avoids star rarity", failures)
	_expect(screen.unit_detail_body.text.length() > 0, "card detail body is readable", failures)


func _check_unit_detail_density(screen: Control, failures: Array[String]) -> void:
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "occupied cell opens unit detail panel", failures)
	_expect(screen.unit_detail_title.text.length() > 0, "unit detail title is readable", failures)
	_expect(screen.unit_detail_body.text.length() > 0, "unit detail body is readable", failures)


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
