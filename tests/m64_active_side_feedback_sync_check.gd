extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.get_script():
		failures.append("FAIL: battle screen script failed to load")
		_finish(screen, failures)
		return

	_prepare_both_side_units(screen)
	await process_frame
	_check_player_feedback(screen, failures)
	screen._advance_turn()
	await process_frame
	_check_enemy_feedback(screen, failures)
	_finish(screen, failures)


func _prepare_both_side_units(screen: Control) -> void:
	screen.battle_state.deploy_hero("guanyu", BoardModelScript.SIDE_LEFT, 1, 3)
	screen.battle_state.deploy_hero("zhouyu", BoardModelScript.SIDE_RIGHT, 8, 3)
	screen._refresh_board()
	screen._update_status("M64 行动侧反馈同步检查。")


func _check_player_feedback(screen: Control, failures: Array[String]) -> void:
	_expect(screen.advance_turn_button.text.contains("我方行动 - 向右推进"), "player turn button uses unified side cue", failures)
	_expect(screen.advance_turn_button.tooltip_text.contains("向右推进"), "player tooltip mirrors direction", failures)
	_expect(_panel_style(screen.player_master_panel).border_color.is_equal_approx(screen._active_side_feedback_color(BoardModelScript.SIDE_LEFT)), "player master panel uses active-side color", failures)
	_expect(not _panel_style(screen.enemy_master_panel).border_color.is_equal_approx(screen._active_side_feedback_color(BoardModelScript.SIDE_RIGHT)), "enemy master panel stays standby", failures)
	_expect(_cell_text(screen, 1, 3).contains("● 向右推进"), "player unit cell shows current-action direction", failures)
	_expect(not _cell_text(screen, 8, 3).contains("● 当前行动"), "enemy unit cell stays standby on player turn", failures)
	_expect(_cell_style(screen, 1, 3).border_color.is_equal_approx(screen._active_side_feedback_color(BoardModelScript.SIDE_LEFT)), "player unit cell border uses active-side color", failures)


func _check_enemy_feedback(screen: Control, failures: Array[String]) -> void:
	_expect(screen.advance_turn_button.text.contains("敌方行动 - 向左推进"), "enemy turn button uses unified side cue", failures)
	_expect(screen.advance_turn_button.tooltip_text.contains("向左推进"), "enemy tooltip mirrors direction", failures)
	_expect(_panel_style(screen.enemy_master_panel).border_color.is_equal_approx(screen._active_side_feedback_color(BoardModelScript.SIDE_RIGHT)), "enemy master panel uses active-side color", failures)
	_expect(not _panel_style(screen.player_master_panel).border_color.is_equal_approx(screen._active_side_feedback_color(BoardModelScript.SIDE_LEFT)), "player master panel returns to standby", failures)
	_expect(_cell_text(screen, 8, 3).contains("● 向左推进"), "enemy unit cell shows current-action direction", failures)
	_expect(not _cell_text(screen, 1, 3).contains("● 当前行动"), "player unit cell stays standby on enemy turn", failures)
	_expect(_cell_style(screen, 8, 3).border_color.is_equal_approx(screen._active_side_feedback_color(BoardModelScript.SIDE_RIGHT)), "enemy unit cell border uses active-side color", failures)


func _cell_text(screen: Control, column: int, row: int) -> String:
	return str(screen.cell_buttons["%d,%d" % [column, row]].text)


func _cell_style(screen: Control, column: int, row: int) -> StyleBoxFlat:
	return screen.cell_buttons["%d,%d" % [column, row]].get_theme_stylebox("normal") as StyleBoxFlat


func _panel_style(panel: PanelContainer) -> StyleBoxFlat:
	return panel.get_theme_stylebox("panel") as StyleBoxFlat


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M64 active side feedback sync checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
