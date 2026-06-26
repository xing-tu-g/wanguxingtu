extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	await _check_duel_layout_structure(failures)
	await _check_master_panels_and_board_priority(failures)
	await _check_bottom_hand_bar_and_drawers(failures)
	await process_frame

	if failures.is_empty():
		print("M38 duel battle layout checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_duel_layout_structure(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.has_node("Background"), "battle screen has star-map background placeholder", failures)
	_expect(screen.has_node("Margin/Layout/TopStatusBar"), "top status bar exists", failures)
	_expect(screen.has_node("Margin/Layout/DuelArea"), "duel area exists", failures)
	_expect(screen.has_node("Margin/Layout/BottomHandBar"), "bottom hand bar exists", failures)
	_expect(screen.has_node("Margin/Layout/DuelArea/PlayerMasterPanel"), "left master panel exists", failures)
	_expect(screen.has_node("Margin/Layout/DuelArea/EnemyMasterPanel"), "right master panel exists", failures)
	_expect(screen.has_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea/BoardPanel"), "center board panel exists", failures)
	screen.queue_free()


func _check_master_panels_and_board_priority(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var duel_area: HBoxContainer = screen.get_node("Margin/Layout/DuelArea")
	var player_master_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel")
	var enemy_master_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel")
	var board_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea/BoardPanel")
	var player_portrait: Label = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerMasterPortrait")
	var enemy_portrait: Label = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyMasterPortrait")
	_expect(duel_area.size_flags_vertical == Control.SIZE_EXPAND_FILL, "duel area gets the primary vertical space", failures)
	_expect(player_master_panel.custom_minimum_size.x >= 220.0, "player master panel keeps compact visible width", failures)
	_expect(enemy_master_panel.custom_minimum_size.x >= 220.0, "enemy master panel keeps compact visible width", failures)
	_expect(board_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "board expands between masters", failures)
	_expect(player_portrait.text.find("⇢") >= 0, "player master faces the board", failures)
	_expect(enemy_portrait.text.find("⇠") >= 0, "enemy master faces the board", failures)
	screen.queue_free()


func _check_bottom_hand_bar_and_drawers(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var bottom_hand_bar: HBoxContainer = screen.get_node("Margin/Layout/BottomHandBar")
	var card_zone_panel: PanelContainer = screen.get_node("Margin/Layout/BottomHandBar/CardZonePanel")
	var hero_scroll: ScrollContainer = screen.get_node("Margin/Layout/BottomHandBar/Controls/HeroScroll")
	_expect(bottom_hand_bar.custom_minimum_size.y >= 150.0, "bottom hand bar reserves touch card height", failures)
	_expect(card_zone_panel.get_parent() == bottom_hand_bar, "compact card summary lives in bottom hand bar", failures)
	_expect(hero_scroll.custom_minimum_size.y >= 90.0, "hand card scroll is taller than old debug row", failures)
	_expect(screen.card_zone_drawer_panel.get_parent() == screen, "card zone drawer remains root overlay", failures)
	_expect(screen.log_panel.get_parent() == screen, "battle log is a root drawer instead of side panel", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
