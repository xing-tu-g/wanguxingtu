extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleUIThemeScript: GDScript = preload("res://scripts/ui/theme/BattleUITheme.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

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
	screen._update_status("M64 active-side feedback check")


func _check_player_feedback(screen: Control, failures: Array[String]) -> void:
	var advance_label: Label = screen.advance_turn_button.get_node("AdvanceText")
	_expect(advance_label.text.contains("推进"), "player turn button keeps unified main action", failures)
	_expect(screen.status_label.text.contains("我方行动"), "top core status names player side", failures)
	_expect(_panel_style(screen.player_master_panel).border_color.is_equal_approx(BattleUIThemeScript.PLAYER_BORDER), "player master panel uses active-side color", failures)
	_expect(_panel_style(screen.player_master_panel).border_width_left > _panel_style(screen.enemy_master_panel).border_width_left, "enemy master panel stays standby", failures)
	_expect(not _cell_text(screen, 1, 3).is_empty(), "player unit cell keeps compact unit id", failures)
	_expect(not _cell_text(screen, 8, 3).contains("当前行动"), "enemy unit cell avoids verbose active text on player turn", failures)


func _check_enemy_feedback(screen: Control, failures: Array[String]) -> void:
	_expect(screen.status_label.text.contains("敌方行动"), "top core status names enemy side", failures)
	_expect(_panel_style(screen.enemy_master_panel).border_color.is_equal_approx(BattleUIThemeScript.ENEMY_BORDER), "enemy master panel uses active-side color", failures)
	_expect(_panel_style(screen.enemy_master_panel).border_width_left > _panel_style(screen.player_master_panel).border_width_left, "player master panel returns to standby", failures)
	_expect(not _cell_text(screen, 8, 3).is_empty(), "enemy unit cell keeps compact unit id", failures)
	_expect(not _cell_text(screen, 1, 3).contains("当前行动"), "player unit cell avoids verbose active text on enemy turn", failures)


func _cell_text(screen: Control, column: int, row: int) -> String:
	return str(screen.cell_buttons["%d,%d" % [column, row]].text)


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
