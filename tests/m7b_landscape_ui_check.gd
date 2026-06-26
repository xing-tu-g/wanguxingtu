extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var margin: MarginContainer = screen.get_node("Margin")
	_expect(margin.offset_left >= 16.0, "left safe margin is at least 16 px", failures)
	_expect(margin.offset_top >= 12.0, "top safe margin is at least 12 px", failures)
	_expect(margin.offset_right <= -16.0, "right safe margin is at least 16 px", failures)
	_expect(margin.offset_bottom <= -16.0, "bottom safe margin is at least 16 px", failures)

	var top_status_bar: VBoxContainer = screen.get_node("Margin/Layout/TopStatusBar")
	var duel_area: HBoxContainer = screen.get_node("Margin/Layout/DuelArea")
	var bottom_hand_bar: HBoxContainer = screen.get_node("Margin/Layout/BottomHandBar")
	var player_master_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel")
	var enemy_master_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel")
	var board_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea/BoardPanel")
	_expect(top_status_bar != null, "battle screen has top status bar", failures)
	_expect(duel_area != null, "battle content uses a duel landscape area", failures)
	_expect(bottom_hand_bar != null, "battle screen has bottom hand bar", failures)
	_expect(player_master_panel.custom_minimum_size.x >= 220.0, "player master panel reserves left duel space", failures)
	_expect(enemy_master_panel.custom_minimum_size.x >= 220.0, "enemy master panel reserves right duel space", failures)
	_expect(board_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "board panel expands between masters", failures)

	var hero_scroll: ScrollContainer = screen.get_node("Margin/Layout/BottomHandBar/Controls/HeroScroll")
	_expect(hero_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "hero buttons can scroll horizontally", failures)
	_expect(hero_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "hero buttons avoid vertical scrolling", failures)

	for button_path in [
		"Margin/Layout/TopStatusBar/HeaderRow/HomeButton",
		"Margin/Layout/TopStatusBar/HeaderRow/ToggleLogButton",
		"Margin/Layout/BottomHandBar/Controls/AdvanceTurnButton",
		"Margin/Layout/BottomHandBar/Controls/ResetButton",
	]:
		var button: Button = screen.get_node(button_path)
		_expect(button.custom_minimum_size.y >= 52.0, "%s keeps touch-friendly height" % button_path, failures)
	_expect(screen.hero_buttons.size() >= 3, "battle screen builds selectable hero buttons", failures)
	for hero_id in screen.hero_buttons.keys():
		var hero_button: Button = screen.hero_buttons[hero_id]
		_expect(hero_button.custom_minimum_size.y >= 52.0, "%s hero button keeps touch-friendly height" % hero_id, failures)

	_expect(not screen.log_panel.visible, "battle log drawer starts hidden", failures)
	_expect(screen.toggle_log_button.text == "战报", "log button starts as battle report entry", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(screen.log_panel.visible, "toggle shows battle log drawer", failures)
	_expect(screen.toggle_log_button.text == "收起战报", "toggle label marks open battle report", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(not screen.log_panel.visible, "toggle hides battle log drawer again", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M7b landscape UI checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
