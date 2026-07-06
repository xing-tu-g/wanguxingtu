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
	_expect(screen_source.contains("func _board_get_terrain"), "BattleScreen exposes terrain callback", failures)
	_expect(screen_source.contains("func _board_is_selected_cell"), "BattleScreen exposes selected-cell UI callback", failures)
	_expect(screen_source.contains("func _board_is_recommended_deploy_cell"), "BattleScreen exposes deploy-hover UI callback", failures)
	_expect(screen_source.contains("TerrainSystemScript.TERRAIN_GRASS"), "terrain callback falls back to grass for invalid values", failures)
	_expect(screen_source.contains('preload("res://scripts/ui/theme/BattleUIAssets.gd")'), "BattleScreen preloads battle UI assets", failures)
	_expect(board_view_source.contains('preload("res://scripts/ui/theme/BattleUIAssets.gd")'), "BattleBoardView preloads battle UI assets", failures)
	_expect(board_view_source.contains("func build"), "BattleBoardView owns cell button creation", failures)
	_expect(board_view_source.contains("func refresh"), "BattleBoardView owns cell refresh loop", failures)
	_expect(board_view_source.contains("deploy_callback.bind(column, row)"), "BattleBoardView wires cell clicks through callback", failures)
	_expect(board_view_source.contains("func _zone_for_cell"), "BattleBoardView computes zones without non-static BoardModel calls", failures)
	_expect(board_view_source.contains("GridBackplate"), "BattleBoardView renders grid art as TextureRect backplates", failures)

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
