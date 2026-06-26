extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.status_label.text.contains("不是我方蓝色部署区"), "public-zone failure explains wrong zone", failures)
	_expect(screen.status_label.text.contains("左侧 1-3 列"), "wrong-zone failure points to left deployment columns", failures)
	_expect(screen.status_label.text.contains("关羽"), "wrong-zone failure mentions selected hero", failures)
	_expect(_last_log(screen).contains("部署失败") and _last_log(screen).contains("非蓝区"), "battle log records compact wrong-zone failure", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.battle_state.get_units_by_side("left").size() >= 1, "valid deployment still succeeds", failures)

	screen.selected_hero_id = "zhouyu"
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	_expect(screen.status_label.text.contains("星力不足"), "low-star failure explains insufficient star power", failures)
	_expect(screen.status_label.text.contains("周瑜 需要 5 星力"), "low-star failure shows selected card cost", failures)
	_expect(screen.status_label.text.contains("当前只有 0"), "low-star failure shows current star power", failures)
	_expect(screen.status_label.text.contains("推进回合"), "low-star failure suggests advancing turn", failures)

	screen._reset_debug_battle()
	await process_frame
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	screen.selected_hero_id = "zhouyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "occupied cell still opens unit detail", failures)
	_expect(screen.status_label.text.contains("正在查看"), "occupied board click keeps existing detail-view behavior", failures)
	var occupied_message: String = screen._deployment_failure_message("cell_occupied", "zhouyu", 2, 3)
	_expect(occupied_message.contains("目标格 (2,3) 已有单位"), "occupied helper message names occupied cell", failures)
	_expect(occupied_message.contains("其他空格"), "occupied helper message suggests another empty cell", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M49 deployment failure guidance checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _last_log(screen: Control) -> String:
	if screen.battle_log_entries.is_empty():
		return ""
	return str(screen.battle_log_entries[screen.battle_log_entries.size() - 1])


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
