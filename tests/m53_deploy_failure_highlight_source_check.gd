extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.get_script():
		failures.append("FAIL: battle screen script failed to load")
		_finish(screen, failures)
		return

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "wrong-zone failure activates highlight", failures)
	_expect(screen.deploy_failure_toast_label.text.contains("金边格就是当前可部署位置"), "failure toast explains gold highlighted cells", failures)
	_expect(not screen.status_label.text.contains("部署失败"), "top HUD does not carry battle-event failure text", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "successful deployment clears highlight", failures)
	_expect(not screen.status_label.text.contains("金边格就是当前可部署位置"), "success status removes highlight source text", failures)

	screen.selected_hero_id = "zhouyu"
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	_expect(screen.deploy_failure_toast_label.text.contains("金边格就是当前可部署位置"), "low-star or occupied failure still explains gold cells in toast", failures)
	screen._advance_turn()
	await process_frame
	_expect(not screen.deploy_failure_toast_panel.visible, "turn summary clears highlight source toast", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(not screen.status_label.text.contains("金边格就是当前可部署位置"), "reset status does not keep highlight source text", failures)

	_finish(screen, failures)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M53 deployment failure highlight source checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
