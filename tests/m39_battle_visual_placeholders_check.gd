extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_battle_assets_present(screen, failures)
	_check_hand_cards_are_structured_controls(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M39 battle visual placeholder checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_battle_assets_present(screen: Control, failures: Array[String]) -> void:
	_expect(screen.battle_background_image.texture != null, "battle background texture is assigned", failures)
	_expect(screen.cell_buttons.size() > 0, "board cells are built", failures)
	_expect(screen.board_overlay_preview.texture != null, "board overlay texture is assigned", failures)


func _check_hand_cards_are_structured_controls(screen: Control, failures: Array[String]) -> void:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		var button: Button = screen.hero_buttons[hero_id]
		_expect(button.has_node("HandCardContainer/TopRow/NameLabel"), "%s hand card has name label" % hero_id, failures)
		_expect(button.has_node("HandCardContainer/TopRow/CostLabel"), "%s hand card has cost label" % hero_id, failures)
		var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
		_expect(cost_label.text.is_valid_int() and not cost_label.text.contains("*") and not cost_label.text.contains("★"), "%s hand card uses numeric fee without star rarity" % hero_id, failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
