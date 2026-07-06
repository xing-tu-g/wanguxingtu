extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_selected_hand_card_visual_hierarchy(screen, failures)
	await _check_selection_switch_updates_visuals(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M42 hand bar hierarchy checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_selected_hand_card_visual_hierarchy(screen: Control, failures: Array[String]) -> void:
	var selected_button: Button = screen.hero_buttons[screen.selected_hero_id]
	var selected_cost_label: Label = selected_button.get_node("HandCardContainer/TopRow/CostLabel")
	var selected_state_label: Label = selected_button.get_node("HandCardContainer/StateLabel")
	_expect(selected_button.visible, "selected hand card is visible", failures)
	_expect(selected_state_label.text == "已选择", "selected hand card has selected state", failures)
	_expect(selected_cost_label.text.is_valid_int(), "selected hand card shows icon-ready numeric fee", failures)
	_expect(not selected_cost_label.text.contains("*") and not selected_cost_label.text.contains("★"), "selected hand card hides star rarity", failures)


func _check_selection_switch_updates_visuals(screen: Control, failures: Array[String]) -> void:
	var next_hero := ""
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if hero_id != screen.selected_hero_id and screen.battle_state.can_afford("left", hero_id):
			next_hero = hero_id
			break
	_expect(next_hero != "", "test can find another affordable hand card", failures)
	if next_hero == "":
		return
	screen._select_hero(next_hero)
	await process_frame
	var new_button: Button = screen.hero_buttons[next_hero]
	var state_label: Label = new_button.get_node("HandCardContainer/StateLabel")
	_expect(screen.selected_hero_id == next_hero, "selection switches to clicked hand card", failures)
	_expect(state_label.text == "已选择", "new selected card updates selected label", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
