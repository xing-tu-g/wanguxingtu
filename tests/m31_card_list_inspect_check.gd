extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_cards.visible, "expanded card zone shows clickable card list", failures)
	_expect(screen.card_inspect_label.visible, "expanded card zone shows inspect label", failures)
	_expect(_count_buttons(screen.card_zone_cards) > 0, "card zone builds card buttons", failures)
	var button := _first_button(screen.card_zone_cards)
	if button != null:
		button.pressed.emit()
		await process_frame
		_expect(screen.selected_card_hero_id.length() > 0, "clicking card stores inspected hero id", failures)
		_expect(screen.card_inspect_label.text.length() > 0, "clicking card updates inspect text", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M31 card list inspect checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _first_button(root_node: Node) -> Button:
	if root_node is Button:
		return root_node
	for child in root_node.get_children():
		var found := _first_button(child)
		if found != null:
			return found
	return null


func _count_buttons(root_node: Node) -> int:
	var count := 0
	if root_node is Button:
		count += 1
	for child in root_node.get_children():
		count += _count_buttons(child)
	return count


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
