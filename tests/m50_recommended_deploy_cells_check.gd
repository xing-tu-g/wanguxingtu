extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var recommended_count := 0
	for column in range(1, 4):
		for row in range(1, BoardModelScript.ROWS + 1):
			if screen._should_show_recommended_deploy_cell(column, row):
				recommended_count += 1
	_expect(recommended_count == 15, "all empty left deployment cells are recommended before first deploy", failures)
	_expect(not screen._should_show_recommended_deploy_cell(4, 3), "public area is not recommended", failures)
	_expect(not screen._should_show_recommended_deploy_cell(8, 3), "enemy deployment area is not recommended", failures)

	var recommended_button: Button = screen.cell_buttons[screen._cell_key(2, 3)]
	_expect(recommended_button.text.contains("● 可上阵"), "recommended cell text includes deployment hint", failures)
	var recommended_style: StyleBoxFlat = recommended_button.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(recommended_style != null, "recommended cell has style", failures)
	if recommended_style != null:
		_expect(recommended_style.border_color.is_equal_approx(Color(1.0, 0.82, 0.24, 1.0)), "recommended cell uses gold border", failures)
		_expect(recommended_style.get_border_width(SIDE_LEFT) >= 5, "recommended cell has thicker border", failures)

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen._refresh_board()
	await process_frame
	_expect(not screen._should_show_recommended_deploy_cell(2, 3), "dismissed first deploy hint hides recommended cells", failures)
	_expect(not str(screen.cell_buttons[screen._cell_key(2, 3)].text).contains("● 可上阵"), "dismissed hint removes recommended text", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(screen._should_show_recommended_deploy_cell(2, 3), "reset restores recommended cells", failures)

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen._should_show_recommended_deploy_cell(1, 1), "successful first deployment hides remaining recommended cells", failures)
	_expect(not str(screen.cell_buttons[screen._cell_key(1, 1)].text).contains("● 可上阵"), "remaining empty deployment cells lose recommended text after first deploy", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M50 recommended deployment cell checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
