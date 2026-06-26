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

	await _check_card_detail_density(screen, failures)
	await _check_unit_detail_density(screen, failures)
	_finish(screen, failures)


func _check_card_detail_density(screen: Control, failures: Array[String]) -> void:
	screen.hero_buttons["zhouyu"].pressed.emit()
	await process_frame
	_expect(screen.unit_detail_panel.visible, "hand card opens detail panel", failures)
	_expect(screen.unit_detail_title.text.contains("卡牌 - 周瑜 - 费用 *5 - 阵营 吴"), "card detail title carries cost and faction", failures)
	_expect(screen.unit_detail_title.text.find("法师") < 0, "card detail title hides class", failures)
	_expect(screen.unit_detail_body.text.contains("[b]点击反馈[/b]：已选中此手牌"), "card detail begins with click feedback", failures)
	_expect(screen.unit_detail_body.text.contains("星力不足时可先点「推进回合」回星"), "card detail gives recovery action", failures)
	_expect(screen.unit_detail_body.text.contains("赤壁灼烧"), "card detail keeps skill description", failures)


func _check_unit_detail_density(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "occupied cell opens unit detail panel", failures)
	_expect(screen.unit_detail_title.text.contains("> 周瑜 - 我方 - 100%"), "unit detail title carries direction side and hp percent", failures)
	_expect(screen.unit_detail_body.text.contains("[b]点击反馈[/b]：已选中场上单位"), "unit detail begins with click feedback", failures)
	_expect(screen.unit_detail_body.text.contains("[b]方向[/b]：向右推进"), "unit detail explains movement direction", failures)
	_expect(screen.unit_detail_body.text.contains("[b]生命[/b]") and screen.unit_detail_body.text.contains("（100%）"), "unit detail shows hp percent", failures)
	_expect(screen.unit_detail_body.text.contains("[b]技能[/b]"), "unit detail keeps skills section", failures)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M60 detail density feedback checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
