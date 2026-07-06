extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	await _check_card_zone_close_button(screen, failures)
	await _check_log_drawer_disabled_in_battle(screen, failures)
	await _check_shared_overlay_dismisses_drawers(screen, failures)
	await _check_drawers_do_not_reflow_battle_layout(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M40 drawer dismiss controls checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_card_zone_close_button(screen: Control, failures: Array[String]) -> void:
	_expect(screen.has_node("CardZoneDrawerPanel/DrawerMargin/DrawerLayout/DrawerHeader/CardZoneCloseButton"), "card drawer has a close button", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "card drawer opens before close-button check", failures)
	_expect(screen.overlay_dismiss_button.visible, "overlay mask appears with card drawer", failures)
	screen.card_zone_close_button.pressed.emit()
	await _wait_for_overlay_close(screen)
	_expect(not screen.card_zone_drawer_panel.visible, "card drawer close button hides drawer", failures)
	_expect(not screen.overlay_dismiss_button.visible, "overlay mask hides after card drawer closes", failures)
	_expect(screen.card_zone_view.collapsed, "card zone view resets after close button", failures)


func _check_log_drawer_disabled_in_battle(screen: Control, failures: Array[String]) -> void:
	_expect(screen.has_node("LogPanel/LogMargin/LogLayout/LogHeader/LogCloseButton"), "internal log drawer node still exists for log buffering", failures)
	_expect(not screen.toggle_log_button.visible, "battle report button is hidden during battle", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(not screen.log_panel.visible, "battle log drawer cannot open during battle", failures)
	_expect(not screen.overlay_dismiss_button.visible, "hidden battle log does not summon overlay mask", failures)


func _check_shared_overlay_dismisses_drawers(screen: Control, failures: Array[String]) -> void:
	screen._toggle_card_zone()
	screen._toggle_battle_log()
	await process_frame
	_expect(screen.card_zone_drawer_panel.visible, "card drawer opens before mask dismissal", failures)
	_expect(not screen.log_panel.visible, "log drawer remains hidden before mask dismissal", failures)
	_expect(screen.overlay_dismiss_button.visible, "overlay mask appears when any drawer opens", failures)
	screen.overlay_dismiss_button.pressed.emit()
	await _wait_for_overlay_close(screen)
	_expect(not screen.card_zone_drawer_panel.visible, "overlay mask closes card drawer", failures)
	_expect(not screen.log_panel.visible, "overlay mask closes log drawer", failures)
	_expect(not screen.overlay_dismiss_button.visible, "overlay mask hides after closing all drawers", failures)


func _check_drawers_do_not_reflow_battle_layout(screen: Control, failures: Array[String]) -> void:
	var duel_area: HBoxContainer = screen.get_node("DuelArea")
	var bottom_hand_bar: HBoxContainer = screen.get_node("BottomHand")
	var duel_size := duel_area.size
	var bottom_size := bottom_hand_bar.size
	_expect(screen.overlay_dismiss_button.get_parent() == screen, "overlay mask is root-level", failures)
	_expect(screen.card_zone_drawer_panel.get_parent() == screen, "card drawer remains root-level", failures)
	_expect(screen.log_panel.get_parent() == screen, "log drawer remains root-level", failures)
	screen._toggle_card_zone()
	screen._toggle_battle_log()
	await process_frame
	_expect(duel_area.size == duel_size, "opening drawers does not change duel area size", failures)
	_expect(bottom_hand_bar.size == bottom_size, "opening drawers does not change bottom hand bar size", failures)
	_expect(not screen.log_panel.visible, "battle log remains hidden during layout check", failures)
	screen.overlay_dismiss_button.pressed.emit()
	await _wait_for_overlay_close(screen)


func _wait_for_overlay_close(screen: Control) -> void:
	for _index in range(16):
		await process_frame
		if not screen.overlay_dismiss_button.visible and not screen.card_zone_drawer_panel.visible and not screen.log_panel.visible:
			return


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
