extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.get_script():
		failures.append("FAIL: battle screen script failed to load")
		_finish(screen, failures)
		return

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_check_failed_deploy_log(screen, failures)

	screen._deploy_selected_to_cell(3, 3)
	await process_frame
	_check_success_deploy_log(screen, failures)

	screen._advance_turn()
	await process_frame
	_check_turn_log(screen, failures)
	_finish(screen, failures)


func _check_failed_deploy_log(screen: Control, failures: Array[String]) -> void:
	var latest: String = _latest_log(screen)
	_expect(latest.begins_with("R1 - 关羽 - 部署失败 - "), "failed deploy log uses compact prefix", failures)
	_expect(latest.contains("部署失败"), "failed deploy log keeps failure keyword", failures)
	_expect(latest.length() <= 72, "failed deploy log is short enough for drawer", failures)


func _check_success_deploy_log(screen: Control, failures: Array[String]) -> void:
	var latest: String = _latest_log(screen)
	_expect(latest.begins_with("R1 - 关羽 - 部署 - "), "success deploy log uses compact prefix", failures)
	_expect(latest.contains("消耗"), "success deploy log keeps cost keyword", failures)
	_expect(latest.length() <= 72, "success deploy log is short enough for drawer", failures)


func _check_turn_log(screen: Control, failures: Array[String]) -> void:
	var log_text: String = screen.battle_log_text.text
	_expect(log_text.contains("R1 - 我方 - 回合开始 - "), "turn start log uses compact prefix", failures)
	_expect(log_text.contains("移动") or log_text.contains("攻击") or log_text.contains("移动后攻击"), "action keywords remain visible", failures)
	for line in log_text.split("\n"):
		var line_text: String = String(line)
		if not line_text.is_empty():
			_expect(line_text.length() <= 82, "compact log line stays within mobile-friendly width: %s" % line_text, failures)
	_expect(screen.battle_log_entries.size() <= 20, "battle log still caps latest lines", failures)


func _latest_log(screen: Control) -> String:
	if screen.battle_log_entries.is_empty():
		return ""
	return str(screen.battle_log_entries[screen.battle_log_entries.size() - 1])


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M63 compact battle log checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
