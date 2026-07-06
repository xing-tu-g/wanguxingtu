extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_hand_card_visual_fields(screen, failures)
	_check_selected_card_has_stronger_visual_state(screen, failures)
	await _check_clicking_visual_card_keeps_select_behavior(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M33 card visual component checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hand_card_visual_fields(screen: Control, failures: Array[String]) -> void:
	_expect(screen.player_hand.size() == 5, "opening hand has five cards", failures)
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		var button: Button = screen.hero_buttons.get(hero_id)
		_expect(button != null, "%s visual hand button exists" % hero_id, failures)
		if button == null:
			continue
		_expect(button.visible, "%s hand button is visible" % hero_id, failures)
		_expect(button.custom_minimum_size.x >= 170.0, "%s hand card is wider than a text chip" % hero_id, failures)
		_expect(button.custom_minimum_size.y >= 148.0, "%s hand card remains a structured HUD card" % hero_id, failures)
		_expect(button.text.is_empty(), "%s hand card does not use raw button text" % hero_id, failures)

		var name_label: Label = button.get_node("HandCardContainer/TopRow/NameLabel")
		var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
		var meta_label: Label = button.get_node("HandCardContainer/MetaLabel")
		var state_label: Label = button.get_node("HandCardContainer/StateLabel")
		_expect(not name_label.text.is_empty(), "%s hand card shows hero name", failures)
		_expect(cost_label.text.is_valid_int(), "%s hand card shows icon-ready numeric fee" % hero_id, failures)
		_expect(not cost_label.text.contains("*") and not cost_label.text.contains("★"), "%s hand card hides star rarity text", failures)
		_expect(meta_label.text.find("/") >= 0, "%s hand card shows faction and class row", failures)
		_expect(["已选择", "可部署", "星力不足"].has(state_label.text), "%s hand card shows compact state text" % hero_id, failures)


func _check_selected_card_has_stronger_visual_state(screen: Control, failures: Array[String]) -> void:
	var selected_id := _first_visible_hand_id(screen)
	_expect(not selected_id.is_empty(), "selected hand card candidate exists", failures)
	if selected_id.is_empty():
		return

	screen._select_hero(selected_id)
	screen._update_hero_buttons()
	var selected_button: Button = screen.hero_buttons[selected_id]
	var selected_style := selected_button.get_theme_stylebox("normal") as StyleBoxFlat
	var selected_state: Label = selected_button.get_node("HandCardContainer/StateLabel")
	_expect(selected_state.text == "已选择", "selected hand card uses selected state text", failures)
	_expect(selected_style != null, "selected hand card has flat HUD style", failures)
	if selected_style != null:
		var expected_glow: Color = screen._hand_card_rarity_glow(screen.battle_state.get_hero_def(selected_id))
		_expect(_color_distance(selected_style.border_color, expected_glow) < 1.10, "selected hand card uses rarity glow on border", failures)


func _check_clicking_visual_card_keeps_select_behavior(screen: Control, failures: Array[String]) -> void:
	var hero_id := _first_visible_hand_id(screen)
	_expect(not hero_id.is_empty(), "clickable hand card exists", failures)
	if hero_id.is_empty():
		return
	var button: Button = screen.hero_buttons[hero_id]
	button.pressed.emit()
	await process_frame
	_expect(screen.selected_hero_id == hero_id, "clicking visual hand card selects hero", failures)
	_expect(screen.selected_card_hero_id == hero_id, "clicking visual hand card keeps inspect selection in sync", failures)


func _first_visible_hand_id(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		var button: Button = screen.hero_buttons.get(hero_id)
		if button != null and button.visible:
			return hero_id
	return ""


func _color_distance(left: Color, right: Color) -> float:
	return absf(left.r - right.r) + absf(left.g - right.g) + absf(left.b - right.b)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
