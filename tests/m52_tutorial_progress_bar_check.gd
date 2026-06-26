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
	_expect(screen.tutorial_progress_label != null, "battle screen exposes tutorial progress label", failures)
	_expect(screen.tutorial_progress_label.text == "新手流程", "progress title is compact Chinese label", failures)
	_expect(screen.tutorial_step_select_label.text.contains("✓ 选牌"), "initial selected hand card marks step one done", failures)
	_expect(screen.tutorial_step_deploy_label.text.contains("○ 点推荐格"), "initial progress waits for deployment", failures)
	_expect(screen.tutorial_step_turn_label.text.contains("○ 推进回合"), "initial progress waits for advancing turn", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.tutorial_step_deploy_label.text.contains("✓ 点推荐格"), "successful deployment marks recommendation step done", failures)
	_expect(screen.tutorial_step_turn_label.text.contains("○ 推进回合"), "deployment does not mark turn advance step", failures)

	screen._advance_turn()
	await process_frame
	_expect(screen.tutorial_step_turn_label.text.contains("✓ 推进回合"), "advancing turn marks final tutorial step done", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(screen.tutorial_step_select_label.text.contains("✓ 选牌"), "reset keeps selected available card step done", failures)
	_expect(screen.tutorial_step_deploy_label.text.contains("○ 点推荐格"), "reset clears deployment progress", failures)
	_expect(screen.tutorial_step_turn_label.text.contains("○ 推进回合"), "reset clears turn progress", failures)

	_finish(screen, failures)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M52 tutorial progress bar checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
