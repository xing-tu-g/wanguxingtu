extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_initial_deck_counts_visible(failures)
	await _check_empty_deck_hint_after_exhaustion(failures)
	await _check_expanded_rule_explains_no_recycle_and_three_empty_defeat(failures)
	await _check_reset_clears_empty_deck_hint(failures)
	await process_frame

	if failures.is_empty():
		print("M32 empty deck UI hint checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_deck_counts_visible(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.player_hud_label.text.find("牌库 3") >= 0, "player HUD shows initial deck count", failures)
	_expect(screen.enemy_hud_label.text.find("牌库 3") >= 0, "enemy HUD shows initial deck count", failures)
	_expect(screen.card_zone_summary_label.text.find("我方 牌库：3") >= 0, "card zone summary shows player deck count", failures)
	_expect(screen.card_zone_summary_label.text.find("敌方 牌库：3") >= 0, "card zone summary shows enemy deck count", failures)
	screen.queue_free()


func _check_empty_deck_hint_after_exhaustion(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen._log_drawn_cards(BoardModelScript.SIDE_LEFT, screen._draw_cards(BoardModelScript.SIDE_LEFT, 1))
	screen._update_status("抽空提示测试。")
	await process_frame
	_expect(screen.player_hud_label.text.find("牌库 0（抽空）") >= 0, "player HUD marks empty deck", failures)
	_expect(screen.card_zone_summary_label.text.find("我方 牌库：0（无可回收）") >= 0, "summary marks empty deck without recycle source", failures)
	_expect(_log_contains(screen, "我方 - 抽牌 - 牌库与弃牌均为空"), "battle log records empty deck draw", failures)
	screen.queue_free()


func _check_expanded_rule_explains_no_recycle_and_three_empty_defeat(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen._update_status("展开规则提示测试。")
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_detail_label.visible, "expanded card zone detail is visible", failures)
	_expect(screen.card_zone_detail_label.text.find("[b]我方[/b]：牌库 0（无可回收）｜手牌 3｜弃牌 0") >= 0, "expanded detail shows empty player deck count", failures)
	_expect(screen.card_zone_detail_label.text.find("[b]敌方[/b]：牌库 3｜手牌 3｜弃牌 0") >= 0, "expanded detail keeps enemy counts", failures)
	_expect(screen.card_zone_detail_label.text.find("详细牌序属于后台数据") >= 0, "expanded detail explains hidden backend data", failures)
	screen.queue_free()


func _check_reset_clears_empty_deck_hint(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen._update_status("重置前抽空。")
	screen._reset_debug_battle()
	await process_frame
	_expect(screen.player_hud_label.text.find("牌库 3") >= 0, "reset restores player deck count", failures)
	_expect(screen.card_zone_summary_label.text.find("我方 牌库：3") >= 0, "reset restores card zone deck count", failures)
	_expect(screen.card_zone_summary_label.text.find("抽空") < 0, "reset removes empty deck hint", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _log_contains(screen, text: String) -> bool:
	for entry in screen.battle_log_entries:
		if str(entry).find(text) >= 0:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
