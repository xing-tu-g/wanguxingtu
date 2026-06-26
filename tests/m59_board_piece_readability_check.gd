extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.get_script():
		failures.append("FAIL: battle screen script failed to load")
		_finish(screen, failures)
		return

	_check_empty_cell_readability(screen, failures)
	await _check_unit_piece_readability(screen, failures)
	_finish(screen, failures)


func _check_empty_cell_readability(screen: Control, failures: Array[String]) -> void:
	var player_text := str(screen.cell_buttons["1,1"].text)
	var public_text := str(screen.cell_buttons["4,1"].text)
	var enemy_text := str(screen.cell_buttons["8,1"].text)
	_expect(player_text.contains("蓝区 L1"), "player empty cell has compact blue-zone code", failures)
	_expect(player_text.contains("1,1"), "player empty cell keeps coordinate", failures)
	_expect(public_text.contains("中域 C4"), "public empty cell has compact center-zone code", failures)
	_expect(enemy_text.contains("红区 R8"), "enemy empty cell has compact red-zone code", failures)


func _check_unit_piece_readability(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	var enemy_result: Dictionary = screen.battle_state.deploy_hero("zhouyu", BoardModelScript.SIDE_RIGHT, 8, 1)
	_expect(bool(enemy_result.get("ok", false)), "enemy unit deploys for readability check", failures)
	screen._refresh_board()
	await process_frame

	var player_cell: Button = screen.cell_buttons["1,1"]
	var enemy_cell: Button = screen.cell_buttons["8,1"]
	var player_text := str(player_cell.text)
	var enemy_text := str(enemy_cell.text)
	_expect(player_text.contains(">我方") and player_text.contains("蜀"), "player unit shows side arrow and faction", failures)
	_expect(enemy_text.contains("<敌方") and enemy_text.contains("吴"), "enemy unit shows side arrow and faction", failures)
	_expect(player_text.contains("HP 8/8"), "player unit shows numeric HP", failures)
	_expect(enemy_text.contains("HP 6/6"), "enemy unit shows numeric HP", failures)
	_expect(_normal_style(player_cell).get_border_width(SIDE_LEFT) >= 5, "unit piece has stronger base border", failures)
	_expect(_normal_style(player_cell).content_margin_top >= 8, "unit piece has larger content margin", failures)


func _normal_style(button: Button) -> StyleBoxFlat:
	return button.get_theme_stylebox("normal") as StyleBoxFlat


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M59 board piece readability checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
