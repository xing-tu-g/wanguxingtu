extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var recommended_count := 0
	var expected_count := 0
	for row in range(1, BoardModelScript.ROWS + 1):
		var deploy_width: int = BoardModelScript.get_deployment_width_for_row(row)
		expected_count += deploy_width
		for column in range(1, deploy_width + 1):
			if screen._should_show_recommended_deploy_cell(column, row):
				recommended_count += 1
	_expect(recommended_count == expected_count and expected_count == 12, "all empty left deployment cells are recommended before first deploy", failures)
	_expect(not screen._should_show_recommended_deploy_cell(3, 3), "row 3 third column is public area, not recommended", failures)
	_expect(not screen._should_show_recommended_deploy_cell(4, 3), "public area is not recommended", failures)
	_expect(not screen._should_show_recommended_deploy_cell(8, 3), "enemy deployment area is not recommended", failures)

	var recommended_button: Button = screen.cell_buttons[screen._cell_key(2, 3)]
	var recommended_backplate := recommended_button.get_node_or_null("GridBackplate") as TextureRect
	_expect(recommended_backplate != null and recommended_backplate.texture != null, "recommended cell has grid backplate", failures)
	if recommended_backplate != null and recommended_backplate.texture != null:
		_expect(recommended_backplate.texture.resource_path.ends_with("grid_blue_hover.png"), "recommended cell uses hover deploy texture", failures)

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen._refresh_board()
	await process_frame
	_expect(not screen._should_show_recommended_deploy_cell(2, 3), "dismissed first deploy hint hides recommended cells", failures)
	var dismissed_backplate := screen.cell_buttons[screen._cell_key(2, 3)].get_node_or_null("GridBackplate") as TextureRect
	_expect(dismissed_backplate != null and dismissed_backplate.texture != null and dismissed_backplate.texture.resource_path.ends_with("grid_blue_idle.png"), "dismissed hint restores idle blue texture", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(screen._should_show_recommended_deploy_cell(2, 3), "reset restores recommended cells", failures)

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen._should_show_recommended_deploy_cell(1, 1), "successful first deployment hides remaining recommended cells", failures)
	var remaining_backplate := screen.cell_buttons[screen._cell_key(1, 1)].get_node_or_null("GridBackplate") as TextureRect
	_expect(remaining_backplate != null and remaining_backplate.texture != null and remaining_backplate.texture.resource_path.ends_with("grid_blue_idle.png"), "remaining empty deployment cells return to idle texture after first deploy", failures)

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
