extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const ResultScreenScene: PackedScene = preload("res://scenes/ui/ResultScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(3, 3)
	await process_frame
	_expect(screen.last_touched_cell == Vector2i(3, 3), "deployment records the tapped cell", failures)
	var touched_style: StyleBoxFlat = screen.cell_buttons["3,3"].get_theme_stylebox("normal")
	_expect(touched_style.border_color == screen.COLOR_HIGHLIGHT_SELECTED, "tapped cell gets a visible cyan selection border", failures)
	_expect(touched_style.get_border_width(SIDE_LEFT) >= 4, "tapped cell border is thick enough for mobile", failures)

	screen._advance_turn()
	await process_frame
	screen._advance_turn()
	await process_frame
	_expect(screen.last_action_cells.size() > 0, "turn actions record highlighted board cells", failures)
	_expect(screen.battle_log_text.text.find("回合开始") >= 0, "battle log keeps latest turn entries visible", failures)

	screen.queue_free()

	var result_screen = ResultScreenScene.instantiate()
	root.add_child(result_screen)
	result_screen.set_result({
		"outcome": "left_wins",
		"round_number": 5,
		"left_hp": 30,
		"right_hp": 0,
		"left_survivors": 2,
		"right_survivors": 0,
	})
	await process_frame
	var body_label: Label = result_screen.get_node("Margin/Layout/Body")
	_expect(body_label.text.find("下一步") >= 0, "result screen explains the next action", failures)
	_expect(body_label.text.find("left_wins") < 0, "result screen hides raw outcome ids", failures)
	result_screen.queue_free()

	if failures.is_empty():
		print("M8 mobile polish checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)