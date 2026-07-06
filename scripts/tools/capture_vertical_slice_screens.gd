extends SceneTree

const DeckScreenScene: PackedScene = preload("res://scenes/ui/DeckScreen.tscn")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const OUTPUT_DIR := "res://tmp/vertical_slice"


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var ok := true
	ok = await _capture_deck() and ok
	ok = await _capture_battle() and ok
	if not ok:
		quit(1)
		return
	print("VERTICAL_SLICE_SCREENSHOTS_CLEAN")
	quit(0)


func _capture_deck() -> bool:
	var screen: Control = DeckScreenScene.instantiate()
	root.add_child(screen)
	await _settle_frames(4)
	var ok := await _save_viewport("deck_screen.png")
	screen.queue_free()
	await process_frame
	return ok


func _capture_battle() -> bool:
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await _settle_frames(5)
	_deploy_first_affordable(screen)
	await _settle_frames(4)
	var ok := await _save_viewport("battle_screen_deployed.png")
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
