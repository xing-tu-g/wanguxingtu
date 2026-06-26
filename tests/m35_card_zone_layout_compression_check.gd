extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	var failures: Array[String] = []
	await _check_expanded_card_zone_is_height_capped(failures)
	await _check_board_area_remains_visible_with_card_zone_open(failures)
	await process_frame

	if failures.is_empty():
		print("M35 card zone layout compression checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_expanded_card_zone_is_height_capped(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var card_zone_panel: PanelContainer = screen.get_node("Margin/Layout/BottomHandBar/CardZonePanel")
	_expect(screen.card_zone_scroll != null, "card zone uses scroll container", failures)
	_expect(screen.card_zone_scroll.visible, "card zone scroll is visible when expanded", failures)
	_expect(screen.card_zone_scroll.custom_minimum_size.y <= 128.0, "card row scroll height is capped", failures)
	_expect(screen.card_zone_detail_label.custom_minimum_size.y <= 64.0, "card detail intro height is capped", failures)
	_expect(screen.card_inspect_label.custom_minimum_size.y <= 64.0, "card inspect height is capped", failures)
	_expect(card_zone_panel.custom_minimum_size.y <= 64.0, "collapsed card zone panel remains compact", failures)
	screen.queue_free()


func _check_board_area_remains_visible_with_card_zone_open(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var battle_area: HBoxContainer = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea")
	var board_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea/BoardPanel")
	var first_cell: Button = screen.cell_buttons["1,1"]
	_expect(battle_area.size_flags_vertical == Control.SIZE_EXPAND_FILL, "battle area keeps expand-fill vertical priority", failures)
	_expect(board_panel.size_flags_vertical == Control.SIZE_EXPAND_FILL, "board panel keeps vertical expand-fill", failures)
	_expect(first_cell.custom_minimum_size.y >= 88.0, "board cell touch height remains unchanged", failures)
	_expect(screen.card_zone_cards.get_parent() == screen.card_zone_scroll, "card rows live inside capped scroll", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
