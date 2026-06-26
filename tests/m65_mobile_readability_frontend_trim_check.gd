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

	_check_large_text_and_bounds(screen, failures)
	_check_frontend_card_text(screen, failures)
	_check_backend_data_hidden(screen, failures)
	_finish(screen, failures)


func _check_large_text_and_bounds(screen: Control, failures: Array[String]) -> void:
	_expect(_font_size(screen.status_label, "font_size") >= 28, "status text is readable on mobile", failures)
	_expect(_font_size(screen.advance_turn_button, "font_size") >= 30, "advance button text is readable", failures)
	_expect(screen.advance_turn_button.custom_minimum_size.y >= 112, "advance button has large touch height", failures)
	_expect(screen.grid.get("theme_override_constants/h_separation") <= 4, "board grid uses tighter horizontal gap", failures)
	_expect(screen.get_node("Margin").offset_left <= 18, "outer margin gives more screen space", failures)
	_expect(screen.get_node("UnitDetailPanel").offset_left >= -700, "detail panel remains within landscape width", failures)


func _check_frontend_card_text(screen: Control, failures: Array[String]) -> void:
	screen._update_hero_buttons()
	await process_frame
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	_expect(zhouyu_button.text.contains("周瑜"), "hand card keeps hero name", failures)
	_expect(zhouyu_button.text.contains("吴"), "hand card shows faction short tag", failures)
	_expect(not zhouyu_button.text.contains("阵营："), "hand card avoids long faction prefix", failures)
	_expect(not _contains_class_words(zhouyu_button.text), "hand card hides invented class words", failures)
	screen.hero_buttons["zhouyu"].pressed.emit()
	await process_frame
	_expect(screen.unit_detail_title.text.contains("阵营 吴"), "card detail title shows faction", failures)
	_expect(not _contains_class_words(screen.unit_detail_title.text + "\n" + screen.unit_detail_body.text), "card detail hides class words", failures)
	var unit_data: Dictionary = {"hero_id":"zhouyu", "name":"周瑜", "faction":"wu", "side":screen.BoardModelScript.SIDE_LEFT, "hp":30, "max_hp":30, "column":1, "row":1}
	var cell_text: String = screen._format_cell_text(1, 1, unit_data)
	_expect(cell_text.contains("吴"), "unit cell shows faction", failures)
	_expect(not _contains_class_words(cell_text), "unit cell hides class words", failures)


func _check_backend_data_hidden(screen: Control, failures: Array[String]) -> void:
	var detail: String = screen._format_card_zone_detail()
	_expect(detail.contains("详细牌序属于后台数据"), "card zone explains hidden backend data", failures)
	_expect(not detail.contains("关羽") and not detail.contains("周瑜") and not detail.contains("张角"), "card zone detail hides exact card order/names", failures)


func _contains_class_words(text: String) -> bool:
	for word in ["职业", "战士", "法师", "坦克", "射手", "武卫", "刺客", "吴·", "蜀·", "魏·", "群·", "弓", "盾"]:
		if text.contains(word):
			return true
	return false


func _font_size(control: Control, key: String) -> int:
	return int(control.get_theme_font_size(key))


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M65 mobile readability and frontend trim checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
