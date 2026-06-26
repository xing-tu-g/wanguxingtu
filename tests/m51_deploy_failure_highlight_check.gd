extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen._refresh_board()
	await process_frame
	_expect(not screen._should_show_recommended_deploy_cell(2, 3), "dismissed first-deploy hint hides recommendation before failure", failures)

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "wrong-zone failure activates deployment-area highlight", failures)
	_expect(screen._should_show_recommended_deploy_cell(2, 3), "wrong-zone failure highlights empty own deployment cells", failures)
	_expect(not screen._should_show_recommended_deploy_cell(5, 3), "wrong-zone failure does not highlight public cells", failures)
	var highlighted_button: Button = screen.cell_buttons[screen._cell_key(2, 3)]
	_expect(str(highlighted_button.text).contains("● 可上阵"), "highlighted cell shows recommendation text after failure", failures)
	var highlighted_style: StyleBoxFlat = highlighted_button.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(highlighted_style != null, "highlighted cell has style after failure", failures)
	if highlighted_style != null:
		_expect(highlighted_style.border_color.is_equal_approx(Color(1.0, 0.82, 0.24, 1.0)), "failure highlight uses gold border", failures)
		_expect(highlighted_style.get_border_width(SIDE_LEFT) >= 5, "failure highlight uses thick border", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "successful deployment clears failure highlight", failures)
	_expect(not screen._should_show_recommended_deploy_cell(1, 1), "successful deployment hides remaining recommendation cells", failures)

	screen.selected_hero_id = "zhouyu"
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "occupied click failure activates highlight helper path", failures)
	screen._advance_turn()
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "advancing turn clears failure highlight", failures)

	screen._reset_debug_battle()
	await process_frame
	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "failure highlight can reactivate after reset", failures)
	screen._reset_debug_battle()
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "reset clears failure highlight", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M51 deployment failure highlight checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
