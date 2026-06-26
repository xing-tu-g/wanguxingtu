extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_initial_draw_from_deck(failures)
	await _check_player_turn_draws_one_card(failures)
	await _check_enemy_turn_draws_before_auto_deploy(failures)
	await _check_empty_deck_draw_is_safe(failures)
	await _check_three_empty_defeat_still_waits_for_board_clear(failures)
	await process_frame

	if failures.is_empty():
		print("M25 draw deck prototype checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_draw_from_deck(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.player_hand == ["guanyu", "zhouyu", "zhangjiao"], "player starts with first three cards in hand", failures)
	_expect(screen.player_deck == ["zhaoyun", "zhangfei", "sunshangxiang"], "player deck keeps remaining three cards", failures)
	_expect(screen.player_discard.is_empty(), "player starts with empty discard pile", failures)
	_expect(screen.enemy_hand == ["zhouyu", "guanyu", "zhaoyun"], "enemy starts with first three cards in hand", failures)
	_expect(screen.enemy_deck == ["zhangfei", "sunshangxiang", "zhangjiao"], "enemy deck keeps remaining three cards", failures)
	_expect(screen.enemy_discard.is_empty(), "enemy starts with empty discard pile", failures)
	_expect(screen.selected_hero_id == "guanyu", "first player hand card is selected", failures)
	_expect(screen.hero_buttons["zhaoyun"].disabled, "undrawn player card is not selectable", failures)
	_expect(str(screen.hero_buttons["zhaoyun"].text).find("牌库") >= 0, "undrawn player card is labeled as deck card", failures)
	screen.queue_free()


func _check_player_turn_draws_one_card(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var result: Dictionary = screen._advance_turn()
	await process_frame
	_expect(result.get("drawn_cards", []) == ["zhaoyun"], "left turn draws exactly one player card", failures)
	_expect(screen.player_hand.has("zhaoyun"), "drawn player card enters hand", failures)
	_expect(screen.player_deck == ["zhangfei", "sunshangxiang"], "player deck loses drawn card", failures)
	_expect(not screen.hero_buttons["zhaoyun"].disabled, "drawn player card button becomes enabled", failures)
	screen.queue_free()


func _check_enemy_turn_draws_before_auto_deploy(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._advance_turn()
	var right_result: Dictionary = screen._advance_turn()
	await process_frame
	_expect(right_result.get("drawn_cards", []) == ["zhangfei"], "right turn draws exactly one enemy card", failures)
	_expect(not screen.enemy_hand.has("zhouyu"), "enemy auto deploy consumes an affordable hand card", failures)
	_expect(screen.enemy_hand.has("zhangfei"), "enemy drawn card remains in hand if not deployed", failures)
	_expect(screen.enemy_deck == ["sunshangxiang", "zhangjiao"], "enemy deck loses drawn card", failures)
	screen.queue_free()


func _check_empty_deck_draw_is_safe(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	var before_hand_size: int = screen.player_hand.size()
	var drawn_cards: Array = screen._draw_cards(BoardModelScript.SIDE_LEFT, 2)
	_expect(drawn_cards.is_empty(), "drawing from empty deck returns no cards", failures)
	_expect(screen.player_hand.size() == before_hand_size, "drawing from empty deck keeps hand unchanged", failures)
	screen.queue_free()


func _check_three_empty_defeat_still_waits_for_board_clear(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.player_deck.clear()
	screen.player_hand.clear()
	_add_unit(screen, "left_anchor", BoardModelScript.SIDE_LEFT, 2, 3)
	var result_with_unit: Dictionary = screen._check_battle_end()
	_expect(result_with_unit.is_empty(), "empty deck and hand do not lose while board has a unit", failures)
	screen.battle_state.remove_unit("left_anchor")
	var result_without_unit: Dictionary = screen._check_battle_end()
	_expect(str(result_without_unit.get("outcome", "")) == "right_wins", "empty deck hand and board still loses", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _add_unit(screen, unit_id: String, side: String, column: int, row: int) -> Dictionary:
	var unit_data := {
		"instance_id": unit_id,
		"entry_order": screen.battle_state.next_unit_sequence,
		"hero_id": unit_id,
		"name": unit_id,
		"max_hp": 10,
		"hp": 10,
		"attack": 2,
		"range": 1,
		"move": 1,
		"class": "warrior",
		"physical_block": 0,
		"magic_block": 0,
		"damage_type": "physical",
		"skill_ids": [],
		"statuses": {},
		"stats": {},
	}
	var result: Dictionary = screen.battle_state.create_unit_instance(unit_data, side, column, row)
	return result.get("unit", {})


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
