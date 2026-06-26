extends SceneTree

const BootScene: PackedScene = preload("res://scenes/boot/Boot.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var boot = BootScene.instantiate()
	root.add_child(boot)
	await process_frame
	await process_frame

	await _check_home_to_battle(boot, failures)
	if boot.current_screen == null or boot.current_screen.name != "BattleScreen":
		_finish(boot, failures)
		return

	await _check_first_battle_steps(boot.current_screen, failures)
	_finish(boot, failures)


func _check_home_to_battle(boot: Node, failures: Array[String]) -> void:
	_expect(boot.current_screen != null, "boot loads initial screen", failures)
	_expect(boot.current_screen.name == "HomeScreen", "first-run path starts at home", failures)
	var battle_button: Button = boot.current_screen.find_child("BattleButton", true, false)
	_expect(battle_button != null, "home exposes battle entry", failures)
	if battle_button == null:
		return
	battle_button.pressed.emit()
	await process_frame
	await process_frame
	_expect(boot.current_screen != null, "battle entry loads a screen", failures)
	_expect(boot.current_screen.name == "BattleScreen", "battle entry routes directly to battle screen", failures)


func _check_first_battle_steps(screen: Control, failures: Array[String]) -> void:
	_expect(screen.first_deploy_hint_panel.visible, "first deploy hint is visible on first battle screen", failures)
	_expect(screen.tutorial_step_select_label.text.length() > 0, "tutorial progress shows select step", failures)

	screen.hero_buttons["zhouyu"].pressed.emit()
	await process_frame
	_expect(screen.selected_hero_id == "zhouyu", "tapping a hand card selects it", failures)
	_expect(screen.selected_card_hero_id == "zhouyu", "tapping a hand card opens inspected card", failures)
	_expect(screen.unit_detail_panel.visible, "tapping a hand card opens detail panel", failures)
	_expect(screen.first_deploy_hint_body.text.contains("周瑜"), "first deploy hint updates to selected hero", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	var deployed_unit: Dictionary = screen.battle_state.board.get_unit_at(2, 3)
	_expect(str(deployed_unit.get("hero_id", "")) == "zhouyu", "selected hero deploys into legal blue zone", failures)
	_expect(not screen.first_deploy_hint_panel.visible, "successful first deployment hides hint", failures)
	_expect(screen.battle_log_text.text.contains("部署") or screen.battle_log_text.text.contains("閮ㄧ讲"), "battle log records first deployment", failures)

	var side_before := str(screen.turn_controller.current_side)
	screen._advance_turn()
	await process_frame
	_expect(str(screen.turn_controller.current_side) != side_before, "advance turn changes active side after first deployment", failures)
	_expect(screen.status_label.text.length() > 0, "status label remains visible after advancing", failures)


func _finish(boot: Node, failures: Array[String]) -> void:
	if boot != null:
		boot.queue_free()
	if failures.is_empty():
		print("M61 first-run tutorial path checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
