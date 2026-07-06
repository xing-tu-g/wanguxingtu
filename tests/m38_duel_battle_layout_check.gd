extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_duel_layout_structure(screen, failures)
	_check_master_panels_and_board_priority(screen, failures)
	_check_bottom_hand_bar_and_drawers(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M38 duel battle layout checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_duel_layout_structure(screen: Control, failures: Array[String]) -> void:
	_expect(screen.has_node("Background"), "battle screen has star-map background", failures)
	_expect(screen.has_node("TopBar"), "top status bar exists", failures)
	_expect(screen.has_node("DuelArea"), "duel area exists", failures)
	_expect(screen.has_node("BottomHand"), "bottom hand bar exists", failures)
	_expect(screen.has_node("DuelArea/PlayerMasterPanel"), "left master panel exists", failures)
	_expect(screen.has_node("DuelArea/EnemyMasterPanel"), "right master panel exists", failures)
	_expect(screen.has_node("DuelArea/CenterBoardStack/BattleArea/BoardPanel"), "center board panel exists", failures)


func _check_master_panels_and_board_priority(screen: Control, failures: Array[String]) -> void:
	var duel_area: HBoxContainer = screen.get_node("DuelArea")
	var player_master_panel: PanelContainer = screen.get_node("DuelArea/PlayerMasterPanel")
	var enemy_master_panel: PanelContainer = screen.get_node("DuelArea/EnemyMasterPanel")
	var board_panel: PanelContainer = screen.get_node("DuelArea/CenterBoardStack/BattleArea/BoardPanel")
	var player_portrait: TextureRect = screen.get_node("DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerPortrait")
	var enemy_portrait: TextureRect = screen.get_node("DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyPortrait")
	_expect(duel_area.size.y > screen.get_node("BottomHand").size.y * 3.0, "duel area gets the primary vertical space", failures)
	_expect(player_master_panel.custom_minimum_size.x >= 200.0, "player master panel keeps compact visible width", failures)
	_expect(enemy_master_panel.custom_minimum_size.x >= 200.0, "enemy master panel keeps compact visible width", failures)
	_expect(board_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "board expands between masters", failures)
	_expect(player_portrait.texture != null, "player master uses portrait texture", failures)
	_expect(enemy_portrait.texture != null, "enemy master uses portrait texture", failures)


func _check_bottom_hand_bar_and_drawers(screen: Control, failures: Array[String]) -> void:
	var bottom_hand_bar: HBoxContainer = screen.get_node("BottomHand")
	var card_zone_panel: PanelContainer = screen.get_node("BottomHand/CardZonePanel")
	var hero_scroll: ScrollContainer = screen.get_node("BottomHand/Controls/HeroScroll")
	_expect(bottom_hand_bar.size.y >= 180.0, "bottom hand bar reserves card HUD height", failures)
	_expect(card_zone_panel.get_parent() == bottom_hand_bar, "compact card summary lives in bottom hand bar", failures)
	_expect(hero_scroll.custom_minimum_size.y >= 170.0, "hand card scroll is taller than old debug row", failures)
	_expect(screen.card_zone_drawer_panel.get_parent() == screen, "card zone drawer remains root overlay", failures)
	_expect(screen.log_panel.get_parent() == screen, "battle log is a root drawer instead of side panel", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
