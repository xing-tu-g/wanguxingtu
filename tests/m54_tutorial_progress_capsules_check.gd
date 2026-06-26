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

	_expect(screen.tutorial_progress_row != null, "battle screen exposes tutorial progress row", failures)
	_expect(screen.tutorial_step_select_label != null, "progress row has select-card capsule", failures)
	_expect(screen.tutorial_step_deploy_label != null, "progress row has deployment capsule", failures)
	_expect(screen.tutorial_step_turn_label != null, "progress row has turn capsule", failures)
	_expect(screen.tutorial_progress_row.custom_minimum_size.x >= 540.0, "progress capsules reserve readable landscape width", failures)
	_expect(screen.tutorial_step_select_label.text.contains("✓ 选牌"), "select capsule starts complete", failures)
	_expect(screen.tutorial_step_deploy_label.text.contains("○ 点推荐格"), "deploy capsule starts pending", failures)
	_expect(screen.tutorial_step_turn_label.text.contains("○ 推进回合"), "turn capsule starts pending", failures)
	_expect(_style(screen.tutorial_step_select_label).get_corner_radius(CORNER_TOP_LEFT) >= 16, "select capsule has rounded style", failures)
	_expect(_style(screen.tutorial_step_select_label).border_color != _style(screen.tutorial_step_deploy_label).border_color, "complete and pending capsules use different borders", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.tutorial_step_deploy_label.text.contains("✓ 点推荐格"), "deploy capsule completes after successful deployment", failures)
	_expect(_style(screen.tutorial_step_deploy_label).border_color == _style(screen.tutorial_step_select_label).border_color, "completed deploy capsule uses done border", failures)

	screen._advance_turn()
	await process_frame
	_expect(screen.tutorial_step_turn_label.text.contains("✓ 推进回合"), "turn capsule completes after advancing turn", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(screen.tutorial_step_deploy_label.text.contains("○ 点推荐格"), "reset clears deploy capsule", failures)
	_expect(screen.tutorial_step_turn_label.text.contains("○ 推进回合"), "reset clears turn capsule", failures)

	_finish(screen, failures)


func _style(label: Label) -> StyleBoxFlat:
	return label.get_theme_stylebox("normal") as StyleBoxFlat


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M54 tutorial progress capsule checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)