extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	await _check_first_battle_steps(screen, failures)
	_finish(screen, failures)


func _check_first_battle_steps(screen: Control, failures: Array[String]) -> void:
	_expect(screen.first_deploy_hint_panel.visible, "first deploy hint is visible on first battle screen", failures)
	var hint_title: Label = screen.get_node("FirstDeployHintPanel/HintMargin/HintLayout/HintTitle")
	_expect(hint_title.text.contains("点击手牌"), "first deploy hint explains hand selection", failures)

	var hero_id := _first_affordable_hand_hero(screen)
	_expect(not hero_id.is_empty(), "first battle has an affordable hand card", failures)
	if hero_id.is_empty():
		return
	screen.hero_buttons[hero_id].pressed.emit()
	await process_frame
	_expect(screen.selected_hero_id == hero_id, "tapping a hand card selects it", failures)
	_expect(screen.selected_card_hero_id == hero_id, "tapping a hand card opens inspected card", failures)
	_expect(screen.unit_detail_panel.visible, "tapping a hand card opens detail panel", failures)

	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	var deployed_unit: Dictionary = screen.battle_state.board.get_unit_at(cell.x, cell.y)
	_expect(str(deployed_unit.get("hero_id", "")) == hero_id, "selected hero deploys into legal blue zone", failures)
	_expect(not screen.first_deploy_hint_panel.visible, "successful first deployment hides hint", failures)
	_expect(_log_text(screen).contains("部署"), "battle log data records first deployment for report replay", failures)

	var side_before := str(screen.turn_controller.current_side)
	screen._advance_turn()
	await process_frame
	_expect(str(screen.turn_controller.current_side) != side_before, "advance turn changes active side after first deployment", failures)
	_expect(screen.status_label.text.length() > 0, "status label remains visible after advancing", failures)


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return ""


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _finish(screen: Node, failures: Array[String]) -> void:
	if screen != null:
		screen.queue_free()
	if failures.is_empty():
		print("M61 first-run tutorial path checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)


func _log_text(screen: Control) -> String:
	return "\n".join(screen.battle_log_entries)
