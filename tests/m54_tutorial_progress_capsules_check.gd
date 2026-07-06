extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.tutorial_progress_row != null, "battle screen still exposes tutorial progress row for compatibility", failures)
	_expect(screen.tutorial_step_select_label != null, "progress row has select-card capsule node", failures)
	_expect(screen.tutorial_step_deploy_label != null, "progress row has deployment capsule node", failures)
	_expect(screen.tutorial_step_turn_label != null, "progress row has turn capsule node", failures)
	_expect(not screen.tutorial_progress_row.visible, "debug-style tutorial progress capsules are hidden in battle HUD", failures)

	var hint_title: Label = screen.get_node("FirstDeployHintPanel/HintMargin/HintLayout/HintTitle")
	_expect(screen.first_deploy_hint_panel.visible, "compact first-deploy hint replaces top capsules", failures)
	_expect(hint_title.text.contains("点击手牌"), "compact hint names hand-card action", failures)
	_expect(hint_title.text.contains("蓝色近端星格"), "compact hint names deployment cells", failures)
	_expect(hint_title.text.contains("推进回合"), "compact hint names turn action", failures)
	_expect(screen.first_deploy_hint_panel.size.y <= 160.0, "compact hint stays short", failures)

	screen.queue_free()
	await process_frame
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
