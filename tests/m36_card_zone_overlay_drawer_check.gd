extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	var failures: Array[String] = []
	await _check_overlay_is_outside_main_layout(failures)
	await _check_toggle_shows_and_hides_overlay(failures)
	await _check_overlay_cards_remain_clickable(failures)
	await process_frame

	if failures.is_empty():
		print("M36 card zone overlay drawer checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_overlay_is_outside_main_layout(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var card_zone_panel: PanelContainer = screen.get_node("Margin/Layout/BottomHandBar/CardZonePanel")
	var battle_area: HBoxContainer = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea")
	_expect(screen.card_zone_drawer_panel != null, "card zone overlay exists", failures)
	_expect(screen.card_zone_drawer_panel.get_parent() == screen, "overlay is rooted outside Margin/Layout flow", failures)
	_expect(screen.card_zone_detail_label.get_parent() != card_zone_panel, "detail label is not in compact panel layout", failures)
	_expect(screen.card_zone_cards.get_parent() == screen.card_zone_scroll, "card rows stay inside overlay scroll", failures)
	_expect(card_zone_panel.custom_minimum_size.y <= 64.0, "compact summary panel remains short", failures)
	_expect(battle_area.size_flags_vertical == Control.SIZE_EXPAND_FILL, "battle area keeps vertical expand priority", failures)
	screen.queue_free()


func _check_toggle_shows_and_hides_overlay(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(not screen.card_zone_drawer_panel.visible, "overlay hidden by default", failures)
	_expect(not screen.card_zone_scroll.visible, "overlay scroll hidden by default", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "overlay visible when expanded", failures)
	_expect(screen.card_zone_scroll.visible, "overlay scroll visible when expanded", failures)
	_expect(screen.card_zone_toggle_button.text == "收起牌区", "toggle label switches to collapse", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(not screen.card_zone_drawer_panel.visible, "overlay hidden after collapse", failures)
	_expect(screen.card_zone_toggle_button.text == "展开牌区", "toggle label switches to expand", failures)
	screen.queue_free()


func _check_overlay_cards_remain_clickable(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var zhouyu_button := _find_button(screen.card_zone_cards, "周瑜")
	_expect(zhouyu_button != null, "overlay card list contains zhouyu", failures)
	if zhouyu_button != null:
		zhouyu_button.pressed.emit()
		await process_frame
		_expect(screen.selected_card_hero_id == "zhouyu", "overlay card click updates selected card", failures)
		_expect(screen.card_inspect_label.text.find("赤壁灼烧") >= 0, "overlay inspect label updates skill text", failures)
	var first_cell: Button = screen.cell_buttons["1,1"]
	_expect(first_cell.custom_minimum_size.y >= 88.0, "board cell touch height remains unchanged", failures)
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


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
