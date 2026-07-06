extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_initial_randomized_five_card_hand(screen, failures)
	await _check_deploy_refills_hand_slot(screen, failures)
	_check_full_hand_turn_does_not_overdraw(screen, failures)
	_check_empty_deck_slot_hint(screen, failures)
	_check_empty_deck_draw_is_safe(screen, failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M25 draw deck prototype checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_randomized_five_card_hand(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	var expected_reserve: int = screen._player_battle_hero_ids().size() - 5
	_expect(screen.player_hand.size() == 5, "player starts with five hand cards", failures)
	_expect(screen.player_deck.size() == expected_reserve, "player deck keeps configured reserve cards", failures)
	_expect(screen.enemy_hand.size() == 5, "enemy starts with five hand cards", failures)
	_expect(screen.enemy_deck.size() == expected_reserve, "enemy deck keeps configured reserve cards", failures)
	_expect(_has_same_members(screen.player_hand + screen.player_deck, screen._player_battle_hero_ids()), "player hand and deck preserve configured cards", failures)


func _check_deploy_refills_hand_slot(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var reserve_before: Array = screen.player_deck.duplicate()
	var deployed_hero := str(screen.player_hand[0])
	screen._select_hero(deployed_hero)
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(not screen.player_hand.has(deployed_hero), "deployed hero leaves hand", failures)
	_expect(screen.player_hand.size() == 5, "deploy immediately refills hand to five while deck has cards", failures)
	_expect(screen.player_deck.size() == reserve_before.size() - 1, "deploy refill consumes one reserve card", failures)
	if not reserve_before.is_empty():
		_expect(screen.player_hand.has(str(reserve_before[0])), "next draw_queue card enters hand after deploy", failures)


func _check_full_hand_turn_does_not_overdraw(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	var deck_before: int = screen.player_deck.size()
	var result: Dictionary = screen._advance_turn()
	_expect(screen.player_hand.size() == 5, "full hand remains capped at five after turn advance", failures)
	_expect(screen.player_deck.size() == deck_before, "full hand turn does not draw from deck", failures)
	_expect(result.get("drawn_cards", []).is_empty(), "full hand turn reports no drawn cards", failures)


func _check_empty_deck_slot_hint(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	screen.player_deck.clear()
	var removed_id := str(screen.player_hand[0])
	screen.player_hand.erase(removed_id)
	screen._update_hero_buttons()
	var next_slot: PanelContainer = screen.get_node("BottomHand/Controls/HeroScroll/HeroButtons/NextDrawSlot")
	var next_label: Label = next_slot.get_node("NextDrawLabel")
	_expect(next_slot.visible, "empty hand slot is visible when hand has fewer than five cards", failures)
	_expect(next_label.text.contains("牌库已空"), "empty slot explains deck is empty", failures)


func _check_empty_deck_draw_is_safe(screen: Control, failures: Array[String]) -> void:
	screen._reset_debug_battle()
	screen.player_deck.clear()
	var before_hand_size: int = screen.player_hand.size()
	var drawn_cards: Array = screen._draw_cards(BoardModelScript.SIDE_LEFT, 2)
	_expect(drawn_cards.is_empty(), "drawing from empty deck returns no cards", failures)
	_expect(screen.player_hand.size() == before_hand_size, "drawing from empty deck keeps hand unchanged", failures)


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _has_same_members(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	var remaining: Array = expected.duplicate()
	for value in actual:
		var index: int = remaining.find(value)
		if index < 0:
			return false
		remaining.remove_at(index)
	return remaining.is_empty()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
