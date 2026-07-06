extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var hint_title: Label = screen.get_node("FirstDeployHintPanel/HintMargin/HintLayout/HintTitle")
	_expect(screen.first_deploy_hint_panel != null, "battle screen exposes first deploy hint panel", failures)
	_expect(screen.first_deploy_hint_panel.visible, "first deploy hint starts visible before any unit is deployed", failures)
	_expect(hint_title.text.contains("点击手牌"), "hint explains selecting a hand card", failures)
	_expect(hint_title.text.contains("蓝色近端星格"), "hint explains blue near deployment cells", failures)
	_expect(hint_title.text.contains("自动补牌"), "hint explains automatic refill", failures)
	_expect(hint_title.text.contains("推进回合"), "hint explains advancing turn", failures)

	var hero_id := _first_affordable_hand_hero(screen)
	_expect(not hero_id.is_empty(), "test finds an affordable opening hand card", failures)
	if not hero_id.is_empty():
		screen.hero_buttons[hero_id].pressed.emit()
		await process_frame
		_expect(screen.first_deploy_hint_panel.visible, "selecting a card keeps deployment hint visible", failures)

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	_expect(not screen.first_deploy_hint_panel.visible, "hint dismiss button hides first deploy hint", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(screen.first_deploy_hint_panel.visible, "reset restores first deploy hint", failures)

	hero_id = _first_affordable_hand_hero(screen)
	var cell := _first_deploy_cell(screen)
	screen.selected_hero_id = hero_id
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(not screen.first_deploy_hint_panel.visible, "successful first deployment hides hint", failures)
	_expect(screen.battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).size() >= 1, "deployment still creates player unit", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M48 first deploy hint checks passed")
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
	return ""


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
