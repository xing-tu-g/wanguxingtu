extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_expanded_card_list_and_initial_inspect(failures)
	await _check_clicking_card_updates_inspect_panel(failures)
	await _check_deploy_refreshes_list_and_inspect(failures)
	await _check_draw_and_reset_refresh_card_list(failures)
	await process_frame

	if failures.is_empty():
		print("M31 card list inspect checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_expanded_card_list_and_initial_inspect(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_cards.visible, "expanded card zone shows clickable card list", failures)
	_expect(screen.card_inspect_label.visible, "expanded card zone shows inspect label", failures)
	_expect(_button_has_fragments(screen.card_zone_cards, ["关羽", "费5", "阵营：蜀"]), "player hand card button shows name cost and faction", failures)
	_expect(_button_has_fragments(screen.card_zone_cards, ["赵云", "费4", "阵营：蜀"]), "enemy hand card button shows name cost and faction", failures)
	_expect(screen.card_inspect_label.text.find("[b]关羽[/b]｜费用 5｜阵营 蜀") >= 0, "initial inspect selects first player hand card", failures)
	_expect(screen.card_inspect_label.text.find("生命 8｜攻击 4｜射程 1｜移动 3") >= 0, "inspect shows combat stats", failures)
	_expect(screen.card_inspect_label.text.find("武圣成长") >= 0, "inspect shows skill name", failures)
	screen.queue_free()


func _check_clicking_card_updates_inspect_panel(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	var zhouyu_button := _find_button(screen.card_zone_cards, "周瑜")
	_expect(zhouyu_button != null, "zhouyu card button exists", failures)
	if zhouyu_button != null:
		zhouyu_button.pressed.emit()
		await process_frame
		_expect(screen.selected_card_hero_id == "zhouyu", "clicking card stores inspected hero id", failures)
		_expect(screen.card_inspect_label.text.find("周瑜") >= 0, "clicking card updates inspect name", failures)
		_expect(screen.card_inspect_label.text.find("阵营 吴") >= 0, "clicking card updates inspect faction", failures)
		_expect(screen.card_inspect_label.text.find("赤壁灼烧") >= 0, "clicking card updates inspect skill", failures)
	screen.queue_free()


func _check_deploy_refreshes_list_and_inspect(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.card_zone_cards.visible, "expanded card list remains visible after deploy", failures)
	_expect(_button_text_exists(screen.card_zone_cards, "我方弃牌", "关羽"), "deployed card appears in player discard row", failures)
	_expect(not _button_text_exists(screen.card_zone_cards, "我方手牌", "关羽"), "deployed card leaves player hand row", failures)
	_expect(screen.card_inspect_label.text.find("关羽") >= 0, "inspect can keep showing deployed card details", failures)
	screen.queue_free()


func _check_draw_and_reset_refresh_card_list(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	screen._advance_turn()
	await process_frame
	_expect(_button_text_exists(screen.card_zone_cards, "我方手牌", "赵云"), "drawn player card appears in hand row", failures)
	screen._reset_debug_battle()
	await process_frame
	_expect(_button_text_exists(screen.card_zone_cards, "我方手牌", "关羽"), "reset refreshes player hand row", failures)
	_expect(not _button_text_exists(screen.card_zone_cards, "我方手牌", "赵云"), "reset removes drawn card from hand row", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _find_button(root_node: Node, text_fragment: String) -> Button:
	if root_node is Button and str(root_node.text).find(text_fragment) >= 0:
		return root_node
	for child in root_node.get_children():
		var found := _find_button(child, text_fragment)
		if found != null:
			return found
	return null


func _button_has_fragments(root_node: Node, fragments: Array[String]) -> bool:
	if root_node is Button:
		var button_text := str(root_node.text)
		for fragment in fragments:
			if button_text.find(fragment) < 0:
				return false
		return true
	for child in root_node.get_children():
		if _button_has_fragments(child, fragments):
			return true
	return false


func _button_text_exists(root_node: Node, section_fragment: String, button_fragment: String = "") -> bool:
	if button_fragment.is_empty():
		return _find_button(root_node, section_fragment) != null
	for row in root_node.get_children():
		if not row is HBoxContainer:
			continue
		var row_text := ""
		for child in row.get_children():
			if child is Label:
				row_text += str(child.text)
		if row_text.find(section_fragment) >= 0 and _find_button(row, button_fragment) != null:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
