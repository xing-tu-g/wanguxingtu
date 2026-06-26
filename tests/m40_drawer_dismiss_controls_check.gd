extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	await _check_card_zone_close_button(failures)
	await _check_log_close_button(failures)
	await _check_shared_overlay_dismisses_drawers(failures)
	await _check_drawers_do_not_reflow_battle_layout(failures)
	await process_frame

	if failures.is_empty():
		print("M40 drawer dismiss controls checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_card_zone_close_button(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.has_node("CardZoneDrawerPanel/DrawerMargin/DrawerLayout/DrawerHeader/CardZoneCloseButton"), "card drawer has a close button", failures)
	_expect(screen.card_zone_close_button.text == "关闭", "card drawer close button is localized", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "card drawer opens before close-button check", failures)
	_expect(screen.overlay_dismiss_button.visible, "overlay mask appears with card drawer", failures)
	screen.card_zone_close_button.pressed.emit()
	await process_frame
	_expect(not screen.card_zone_drawer_panel.visible, "card drawer close button hides drawer", failures)
	_expect(not screen.overlay_dismiss_button.visible, "overlay mask hides after card drawer closes", failures)
	_expect(screen.card_zone_toggle_button.text == "展开牌区", "card toggle label resets after close button", failures)
	screen.queue_free()


func _check_log_close_button(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.has_node("LogPanel/LogMargin/LogLayout/LogHeader/LogCloseButton"), "log drawer has a close button", failures)
	_expect(screen.log_close_button.text == "关闭", "log close button is localized", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(screen.log_panel.visible, "log drawer opens before close-button check", failures)
	_expect(screen.overlay_dismiss_button.visible, "overlay mask appears with log drawer", failures)
	screen.log_close_button.pressed.emit()
	await process_frame
	_expect(not screen.log_panel.visible, "log close button hides drawer", failures)
	_expect(not screen.overlay_dismiss_button.visible, "overlay mask hides after log drawer closes", failures)
	_expect(screen.toggle_log_button.text == "战报", "log toggle label resets after close button", failures)
	screen.queue_free()


func _check_shared_overlay_dismisses_drawers(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	screen._toggle_battle_log()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "card drawer opens before mask dismissal", failures)
	_expect(screen.log_panel.visible, "log drawer opens before mask dismissal", failures)
	_expect(screen.overlay_dismiss_button.visible, "overlay mask appears when any drawer opens", failures)
	screen.overlay_dismiss_button.pressed.emit()
	await process_frame
	_expect(not screen.card_zone_drawer_panel.visible, "overlay mask closes card drawer", failures)
	_expect(not screen.log_panel.visible, "overlay mask closes log drawer", failures)
	_expect(not screen.overlay_dismiss_button.visible, "overlay mask hides after closing all drawers", failures)
	screen.queue_free()


func _check_drawers_do_not_reflow_battle_layout(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var duel_area: HBoxContainer = screen.get_node("Margin/Layout/DuelArea")
	var bottom_hand_bar: HBoxContainer = screen.get_node("Margin/Layout/BottomHandBar")
	var duel_min_height := duel_area.custom_minimum_size.y
	var bottom_min_height := bottom_hand_bar.custom_minimum_size.y
	_expect(screen.overlay_dismiss_button.get_parent() == screen, "overlay mask is root-level", failures)
	_expect(screen.card_zone_drawer_panel.get_parent() == screen, "card drawer remains root-level", failures)
	_expect(screen.log_panel.get_parent() == screen, "log drawer remains root-level", failures)
	screen._toggle_card_zone()
	screen._toggle_battle_log()
	await process_frame
	_expect(duel_area.custom_minimum_size.y == duel_min_height, "opening drawers does not change duel area minimum height", failures)
	_expect(bottom_hand_bar.custom_minimum_size.y == bottom_min_height, "opening drawers does not change bottom hand bar minimum height", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
