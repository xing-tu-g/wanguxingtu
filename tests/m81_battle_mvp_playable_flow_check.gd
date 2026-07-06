extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_initial_hand(screen, failures)
	_check_icon_slots(screen, failures)
	_check_affordability_visual(screen, failures)
	_check_deploy_refills_hand(screen, failures)
	_check_card_detail(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M81 battle MVP playable flow checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_hand(screen: Control, failures: Array[String]) -> void:
	_expect(screen.player_hand.size() == 5, "battle starts with five hand cards", failures)
	_expect(screen.player_deck.size() == screen._player_battle_hero_ids().size() - 5, "draw queue keeps remaining deck after initial draw", failures)
	_expect(not screen.get_node("BottomHand/Controls/ResetButton").visible, "normal battle UI hides reset", failures)


func _check_icon_slots(screen: Control, failures: Array[String]) -> void:
	var button: Button = screen.hero_buttons[0]
	_expect(button.get_node_or_null("HandCardContainer/Portrait") != null, "hand card has portrait slot", failures)
	_expect(_has_icon(button, "HpItem"), "hand card shows HP icon", failures)
	_expect(_has_icon(button, "AttackItem"), "hand card shows attack icon", failures)
	_expect(_has_icon(button, "ClassItem"), "hand card shows class icon", failures)
	_expect(_has_icon(button, "FactionItem"), "hand card shows faction icon", failures)
	var cost_label: Label = button.get_node("HandCardContainer/TopRow/CostLabel")
	_expect(cost_label.text.is_valid_int(), "cost uses numeric value next to icon-ready slot", failures)


func _check_affordability_visual(screen: Control, failures: Array[String]) -> void:
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 0)
	screen._update_hero_buttons()
	for hand_index in range(screen.player_hand.size()):
		var button: Button = screen.hero_buttons[hand_index]
		_expect(button.disabled, "unaffordable hand slot is disabled", failures)
		_expect(button.self_modulate.a < 0.9, "unaffordable hand slot is visually dimmed", failures)
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen._update_hero_buttons()


func _check_deploy_refills_hand(screen: Control, failures: Array[String]) -> void:
	var before_hand: int = screen.player_hand.size()
	var before_deck: int = screen.player_deck.size()
	screen._select_hand_slot(0)
	var selected_before: String = screen.selected_hero_id
	var cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(cell.x, cell.y)
	_expect(screen.battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).size() >= 1, "legal board click deploys selected hero", failures)
	_expect(screen.player_discard.has(selected_before), "deployed card moves to discard", failures)
	_expect(screen.player_hand.size() == before_hand, "hand refills to five after deploy when deck has cards", failures)
	_expect(screen.player_deck.size() == before_deck - 1, "deploy refill consumes one draw_queue card", failures)


func _check_card_detail(screen: Control, failures: Array[String]) -> void:
	var hero_id := str(screen.player_hand[0])
	screen._show_card_detail(hero_id)
	var detail_text := str(screen.unit_detail_body.text)
	_expect(detail_text.contains("阵营"), "card detail includes faction", failures)
	_expect(detail_text.contains("职业"), "card detail includes profession", failures)
	_expect(detail_text.contains("稀有度"), "card detail includes rarity", failures)
	_expect(detail_text.contains("移动"), "card detail includes move", failures)
	_expect(detail_text.contains("射程"), "card detail includes range", failures)
	_expect(detail_text.contains("技能"), "card detail includes skill text", failures)
	_expect(detail_text.contains("背景"), "card detail includes background field", failures)


func _has_icon(button: Button, item_name: String) -> bool:
	var icon := button.get_node_or_null("HandCardContainer/StatsRow/%s/Icon" % item_name) as TextureRect
	return icon != null and icon.texture != null


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		for column in range(1, BoardModelScript.get_cols_for_row(row) + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
