extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var hero_id := _first_affordable_hand_hero(screen)
	screen.selected_hero_id = hero_id
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_check_failed_deploy_log(screen, failures)

	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_check_success_deploy_log(screen, failures)

	screen._advance_turn()
	await process_frame
	_check_turn_log(screen, failures)
	_finish(screen, failures)


func _check_failed_deploy_log(screen: Control, failures: Array[String]) -> void:
	var latest: String = _latest_log(screen)
	_expect(latest.contains("部署失败"), "failed deploy log keeps failure keyword", failures)
	_expect(latest.contains("蓝色近端"), "failed deploy log keeps guidance keyword", failures)
	_expect(latest.length() <= 96, "failed deploy log is short enough for drawer", failures)


func _check_success_deploy_log(screen: Control, failures: Array[String]) -> void:
	var latest: String = _latest_log_matching(screen, ["部署"])
	_expect(latest.contains("部署"), "success deploy log keeps deploy keyword", failures)
	_expect(latest.contains("消耗") or latest.contains("星力"), "success deploy log keeps cost keyword", failures)
	_expect(latest.length() <= 96, "success deploy log is short enough for drawer", failures)


func _check_turn_log(screen: Control, failures: Array[String]) -> void:
	var log_text: String = "\n".join(screen.battle_log_entries)
	_expect(log_text.contains("回合开始") or log_text.contains("移动") or log_text.contains("攻击"), "turn/action keywords remain recorded for report replay", failures)
	_expect(screen.battle_log_text.text.is_empty(), "compact log text is not rendered during battle", failures)
	_expect(not screen.log_panel.visible, "compact log stays hidden during battle", failures)
	for line in log_text.split("\n"):
		var line_text: String = String(line)
		if not line_text.is_empty():
			_expect(line_text.length() <= 110, "compact log line stays within mobile-friendly width: %s" % line_text, failures)
	_expect(screen.battle_log_entries.size() <= 20, "battle log still caps latest lines", failures)


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return ""


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _latest_log(screen: Control) -> String:
	if screen.battle_log_entries.is_empty():
		return ""
	return str(screen.battle_log_entries[screen.battle_log_entries.size() - 1])


func _latest_log_matching(screen: Control, needles: Array[String]) -> String:
	for index in range(screen.battle_log_entries.size() - 1, -1, -1):
		var line := str(screen.battle_log_entries[index])
		for needle in needles:
			if line.contains(needle):
				return line
	return ""


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
