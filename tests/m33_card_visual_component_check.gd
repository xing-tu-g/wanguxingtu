extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	await _check_card_button_visual_fields(failures)
	await _check_selected_card_has_stronger_border_and_marker(failures)
	await _check_clicking_visual_card_keeps_inspect_behavior(failures)
	await process_frame

	if failures.is_empty():
		print("M33 card visual component checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_card_button_visual_fields(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var guanyu_button := _find_button(screen.card_zone_cards, "关羽")
	_expect(guanyu_button != null, "guanyu visual card button exists", failures)
	if guanyu_button != null:
		_expect(guanyu_button.custom_minimum_size.x >= 188.0, "visual card button is wider than text chip", failures)
		_expect(guanyu_button.custom_minimum_size.y >= 72.0, "visual card button is taller than text chip", failures)
		_expect(guanyu_button.text.find("费5") >= 0, "visual card shows fee badge text", failures)
		_expect(guanyu_button.text.find("阵营：蜀") >= 0, "visual card shows faction row", failures)
		_expect(not _contains_class_or_damage_copy(guanyu_button.text), "visual card hides class and damage labels", failures)
		_expect(guanyu_button.alignment == HORIZONTAL_ALIGNMENT_LEFT, "visual card text is left aligned", failures)
	screen.queue_free()


func _check_selected_card_has_stronger_border_and_marker(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var guanyu_button := _find_button(screen.card_zone_cards, "关羽")
	var zhouyu_button := _find_button(screen.card_zone_cards, "周瑜")
	_expect(guanyu_button != null and zhouyu_button != null, "selected and unselected visual buttons exist", failures)
	if guanyu_button != null and zhouyu_button != null:
		_expect(str(guanyu_button.text).begins_with("> "), "selected card keeps selection marker", failures)
		var selected_style := guanyu_button.get_theme_stylebox("normal") as StyleBoxFlat
		var normal_style := zhouyu_button.get_theme_stylebox("normal") as StyleBoxFlat
		_expect(selected_style != null and normal_style != null, "visual card styleboxes are applied", failures)
		if selected_style != null and normal_style != null:
			_expect(selected_style.border_width_left > normal_style.border_width_left, "selected card has stronger border", failures)
			_expect(normal_style.corner_radius_top_left >= 12, "visual card has rounded corners", failures)
	screen.queue_free()


func _check_clicking_visual_card_keeps_inspect_behavior(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var zhouyu_button := _find_button(screen.card_zone_cards, "周瑜")
	_expect(zhouyu_button != null, "zhouyu visual card button exists", failures)
	if zhouyu_button != null:
		zhouyu_button.pressed.emit()
		await process_frame
		_expect(screen.selected_card_hero_id == "zhouyu", "clicking visual card still selects hero", failures)
		_expect(screen.card_inspect_label.text.find("赤壁灼烧") >= 0, "clicking visual card still updates inspect panel", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _find_button(root_node: Node, text_fragment: String) -> Button:
	if root_node is Button and str(root_node.text).find(text_fragment) >= 0:
		return root_node
	for child in root_node.get_children():
		var found := _find_button(child, text_fragment)
		if found != null:
			return found
	return null


func _contains_class_or_damage_copy(text: String) -> bool:
	for forbidden in ["职业", "战士", "法师", "坦克", "射手", "武卫", "刺客", "物理", "法术", "弓", "盾"]:
		if text.find(forbidden) >= 0:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
