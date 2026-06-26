extends SceneTree

const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"
const BATTLE_BOARD_VIEW_PATH := "res://scripts/ui/BattleBoardView.gd"


func _init() -> void:
	var failures: Array[String] = []
	var screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	var board_view_source := FileAccess.get_file_as_string(BATTLE_BOARD_VIEW_PATH)

	_expect(not screen_source.is_empty(), "BattleScreen.gd is readable", failures)
	_expect(not board_view_source.is_empty(), "BattleBoardView.gd is readable", failures)
	_expect(board_view_source.contains("class_name BattleBoardView"), "BattleBoardView exposes a class name", failures)
	_expect(screen_source.contains('preload("res://scripts/ui/BattleBoardView.gd")'), "BattleScreen preloads BattleBoardView", failures)
	_expect(screen_source.contains("battle_board_view.setup("), "BattleScreen initializes BattleBoardView", failures)
	_expect(screen_source.contains("func _build_board"), "BattleScreen keeps build-board compatibility wrapper", failures)
	_expect(screen_source.contains("battle_board_view.build("), "build-board wrapper delegates to BattleBoardView", failures)
	_expect(screen_source.contains("func _refresh_board"), "BattleScreen keeps refresh-board compatibility wrapper", failures)
	_expect(screen_source.contains("battle_board_view.refresh("), "refresh-board wrapper delegates to BattleBoardView", failures)
	_expect(screen_source.contains("func _board_unit_at"), "BattleScreen exposes board data callback", failures)
	_expect(board_view_source.contains("func build"), "BattleBoardView owns cell button creation", failures)
	_expect(board_view_source.contains("func refresh"), "BattleBoardView owns cell refresh loop", failures)
	_expect(board_view_source.contains("deploy_callback.bind(column, row)"), "BattleBoardView wires cell clicks through callback", failures)

	if failures.is_empty():
		print("M77 battle board view split checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
