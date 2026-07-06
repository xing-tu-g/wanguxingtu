extends SceneTree

const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"
const BATTLE_LOG_VIEW_PATH := "res://scripts/ui/BattleLogView.gd"


func _init() -> void:
	var failures: Array[String] = []
	var screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	var log_view_source := FileAccess.get_file_as_string(BATTLE_LOG_VIEW_PATH)

	_expect(not screen_source.is_empty(), "BattleScreen.gd is readable", failures)
	_expect(not log_view_source.is_empty(), "BattleLogView.gd is readable", failures)
	_expect(log_view_source.contains("class_name BattleLogView"), "BattleLogView exposes a class name", failures)
	_expect(screen_source.contains("BattleLogView"), "BattleScreen references BattleLogView via class_name (global type)", failures)
	_expect(screen_source.contains("battle_log_view.setup("), "BattleScreen initializes BattleLogView", failures)
	_expect(screen_source.contains("func _add_battle_log"), "BattleScreen keeps add-log compatibility wrapper", failures)
	_expect(screen_source.contains("battle_log_view.add("), "add-log wrapper delegates to BattleLogView", failures)
	_expect(screen_source.contains("battle_log_view.compact_result("), "compact wrapper delegates to BattleLogView", failures)
	_expect(screen_source.contains("SHOW_BATTLE_LOG_IN_BATTLE := false"), "Battle log UI is disabled during battle", failures)
	_expect(screen_source.contains("result_payload[\"battle_log\"]"), "BattleScreen sends logs to result payload", failures)
	_expect(screen_source.contains("battle_log_view.close()"), "close wrapper delegates to BattleLogView", failures)
	_expect(screen_source.contains("visibility_changed.connect"), "BattleScreen connects to BattleLogView signal", failures)
	_expect(log_view_source.contains("func compact_result"), "BattleLogView owns compact-result logic", failures)

	if failures.is_empty():
		print("M75 battle log view split checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
