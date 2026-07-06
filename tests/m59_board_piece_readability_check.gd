extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_empty_cell_readability(screen, failures)
	await _check_unit_piece_readability(screen, failures)
	_finish(screen, failures)


func _check_empty_cell_readability(screen: Control, failures: Array[String]) -> void:
	_expect(str(screen.cell_buttons["1,1"].text).is_empty(), "player empty cell does not show debug coordinate copy", failures)
	_expect(str(screen.cell_buttons["4,1"].text).is_empty(), "public empty cell does not show debug coordinate copy", failures)
	_expect(str(screen.cell_buttons["8,1"].text).is_empty(), "enemy empty cell does not show debug coordinate copy", failures)
	_expect((screen.battle_board_view.cell_backplates["1,1"] as TextureRect).texture != null, "player empty cell has zone texture", failures)
	_expect((screen.battle_board_view.cell_backplates["4,1"] as TextureRect).texture != null, "public empty cell has zone texture", failures)
	_expect((screen.battle_board_view.cell_backplates["8,1"] as TextureRect).texture != null, "enemy empty cell has zone texture", failures)


func _check_unit_piece_readability(screen: Control, failures: Array[String]) -> void:
	var hero_id := _first_affordable_hand_hero(screen)
	screen.selected_hero_id = hero_id
	var player_cell := _first_deploy_cell(screen)
	screen._deploy_selected_to_cell(player_cell.x, player_cell.y)
	await process_frame
	var enemy_cell := Vector2i(8, 1)
	var enemy_result: Dictionary = screen.battle_state.deploy_hero("zhouyu", BoardModelScript.SIDE_RIGHT, enemy_cell.x, enemy_cell.y)
	_expect(bool(enemy_result.get("ok", false)), "enemy unit deploys for readability check", failures)
	screen._refresh_board()
	await process_frame

	var player_key: String = screen._cell_key(player_cell.x, player_cell.y)
	var enemy_key: String = screen._cell_key(enemy_cell.x, enemy_cell.y)
	var player_button: Button = screen.cell_buttons[player_key]
	var enemy_button: Button = screen.cell_buttons[enemy_key]
	var player_hp: Label = player_button.get_node("HpLabel") as Label
	var enemy_hp: Label = enemy_button.get_node("HpLabel") as Label
	var player_portrait: TextureRect = screen.battle_board_view.cell_portraits[player_key]
	var enemy_portrait: TextureRect = screen.battle_board_view.cell_portraits[enemy_key]
	_expect(not player_button.text.is_empty(), "player unit keeps compact id label", failures)
	_expect(not enemy_button.text.is_empty(), "enemy unit keeps compact id label", failures)
	_expect(player_hp.text.contains("/"), "player unit shows numeric HP label", failures)
	_expect(enemy_hp.text.contains("/"), "enemy unit shows numeric HP label", failures)
	_expect(player_portrait.texture != null, "player unit shows portrait texture", failures)
	_expect(enemy_portrait.texture != null, "enemy unit shows portrait texture", failures)


func _first_affordable_hand_hero(screen: Control) -> String:
	for hero_id_value in screen.player_hand:
		var hero_id := str(hero_id_value)
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			return hero_id
	return ""


func _first_deploy_cell(screen: Control) -> Vector2i:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			if screen.battle_state.board.can_deploy(BoardModelScript.SIDE_LEFT, column, row):
				return Vector2i(column, row)
	return Vector2i(1, 1)


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
