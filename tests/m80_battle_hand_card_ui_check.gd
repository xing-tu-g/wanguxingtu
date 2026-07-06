extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_no_star_rarity_text(screen, failures)
	_check_rarity_style_helpers(screen, failures)
	_check_reset_hidden(screen, failures)
	_check_visible_hand_cards_only(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M80 battle hand card UI checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_no_star_rarity_text(screen: Control, failures: Array[String]) -> void:
	for hand_index in range(screen.player_hand.size()):
		var button: Button = screen.hero_buttons[hand_index]
		var hero_id := str(screen.player_hand[hand_index])
		var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
		_expect(not cost_label.text.contains("★"), "%s cost label does not use star glyph" % hero_id, failures)
		_expect(cost_label.text.is_valid_int(), "%s cost label uses icon-ready numeric fee" % hero_id, failures)
		_expect(str(button.text).find("★") < 0, "%s button text does not expose star rarity" % hero_id, failures)


func _check_rarity_style_helpers(screen: Control, failures: Array[String]) -> void:
	var rare_def := {"rarity": "rare"}
	var epic_def := {"rarity": "epic"}
	var legend_def := {"rarity": "legendary"}
	_expect(screen._hand_card_rarity_id(rare_def) == "rare", "rare rarity maps to rare style", failures)
	_expect(screen._hand_card_rarity_id(epic_def) == "epic", "epic rarity maps to epic style", failures)
	_expect(screen._hand_card_rarity_id(legend_def) == "legend", "legendary rarity maps to legend style", failures)
	_expect(screen._hand_card_rarity_tint(rare_def) != screen._hand_card_rarity_tint(epic_def), "rare and epic use different card tint", failures)
	_expect(screen._hand_card_rarity_tint(epic_def) != screen._hand_card_rarity_tint(legend_def), "epic and legend use different card tint", failures)


func _check_reset_hidden(screen: Control, failures: Array[String]) -> void:
	var reset_button: Button = screen.get_node("BottomHand/Controls/ResetButton")
	_expect(not reset_button.visible, "reset button is hidden in normal UI", failures)


func _check_visible_hand_cards_only(screen: Control, failures: Array[String]) -> void:
	var visible_cards := 0
	for hand_index in range(5):
		var button: Button = screen.hero_buttons[hand_index]
		if button.visible:
			visible_cards += 1
			_expect(int(hand_index) < 5, "visible hand slot index is capped", failures)
	_expect(visible_cards == 5, "five hand slots are visible including empty slots", failures)
	_expect(visible_cards <= 5, "visible hand cards are capped at five", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
