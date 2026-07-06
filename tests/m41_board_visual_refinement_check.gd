extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_board_cells_exist(screen, failures)
	_check_hand_card_structure(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M41 board visual refinement checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_board_cells_exist(screen: Control, failures: Array[String]) -> void:
	_expect(screen.cell_buttons.size() > 0, "battle board builds cell buttons", failures)
	_expect(screen.cell_buttons.has("1,1"), "battle board exposes left-side cell", failures)
	_expect(screen.cell_buttons.has("9,5"), "battle board exposes right-side cell", failures)


func _check_hand_card_structure(screen: Control, failures: Array[String]) -> void:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		var button: Button = screen.hero_buttons[hero_id]
		var name_label: Label = button.get_node("HandCardContainer/TopRow/NameLabel")
		var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
		var meta_label: Label = button.get_node("HandCardContainer/MetaLabel")
		_expect(button.visible, "%s current hand card is visible" % hero_id, failures)
		_expect(name_label.text.length() > 0, "%s hand card shows name" % hero_id, failures)
		_expect(cost_label.text.is_valid_int(), "%s hand card shows numeric fee" % hero_id, failures)
		_expect(not cost_label.text.contains("*") and not cost_label.text.contains("★"), "%s hand card hides star rarity" % hero_id, failures)
		_expect(meta_label.text.length() > 0, "%s hand card shows meta" % hero_id, failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
