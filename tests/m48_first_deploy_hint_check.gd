extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.first_deploy_hint_panel != null, "battle screen exposes first deploy hint panel", failures)
	_expect(screen.first_deploy_hint_panel.visible, "first deploy hint starts visible before any unit is deployed", failures)
	_expect(screen.first_deploy_hint_body.text.contains("点击底部手牌"), "hint explains selecting a bottom hand card", failures)
	_expect(screen.first_deploy_hint_body.text.contains("蓝色部署区 1-3 列"), "hint explains left blue deployment columns", failures)
	_expect(screen.first_deploy_hint_body.text.contains("关羽"), "hint mentions current selected hero", failures)

	screen.hero_buttons["zhouyu"].pressed.emit()
	await process_frame
	_expect(screen.first_deploy_hint_panel.visible, "selecting a card keeps deployment hint visible", failures)
	_expect(screen.first_deploy_hint_body.text.contains("周瑜"), "hint updates to newly selected hero", failures)

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	_expect(not screen.first_deploy_hint_panel.visible, "hint dismiss button hides first deploy hint", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(screen.first_deploy_hint_panel.visible, "reset restores first deploy hint", failures)

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.first_deploy_hint_panel.visible, "successful first deployment hides hint", failures)
	_expect(screen.battle_state.get_units_by_side("left").size() >= 1, "deployment still creates player unit", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M48 first deploy hint checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
