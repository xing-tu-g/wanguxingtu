extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_initial_hud(screen, failures)
	screen._advance_turn()
	await process_frame
	_check_after_turn_hud(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M94 HUD information architecture checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_hud(screen: Control, failures: Array[String]) -> void:
	_expect(screen.status_label.text.contains("第"), "core status shows turn count", failures)
	_expect(screen.status_label.text.contains("行动"), "core status shows active side", failures)
	_expect(screen.status_label.text.length() <= 24, "core status stays short", failures)
	_expect(screen.star_label.text.contains("星力"), "resource label shows star power", failures)
	_expect(screen.star_label.text.contains("星潮"), "resource label shows star tide", failures)
	_expect(_has_phase_tag(screen.star_label.text), "resource label carries rhythm phase tag", failures)
	_expect(not _contains_battle_event(screen.status_label.text), "core status excludes battle events", failures)
	_expect(not _contains_battle_event(screen.star_label.text), "resource/rhythm label excludes battle events", failures)
	_expect(not screen.toggle_log_button.visible, "battle log button is not part of battle HUD", failures)
	_expect(not screen.log_panel.visible, "battle log panel is not part of battle HUD", failures)


func _check_after_turn_hud(screen: Control, failures: Array[String]) -> void:
	_expect(screen.status_label.text.length() <= 24, "core status remains short after turn advance", failures)
	_expect(screen.star_label.text.length() <= 36, "resource/rhythm label remains one-line compact", failures)
	_expect(not screen.star_label.text.contains("\n"), "resource/rhythm label does not use second HUD line", failures)
	_expect(not _contains_battle_event(screen.status_label.text), "core status still excludes battle events after turn", failures)
	_expect(not _contains_battle_event(screen.star_label.text), "resource/rhythm label still excludes battle events after turn", failures)
	_expect(not screen.log_panel.visible, "battle log panel remains hidden after turn", failures)


func _has_phase_tag(text: String) -> bool:
	return text.contains("前期") or text.contains("中期") or text.contains("后期")


func _contains_battle_event(text: String) -> bool:
	for token in ["自动部署", "共 ", "单位行动", "下一步", "部署失败", "已部署到", "抽到"]:
		if text.contains(token):
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
