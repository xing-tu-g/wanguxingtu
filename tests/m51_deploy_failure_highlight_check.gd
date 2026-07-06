extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BattleUIAssetsScript: GDScript = preload("res://scripts/ui/theme/BattleUIAssets.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.first_deploy_hint_button.pressed.emit()
	await process_frame
	screen._refresh_board()
	await process_frame
	_expect(not screen._should_show_recommended_deploy_cell(2, 3), "dismissed first-deploy hint hides recommendation before failure", failures)

	var hero_id := _first_affordable_hand_hero(screen)
	screen.selected_hero_id = hero_id
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "wrong-zone failure activates deployment-area highlight", failures)
	_expect(screen._should_show_recommended_deploy_cell(2, 3), "wrong-zone failure highlights empty own deployment cells", failures)
	_expect(not screen._should_show_recommended_deploy_cell(5, 3), "wrong-zone failure does not highlight public cells", failures)
	var highlighted_backplate: TextureRect = screen.battle_board_view.cell_backplates[screen._cell_key(2, 3)]
	_expect(highlighted_backplate.texture == BattleUIAssetsScript.grid_texture("left_deployment", "grass", false, true), "highlighted cell uses blue hover texture", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "successful deployment clears failure highlight", failures)
	_expect(not screen._should_show_recommended_deploy_cell(1, 1), "successful deployment hides remaining recommendation cells", failures)

	screen.selected_hero_id = _first_affordable_hand_hero(screen)
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.deploy_failure_highlight_active, "failure highlight can reactivate after a later wrong-zone click", failures)
	screen._advance_turn()
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "advancing turn clears failure highlight", failures)

	screen._reset_debug_battle()
	await process_frame
	_expect(not screen.deploy_failure_highlight_active, "reset clears failure highlight", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M51 deployment failure highlight checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford("left", hero_id):
			return hero_id
	return ""


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
