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
	_expect(screen.deploy_failure_toast_panel.visible, "toast appears after guided deployment failure", failures)
	_expect(screen.deploy_failure_toast_time_left > 0.0, "toast starts with positive lifetime", failures)
	_expect(is_equal_approx(screen.deploy_failure_toast_panel.modulate.a, 1.0), "toast starts fully opaque", failures)

	screen._process(screen.DEPLOY_FAILURE_TOAST_DURATION - 0.4)
	_expect(screen.deploy_failure_toast_panel.visible, "toast remains visible before lifetime ends", failures)
	_expect(screen.deploy_failure_toast_panel.modulate.a < 1.0, "toast fades near the end of lifetime", failures)

	screen._process(0.5)
	_expect(not screen.deploy_failure_toast_panel.visible, "toast auto hides after lifetime", failures)
	_expect(is_equal_approx(screen.deploy_failure_toast_panel.modulate.a, 1.0), "hidden toast resets opacity", failures)

	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_toast_panel.visible, "toast can be shown again after auto hide", failures)
	screen._hide_deploy_failure_toast()
	_expect(not screen.deploy_failure_toast_panel.visible, "manual hide still works", failures)
	_expect(is_equal_approx(screen.deploy_failure_toast_time_left, 0.0), "manual hide clears lifetime", failures)

	_finish(screen, failures)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M57 deploy failure toast auto-hide checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
