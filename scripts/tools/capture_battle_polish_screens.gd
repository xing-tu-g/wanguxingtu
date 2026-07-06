extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const ResultScreenScene: PackedScene = preload("res://scenes/ui/ResultScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const OUTPUT_DIR := "res://tmp/battle_polish"


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var ok := true
	ok = await _capture_battle_feedback() and ok
	ok = await _capture_result_screen() and ok
	Engine.time_scale = 1.0
	if not ok:
		quit(1)
		return
	print("BATTLE_POLISH_SCREENSHOTS_CLEAN")
	quit(0)


func _capture_battle_feedback() -> bool:
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await _settle_frames(6)
	_deploy_first_affordable(screen)
	await _settle_frames(6)
	for _i in range(3):
		screen._advance_turn()
		await _settle_frames(8)
	var ok := await _save_viewport("battle_feedback.png")
	screen.queue_free()
	await process_frame
	return ok


func _capture_result_screen() -> bool:
	var screen: Control = ResultScreenScene.instantiate()
	root.add_child(screen)
	screen.set_result({
		"outcome": "left_wins",
		"round_number": 12,
		"left_hp": 18,
		"right_hp": 0,
		"left_survivors": 4,
		"right_survivors": 0,
		"stats": {
			"deployments": {"left": 6, "right": 6},
			"units_defeated": {"left": 8, "right": 3},
			"unit_damage_dealt": {"left": 66, "right": 31},
			"master_damage_dealt": {"left": 30, "right": 7},
		},
	})
	await _settle_frames(6)
	var ok := await _save_viewport("result_screen.png")
	screen.queue_free()
	await process_frame
	return ok


func _deploy_first_affordable(screen: Control) -> void:
	var hero_id := ""
	for hero_id_value in screen.player_hand:
		var candidate := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, candidate):
			hero_id = candidate
			break
	if hero_id.is_empty():
		return
	screen.selected_hero_id = hero_id
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				screen._deploy_selected_to_cell(column, row)
				return


func _save_viewport(file_name: String) -> bool:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("SCREENSHOT_FAILED: %s" % file_name)
		return false
	image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
	return true


func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
