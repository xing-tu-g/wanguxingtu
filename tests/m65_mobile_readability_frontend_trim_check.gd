extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_large_text_and_bounds(screen, failures)
	_check_frontend_card_text(screen, failures)
	_check_backend_data_hidden(screen, failures)
	_finish(screen, failures)


func _check_large_text_and_bounds(screen: Control, failures: Array[String]) -> void:
	var advance_label: Label = screen.advance_turn_button.get_node("AdvanceText")
	_expect(_font_size(screen.status_label, "font_size") >= 22, "status text is readable on mobile", failures)
	_expect(_font_size(advance_label, "font_size") >= 24, "advance button text is readable", failures)
	_expect(screen.advance_turn_button.custom_minimum_size.y >= 150, "advance button has large touch height", failures)
	_expect(screen.grid.get_theme_constant("h_separation") <= 4, "board grid uses tight horizontal gap", failures)
	_expect(screen.get_node("UnitDetailPanel").offset_left >= -760, "detail panel remains within landscape width", failures)


func _check_frontend_card_text(screen: Control, failures: Array[String]) -> void:
	screen._update_hero_buttons()
	await process_frame
	var hero_id := str(screen.player_hand[0])
	var button: Button = screen.hero_buttons[hero_id]
	var name_label: Label = button.get_node("HandCardContainer/TopRow/NameLabel")
	var meta_label: Label = button.get_node("HandCardContainer/MetaLabel")
	var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
	_expect(not name_label.text.is_empty(), "hand card keeps hero name", failures)
	_expect(meta_label.text.contains("/"), "hand card shows compact faction/class row", failures)
	_expect(cost_label.text.is_valid_int(), "hand card shows icon-ready numeric fee", failures)
	_expect(not button.text.contains("阵营："), "hand card avoids raw long text", failures)
	button.pressed.emit()
	await process_frame
	_expect(screen.unit_detail_title.text.contains("阵营"), "card detail title shows faction", failures)


func _check_backend_data_hidden(screen: Control, failures: Array[String]) -> void:
	var detail: String = screen._format_card_zone_detail()
	_expect(detail.contains("后台数据"), "card zone explains hidden backend data", failures)
	_expect(not detail.contains("关羽") and not detail.contains("周瑜") and not detail.contains("张角"), "card zone detail hides exact card order/names", failures)


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
