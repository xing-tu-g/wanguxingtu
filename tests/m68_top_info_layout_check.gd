extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_top_bar_current_structure(screen, failures)
	await _check_turn_info_sync(screen, failures)
	_check_hand_status_labels(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M68 top info layout checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_top_bar_current_structure(screen: Control, failures: Array[String]) -> void:
	_expect(screen.has_node("TopBar/BackButton"), "top bar has back button", failures)
	_expect(screen.has_node("TopBar/StatusPanel"), "top bar has status panel", failures)
	_expect(screen.has_node("TopBar/LogButton"), "top bar keeps internal battle report node", failures)
	_expect(not screen.toggle_log_button.visible, "battle report button is hidden during battle", failures)
	_expect(screen.status_label.text.length() > 0, "status label carries current instruction", failures)
	_expect(screen.star_label.text.length() > 0, "turn label carries side and turn state", failures)


func _check_turn_info_sync(screen: Control, failures: Array[String]) -> void:
	var before_text: String = screen.star_label.text
	screen._advance_turn()
	await process_frame
	_expect(screen.star_label.text != before_text, "turn info changes after advancing turn", failures)


func _check_hand_status_labels(screen: Control, failures: Array[String]) -> void:
	screen._update_hero_buttons()
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		var button: Button = screen.hero_buttons[hero_id]
		var name_label: Label = button.get_node("HandCardContainer/TopRow/NameLabel")
		var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
		var meta_label: Label = button.get_node("HandCardContainer/MetaLabel")
		var state_label: Label = button.get_node("HandCardContainer/StateLabel")
		_expect(name_label.text.length() > 0, "%s hand card keeps hero name" % hero_id, failures)
		_expect(cost_label.text.is_valid_int() and not cost_label.text.contains("*") and not cost_label.text.contains("★"), "%s hand card keeps numeric fee without star rarity" % hero_id, failures)
		_expect(meta_label.text.length() > 0, "%s hand card keeps meta" % hero_id, failures)
		_expect(state_label.text.length() > 0, "%s hand card keeps state tag" % hero_id, failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
