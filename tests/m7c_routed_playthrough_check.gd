extends SceneTree

const BootScene: PackedScene = preload("res://scenes/boot/Boot.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var boot = BootScene.instantiate()
	root.add_child(boot)
	await process_frame
	await process_frame

	_expect(boot.current_screen != null, "boot loads an initial screen", failures)
	_expect(boot.current_screen.name == "HomeScreen", "boot starts at home screen", failures)

	var home_screen: Control = boot.current_screen
	var battle_button: Button = home_screen.find_child("BattleButton", true, false)
	_expect(battle_button != null, "home screen exposes the battle button", failures)
	if battle_button == null:
		_finish(boot, failures)
		return
	battle_button.pressed.emit()
	await process_frame
	await process_frame

	_expect(boot.current_screen != null, "battle route loads a screen", failures)
	_expect(boot.current_screen.name == "BattleScreen", "home battle button routes directly to battle screen", failures)
	var battle_screen: Control = boot.current_screen
	_expect(battle_screen.cell_buttons.size() == 50, "routed battle screen builds the board", failures)
	_expect(not battle_screen.log_panel.visible, "routed battle screen keeps battle report drawer hidden by default", failures)
	battle_screen._toggle_battle_log()
	await process_frame
	_expect(battle_screen.log_panel.visible, "routed battle screen can open battle report drawer", failures)
	battle_screen._toggle_battle_log()
	await process_frame

	battle_screen.selected_hero_id = "guanyu"
	battle_screen._deploy_selected_to_cell(3, 3)
	await process_frame
	_expect(battle_screen.battle_state.get_units_by_side("left").size() >= 1, "playthrough can deploy from routed battle", failures)

	_force_battle_result(battle_screen)
	battle_screen._advance_turn()
	await process_frame
	await process_frame
	if boot.current_screen == battle_screen:
		failures.append("FAIL: finished battle did not route away from battle screen")
		_finish(boot, failures)
		return

	_expect(boot.current_screen != null, "battle result routes to a screen", failures)
	_expect(boot.current_screen.name == "ResultScreen", "finished battle routes to result screen", failures)
	var result_screen: Control = boot.current_screen
	_expect(result_screen.result_data.get("outcome", "") == "left_wins", "result screen receives battle outcome", failures)
	var title_label: Label = result_screen.get_node("Margin/Layout/Title")
	_expect(title_label.text == "我方胜利", "result screen formats the win title", failures)

	var home_button: Button = result_screen.get_node("Margin/Layout/HomeButton")
	home_button.pressed.emit()
	await process_frame
	await process_frame
	_expect(boot.current_screen != null, "home route loads after result", failures)
	_expect(boot.current_screen.name == "HomeScreen", "result home button returns to home screen", failures)

	boot.queue_free()
	_finish(null, failures)


func _force_battle_result(battle_screen: Control) -> void:
	battle_screen.battle_state.master_hp["right"] = 0


func _finish(boot, failures: Array[String]) -> void:
	if boot != null:
		boot.queue_free()
	if failures.is_empty():
		print("M7c routed playthrough checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
