extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_empty_deck_does_not_recycle_discard(screen, failures)
	_check_card_zone_keeps_discard_as_used_record(screen, failures)
	_check_empty_slot_hint_after_deploying_last_reserve(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M34 discard no-recycle checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_empty_deck_does_not_recycle_discard(screen: Control, failures: Array[String]) -> void:
	screen.player_deck.clear()
	screen.player_hand.clear()
	screen.player_discard.clear()
	screen.player_discard.append("guanyu")
	var drawn_cards: Array = screen._draw_cards(BoardModelScript.SIDE_LEFT, 1)
	_expect(drawn_cards.is_empty(), "empty deck does not recycle discard into draw", failures)
	_expect(screen.player_discard == ["guanyu"], "discard stays as used-card record", failures)
	_expect(screen.player_hand.is_empty(), "empty deck leaves hand slot empty", failures)


func _check_card_zone_keeps_discard_as_used_record(screen: Control, failures: Array[String]) -> void:
	screen.card_zone_view.refresh()
	screen._update_card_zone_summary()
	_expect(screen.card_zone_summary_label.text.contains("牌库剩余 0"), "summary shows empty reserve deck", failures)
	_expect(screen.card_zone_detail_label.text.contains("弃牌 1"), "detail shows discard count", failures)
	_expect(not screen.card_zone_detail_label.text.contains("待洗回"), "detail does not promise discard recycle", failures)


func _check_empty_slot_hint_after_deploying_last_reserve(screen: Control, failures: Array[String]) -> void:
	screen.player_hand.clear()
	screen.player_deck.clear()
	screen.player_discard.clear()
	screen.player_hand.append("guanyu")
	screen._sync_card_pile_references()
	screen._consume_hero_from_hand(BoardModelScript.SIDE_LEFT, "guanyu")
	screen._update_hero_buttons()
	await screen.get_tree().process_frame
	var next_slot: PanelContainer = screen.get_node("BottomHand/Controls/HeroScroll/HeroButtons/NextDrawSlot")
	var next_label: Label = next_slot.get_node("NextDrawLabel")
	_expect(screen.player_hand.is_empty(), "used final hand card is not replaced when deck is empty", failures)
	_expect(next_slot.visible, "empty hand slot is visible when deck is empty", failures)
	_expect(next_label.text.contains("牌库已空"), "empty hand slot states deck is empty", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
