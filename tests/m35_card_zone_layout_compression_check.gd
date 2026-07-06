extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_compact_card_zone_does_not_own_drawer_content(screen, failures)
	await _check_drawer_is_height_capped_when_open(screen, failures)
	_check_board_area_remains_visible_with_card_zone_open(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M35 card zone layout compression checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_compact_card_zone_does_not_own_drawer_content(screen: Control, failures: Array[String]) -> void:
	var card_zone_panel: PanelContainer = screen.get_node("BottomHand/CardZonePanel")
	_expect(card_zone_panel.custom_minimum_size.y <= 72.0, "compact card zone panel remains short", failures)
	_expect(screen.card_zone_detail_label.get_parent() != card_zone_panel, "detail label is not inside compact panel", failures)
	_expect(screen.card_zone_cards.get_parent() == screen.card_zone_scroll, "card rows live inside capped scroll", failures)


func _check_drawer_is_height_capped_when_open(screen: Control, failures: Array[String]) -> void:
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "card zone drawer is visible when expanded", failures)
	_expect(screen.card_zone_scroll.visible, "card zone scroll is visible when expanded", failures)
	_expect(screen.card_zone_scroll.custom_minimum_size.y <= 140.0, "card row scroll height is capped", failures)
	_expect(screen.card_zone_detail_label.custom_minimum_size.y <= 72.0, "card detail intro height is capped", failures)
	_expect(screen.card_inspect_label.custom_minimum_size.y <= 72.0, "card inspect height is capped", failures)


func _check_board_area_remains_visible_with_card_zone_open(screen: Control, failures: Array[String]) -> void:
	var battle_area: HBoxContainer = screen.get_node("DuelArea/CenterBoardStack/BattleArea")
	var board_panel: PanelContainer = screen.get_node("DuelArea/CenterBoardStack/BattleArea/BoardPanel")
	var first_cell: Button = screen.cell_buttons["1,1"]
	_expect(battle_area.size_flags_vertical == Control.SIZE_EXPAND_FILL, "battle area keeps expand-fill vertical priority", failures)
	_expect(board_panel.size_flags_vertical == Control.SIZE_EXPAND_FILL, "board panel keeps vertical expand-fill", failures)
	_expect(first_cell.size.y >= 88.0, "board cell touch height remains usable", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
