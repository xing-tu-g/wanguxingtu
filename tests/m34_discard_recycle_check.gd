extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_runtime_deck_recycles_discard_on_draw(failures)
	await _check_card_zone_shows_pending_recycle(failures)
	await _check_discard_prevents_three_empty_defeat(failures)
	await process_frame

	if failures.is_empty():
		print("M34 discard recycle checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_runtime_deck_recycles_discard_on_draw(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen.player_hand.clear()
	screen.player_discard.clear()
	screen.player_discard.append("guanyu")
	var drawn_cards: Array = screen._draw_cards(BoardModelScript.SIDE_LEFT, 1)
	screen._log_drawn_cards(BoardModelScript.SIDE_LEFT, drawn_cards)
	screen._update_status("回收测试。")
	await process_frame
	_expect(drawn_cards == ["guanyu"], "runtime draw recycles player discard", failures)
	_expect(screen.player_discard.is_empty(), "runtime recycle clears player discard", failures)
	_expect(screen.player_hand == ["guanyu"], "runtime recycle puts card into player hand", failures)
	_expect(_log_contains(screen, "我方 - 洗牌 - 弃牌回收到牌库后抽牌"), "runtime logs discard recycle", failures)
	_expect(_log_contains(screen, "我方 - 抽牌 - 抽到 关羽"), "runtime logs recycled draw", failures)
	screen.queue_free()


func _check_card_zone_shows_pending_recycle(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen.player_discard.append("zhouyu")
	screen._update_status("待洗回提示测试。")
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_summary_label.text.find("我方 牌库：0（待洗回 1）") >= 0, "summary shows pending recycle count", failures)
	_expect(screen.card_zone_detail_label.text.find("[b]我方[/b]：牌库 0（待洗回 1）｜手牌 3｜弃牌 1") >= 0, "detail shows pending recycle count", failures)
	_expect(screen.card_zone_detail_label.text.find("详细牌序属于后台数据") >= 0, "detail keeps backend data explanation", failures)
	screen.queue_free()


func _check_discard_prevents_three_empty_defeat(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen.player_hand.clear()
	screen.player_discard.clear()
	screen.player_discard.append("zhangjiao")
	for unit_data: Dictionary in screen.battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT):
		screen.battle_state.board.remove_unit(str(unit_data.get("instance_id", "")))
	var result: Dictionary = screen._check_battle_end()
	_expect(result.is_empty(), "discard pile prevents all-empty defeat", failures)
	screen.player_discard.clear()
	result = screen._check_battle_end()
	_expect(not result.is_empty(), "all-empty still triggers defeat after discard clears", failures)
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
