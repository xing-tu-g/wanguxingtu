extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var selected_id := _first_affordable_hand_hero(screen)
	var other_id := _second_visible_hand_hero(screen, selected_id)
	_expect(not selected_id.is_empty(), "test finds an affordable hand card", failures)
	_expect(not other_id.is_empty(), "test finds another visible hand card", failures)
	if selected_id.is_empty() or other_id.is_empty():
		_finish(screen, failures)
		return

	var selected_button: Button = screen.hero_buttons[selected_id]
	var other_button: Button = screen.hero_buttons[other_id]
	screen._select_hero(selected_id)
	await process_frame
	_expect(_state_label(selected_button).text == "已选择", "selected card shows selected label", failures)
	_expect(selected_button.custom_minimum_size.x > other_button.custom_minimum_size.x, "selected card is visually larger", failures)
	_expect(_normal_style(selected_button).border_color != _normal_style(other_button).border_color, "selected card tint differs from normal card", failures)

	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 0)
	screen._update_hero_buttons()
	await process_frame
	_expect(_state_label(other_button).text == "星力不足" or _state_label(selected_button).text == "星力不足", "unaffordable hand card shows low-star label", failures)

	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen._select_hero(selected_id)
	var selected_slot: int = screen.selected_hand_index
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	await process_frame
	_expect(selected_button.visible, "deployed hand slot remains visible after refill/consume", failures)
	_expect(selected_slot < 0 or selected_slot >= screen.player_hand.size() or str(screen.player_hand[selected_slot]) != selected_id, "deployed card is replaced or slot becomes empty", failures)
	_expect(screen.player_hand.size() <= 5, "hand row remains capped after deployment", failures)

	_finish(screen, failures)


func _state_label(button: Button) -> Label:
	return button.get_node("HandCardContainer/StateLabel") as Label


func _normal_style(button: Button) -> StyleBoxFlat:
	return button.get_theme_stylebox("normal") as StyleBoxFlat


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return ""


func _second_visible_hand_hero(screen: Control, excluded_id: String) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if hero_id != excluded_id:
			return hero_id
	return ""


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M56 hand card hierarchy checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
