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

	_expect(screen.deploy_failure_toast_panel != null, "battle screen exposes deploy failure toast", failures)
	_expect(not screen.deploy_failure_toast_panel.visible, "deploy failure toast starts hidden", failures)

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "wrong-zone failure activates board highlight", failures)
	_expect(screen.deploy_failure_toast_panel.visible, "wrong-zone failure shows toast", failures)
	_expect(screen.deploy_failure_toast_label.text.contains("金边格就是当前可部署位置"), "toast explains gold cells", failures)
	_expect(not screen.status_label.text.contains("金边格就是当前可部署位置"), "status bar no longer carries long gold-cell explanation", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.deploy_failure_toast_panel.visible, "successful deployment hides toast", failures)

	screen.selected_hero_id = "zhouyu"
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	_expect(screen.deploy_failure_toast_panel.visible, "next deploy failure can show toast again", failures)
	screen._advance_turn()
	await process_frame
	_expect(not screen.deploy_failure_toast_panel.visible, "advancing turn hides toast", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(not screen.deploy_failure_toast_panel.visible, "reset keeps toast hidden", failures)

	_finish(screen, failures)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M55 deploy failure toast checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)