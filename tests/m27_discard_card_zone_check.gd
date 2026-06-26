extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_initial_card_zone_summary(failures)
	await _check_player_deploy_moves_card_to_discard(failures)
	await _check_enemy_auto_deploy_moves_card_to_discard(failures)
	await _check_draw_log_and_empty_deck_summary(failures)
	await _check_reset_clears_discards(failures)
	await process_frame

	if failures.is_empty():
		print("M27 discard card zone checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_card_zone_summary(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.card_zone_label.text.find("我方 牌库：3  手牌：关羽(5)、周瑜(5)、张角(5)") >= 0, "initial player hand names are shown", failures)
	_expect(screen.card_zone_label.text.find("我方 牌库：3  手牌：关羽(5)、周瑜(5)、张角(5)  弃牌：无") >= 0, "initial player discard is empty", failures)
	_expect(screen.card_zone_label.text.find("敌方 牌库：3  手牌：周瑜(5)、关羽(5)、赵云(4)  弃牌：无") >= 0, "initial enemy hand and discard are shown", failures)
	screen.queue_free()


func _check_player_deploy_moves_card_to_discard(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.player_hand.has("guanyu"), "deployed player card leaves hand", failures)
	_expect(screen.player_discard == ["guanyu"], "deployed player card enters discard", failures)
	_expect(screen.card_zone_label.text.find("我方 牌库：3  手牌：周瑜(5)、张角(5)") >= 0, "player card zone removes deployed card from hand", failures)
	_expect(screen.card_zone_label.text.find("弃牌：关羽(5)") >= 0, "player card zone shows deployed card in discard", failures)
	screen.queue_free()


func _check_enemy_auto_deploy_moves_card_to_discard(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var result: Dictionary = screen._auto_deploy_enemy()
	screen._update_status("敌方自动部署测试。")
	await process_frame
	_expect(bool(result.get("ok", false)), "enemy auto deploy succeeds", failures)
	_expect(not screen.enemy_hand.has("zhouyu"), "deployed enemy card leaves hand", failures)
	_expect(screen.enemy_discard == ["zhouyu"], "deployed enemy card enters discard", failures)
	_expect(screen.card_zone_label.text.find("敌方 牌库：3  手牌：关羽(5)、赵云(4)") >= 0, "enemy card zone removes deployed card from hand", failures)
	_expect(screen.card_zone_label.text.find("敌方 牌库：3  手牌：关羽(5)、赵云(4)  弃牌：周瑜(5)") >= 0, "enemy card zone shows discard", failures)
	screen.queue_free()


func _check_draw_log_and_empty_deck_summary(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._advance_turn()
	await process_frame
	_expect(screen.card_zone_label.text.find("我方 牌库：2  手牌：关羽(5)、周瑜(5)、张角(5)、赵云(4)") >= 0, "drawn card appears in player hand summary", failures)
	_expect(_log_contains(screen, "我方 - 抽牌 - 抽到 赵云"), "battle log records drawn card name", failures)
	screen.player_deck.clear()
	screen._log_drawn_cards(BoardModelScript.SIDE_LEFT, screen._draw_cards(BoardModelScript.SIDE_LEFT, 1))
	screen._update_status("空牌库测试。")
	await process_frame
	_expect(_log_contains(screen, "我方 - 抽牌 - 牌库与弃牌均为空"), "battle log records empty deck draw", failures)
	_expect(screen.card_zone_label.text.find("我方 牌库：0（无可回收）  手牌：关羽(5)、周瑜(5)、张角(5)、赵云(4)  弃牌：无") >= 0, "empty deck keeps hand summary stable", failures)
	screen.queue_free()


func _check_reset_clears_discards(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	screen._reset_debug_battle()
	await process_frame
	_expect(screen.player_discard.is_empty(), "reset clears player discard", failures)
	_expect(screen.enemy_discard.is_empty(), "reset clears enemy discard", failures)
	_expect(screen.card_zone_label.text.find("我方 牌库：3  手牌：关羽(5)、周瑜(5)、张角(5)  弃牌：无") >= 0, "reset restores player card zone", failures)
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
