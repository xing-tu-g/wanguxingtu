extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	await _check_hand_card_opens_detail(screen, failures)
	await _check_selection_keeps_deploy_flow(screen, failures)
	await _check_board_unit_detail_overrides_card_detail(screen, failures)
	await process_frame

	screen.queue_free()
	if failures.is_empty():
		print("M44 hand card detail overlay checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hand_card_opens_detail(screen: Control, failures: Array[String]) -> void:
	screen.hero_buttons["zhouyu"].pressed.emit()
	await process_frame
	_expect(screen.selected_hero_id == "zhouyu", "clicking bottom hand card still selects hero", failures)
	_expect(screen.selected_card_hero_id == "zhouyu", "clicking bottom hand card syncs inspected card", failures)
	_expect(screen.unit_detail_panel.visible, "clicking bottom hand card opens detail overlay", failures)
	_expect(screen.unit_detail_title.text.contains("卡牌 - 周瑜") and screen.unit_detail_title.text.contains("费用 *5"), "detail title identifies card detail", failures)
	_expect(screen.unit_detail_body.text.find("[b]部署提示[/b]") >= 0, "card detail shows deployment hint", failures)
	_expect(screen.unit_detail_body.text.find("[b]费用[/b]：5 星力｜[b]阵营[/b]：吴") >= 0, "card detail shows cost and faction", failures)
	_expect(screen.unit_detail_body.text.find("职业") < 0 and screen.unit_detail_body.text.find("法师") < 0, "card detail hides class", failures)
	_expect(screen.unit_detail_body.text.find("赤壁灼烧") >= 0, "card detail shows skill description", failures)


func _check_selection_keeps_deploy_flow(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.battle_state.board.get_unit_at(2, 3).get("hero_id", "") == "zhouyu", "selected card can still deploy after detail opens", failures)
	_expect(not screen.unit_detail_panel.visible, "successful deploy hides card detail overlay", failures)
	_expect(str(screen.hero_buttons["zhouyu"].text).find("已出") >= 0, "deployed hand card becomes spent", failures)


func _check_board_unit_detail_overrides_card_detail(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "clicking occupied board cell opens unit detail", failures)
	_expect(screen.unit_detail_title.text.find("周瑜") >= 0 and screen.unit_detail_title.text.find("卡牌 - ") == -1, "board unit detail replaces card detail title", failures)
	_expect(screen.unit_detail_body.text.find("[b]位置[/b]：(2,3)") >= 0, "board unit detail shows position", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
