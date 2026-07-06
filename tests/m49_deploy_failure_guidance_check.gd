extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var hero_id := _first_affordable_hand_hero(screen)
	screen.selected_hero_id = hero_id
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	var wrong_zone_message: String = screen._deployment_failure_message("not_own_deployment_zone", hero_id, 5, 3)
	_expect(wrong_zone_message.contains("不是我方蓝色近端部署格"), "public-zone helper explains wrong zone", failures)
	_expect(wrong_zone_message.contains("左侧蓝色近端空格"), "wrong-zone helper points to left near deployment cells", failures)
	_expect(wrong_zone_message.contains(screen._hero_name(hero_id)), "wrong-zone helper mentions selected hero", failures)
	_expect(_last_log(screen).contains("部署失败") and _last_log(screen).contains("蓝色近端"), "battle log records compact wrong-zone failure", failures)

	var cell := _first_deploy_cell(screen)
	screen.selected_hero_id = hero_id
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(screen.battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).size() >= 1, "valid deployment still succeeds", failures)

	var expensive_id := _first_unaffordable_hand_hero(screen)
	if expensive_id != "":
		var empty_cell := _first_deploy_cell(screen)
		screen.selected_hero_id = expensive_id
		screen._deploy_selected_to_cell(empty_cell.x, empty_cell.y)
		await process_frame
		var low_star_message: String = screen._deployment_failure_message("not_enough_star_power", expensive_id, empty_cell.x, empty_cell.y)
		_expect(low_star_message.contains("星力不足"), "low-star helper explains insufficient star power", failures)
		_expect(low_star_message.contains(screen._hero_name(expensive_id)), "low-star helper names selected card", failures)
		_expect(low_star_message.contains("当前只有"), "low-star helper shows current star power", failures)

	screen._reset_debug_battle()
	await process_frame
	hero_id = _first_affordable_hand_hero(screen)
	cell = _first_deploy_cell(screen)
	screen.selected_hero_id = hero_id
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	var occupied_message: String = screen._deployment_failure_message("cell_occupied", hero_id, cell.x, cell.y)
	_expect(occupied_message.contains("目标格 (%d,%d) 已有单位" % [cell.x, cell.y]), "occupied helper message names occupied cell", failures)
	_expect(occupied_message.contains("其他空格"), "occupied helper message suggests another empty cell", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M49 deployment failure guidance checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return ""


func _first_unaffordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if not screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return ""


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _last_log(screen: Control) -> String:
	if screen.battle_log_entries.is_empty():
		return ""
	return str(screen.battle_log_entries[screen.battle_log_entries.size() - 1])


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
