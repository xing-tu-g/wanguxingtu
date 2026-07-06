extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.player_deck.size() == screen._player_battle_hero_ids().size() - 5, "player starts with configured reserve deck after five-card hand", failures)
	screen.player_deck.clear()
	var removed_id := str(screen.player_hand[0])
	screen.player_hand.erase(removed_id)
	screen._update_hero_buttons()
	await process_frame
	var next_slot: PanelContainer = screen.get_node("BottomHand/Controls/HeroScroll/HeroButtons/NextDrawSlot")
	var next_label: Label = next_slot.get_node("NextDrawLabel")
	_expect(next_slot.visible, "empty deck slot hint is visible when hand is not full", failures)
	_expect(next_label.text.contains("牌库已空"), "empty deck slot states deck is empty", failures)
	screen._reset_debug_battle()
	await process_frame
	_expect(screen.player_deck.size() == screen._player_battle_hero_ids().size() - 5 and screen.player_hand.size() == 5, "reset restores deck and hand count", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M32 empty deck UI hint checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
