extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_overlay_is_outside_main_layout(screen, failures)
	await _check_toggle_shows_and_hides_overlay(screen, failures)
	await _check_overlay_cards_remain_clickable(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M36 card zone overlay drawer checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_overlay_is_outside_main_layout(screen: Control, failures: Array[String]) -> void:
	var card_zone_panel: PanelContainer = screen.get_node("BottomHand/CardZonePanel")
	var battle_area: HBoxContainer = screen.get_node("DuelArea/CenterBoardStack/BattleArea")
	_expect(screen.card_zone_drawer_panel != null, "card zone overlay exists", failures)
	_expect(screen.card_zone_drawer_panel.get_parent() == screen, "overlay is rooted outside main layout flow", failures)
	_expect(screen.card_zone_detail_label.get_parent() != card_zone_panel, "detail label is not in compact panel layout", failures)
	_expect(screen.card_zone_cards.get_parent() == screen.card_zone_scroll, "card rows stay inside overlay scroll", failures)
	_expect(card_zone_panel.custom_minimum_size.y <= 72.0, "compact summary panel remains short", failures)
	_expect(battle_area.size_flags_vertical == Control.SIZE_EXPAND_FILL, "battle area keeps vertical expand priority", failures)


func _check_toggle_shows_and_hides_overlay(screen: Control, failures: Array[String]) -> void:
	_expect(not screen.card_zone_drawer_panel.visible, "overlay hidden by default", failures)
	_expect(not screen.card_zone_scroll.visible, "overlay scroll hidden by default", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "overlay visible when expanded", failures)
	_expect(screen.card_zone_scroll.visible, "overlay scroll visible when expanded", failures)
	_expect(not screen.card_zone_view.collapsed, "card zone view marks expanded state", failures)
	screen._toggle_card_zone()
	await _wait_for_drawer_close(screen)
	_expect(not screen.card_zone_drawer_panel.visible, "overlay hidden after collapse animation", failures)
	_expect(screen.card_zone_view.collapsed, "card zone view marks collapsed state", failures)


func _check_overlay_cards_remain_clickable(screen: Control, failures: Array[String]) -> void:
	screen._toggle_card_zone()
	await process_frame
	var first_button := _first_button(screen.card_zone_cards)
	_expect(first_button != null, "overlay card list contains at least one card button", failures)
	if first_button != null:
		first_button.pressed.emit()
		await process_frame
		_expect(not screen.selected_card_hero_id.is_empty(), "overlay card click updates selected card", failures)
		_expect(not screen.card_inspect_label.text.is_empty(), "overlay inspect label updates", failures)
	var first_cell: Button = screen.cell_buttons["1,1"]
	_expect(first_cell.size.y >= 88.0, "board cell touch height remains usable", failures)


func _wait_for_drawer_close(screen: Control) -> void:
	for _index in range(12):
		await process_frame
		if not screen.card_zone_drawer_panel.visible:
			return


func _first_button(root_node: Node) -> Button:
	if root_node is Button:
		return root_node
	for child in root_node.get_children():
		var found := _first_button(child)
		if found != null:
			return found
	return null


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
