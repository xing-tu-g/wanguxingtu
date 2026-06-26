extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_star_map_background(screen, failures)
	_check_board_zone_colors_and_labels(screen, failures)
	_check_master_visual_placeholders(screen, failures)
	await _check_piece_text_and_highlights(screen, failures)
	await process_frame

	screen.queue_free()
	if failures.is_empty():
		print("M39 battle visual placeholder checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_star_map_background(screen: Control, failures: Array[String]) -> void:
	var background: ColorRect = screen.get_node("Background")
	_expect(_color_close(background.color, screen.COLOR_STAR_BG, 0.02), "background uses deep blue star map base", failures)
	_expect(screen.has_node("Background/StarDots/StarDotA"), "star dot placeholder exists", failures)
	_expect(screen.has_node("Background/StarDots/StarDotE"), "multiple star dots exist", failures)
	_expect(screen.has_node("Background/StarOrbitBlue"), "blue star orbit placeholder exists", failures)
	_expect(screen.has_node("Background/StarOrbitGold"), "gold star orbit placeholder exists", failures)


func _check_board_zone_colors_and_labels(screen: Control, failures: Array[String]) -> void:
	var legend: Label = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/Legend")
	_expect(legend.text.find("蓝区 1-3") >= 0, "legend labels player deployment with compact text", failures)
	_expect(legend.text.find("星图区 4-7") >= 0, "legend labels public star area with compact text", failures)
	_expect(legend.text.find("红区 8-10") >= 0, "legend labels enemy deployment with compact text", failures)
	var left_style := _cell_style(screen, "1,1")
	var public_style := _cell_style(screen, "4,1")
	var right_style := _cell_style(screen, "8,1")
	_expect(_color_close(left_style.bg_color, screen.COLOR_ZONE_PLAYER.lightened(0.18), 0.04), "left deployment recommendation keeps blue base glow", failures)
	_expect(_color_close(left_style.border_color, Color(1.0, 0.82, 0.24, 1.0).lightened(0.18), 0.04), "left deployment recommendation uses bright gold border", failures)
	_expect(_color_close(public_style.bg_color, screen.COLOR_ZONE_PUBLIC, 0.04), "public cells use gold style", failures)
	_expect(_color_close(right_style.bg_color, screen.COLOR_ZONE_ENEMY, 0.04), "enemy deployment cells use red-purple style", failures)
	_expect(str(screen.cell_buttons["1,1"].text).find("蓝区") >= 0, "empty player cells keep compact deployment label", failures)
	_expect(str(screen.cell_buttons["4,1"].text).find("中域") >= 0, "empty public cells keep compact star-area label", failures)
	_expect(str(screen.cell_buttons["8,1"].text).find("红区") >= 0, "empty enemy cells keep compact deployment label", failures)


func _check_master_visual_placeholders(screen: Control, failures: Array[String]) -> void:
	var player_portrait: Label = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerMasterPortrait")
	var enemy_portrait: Label = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyMasterPortrait")
	var player_status: Label = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerMasterStatus")
	var enemy_status: Label = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyMasterStatus")
	_expect(player_portrait.text.find("我方剪影") >= 0, "player master uses recognizable silhouette placeholder", failures)
	_expect(player_portrait.text.find("奕星师") >= 0, "player master keeps correct title text", failures)
	_expect(player_portrait.text.find("⇢") >= 0, "player master faces board", failures)
	_expect(player_portrait.text.find("状态") >= 0, "player master shows state hint", failures)
	_expect(enemy_portrait.text.find("敌方剪影") >= 0, "enemy master uses recognizable silhouette placeholder", failures)
	_expect(enemy_portrait.text.find("奕星师") >= 0, "enemy master keeps correct title text", failures)
	_expect(enemy_portrait.text.find("⇠") >= 0, "enemy master faces board", failures)
	_expect(enemy_portrait.text.find("状态") >= 0, "enemy master shows state hint", failures)
	_expect(player_status.text.find("称号") >= 0, "player master has title/status sublabel", failures)
	_expect(enemy_status.text.find("称号") >= 0, "enemy master has title/status sublabel", failures)


func _check_piece_text_and_highlights(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	var enemy_result: Dictionary = screen.battle_state.deploy_hero("zhouyu", BoardModelScript.SIDE_RIGHT, 8, 1)
	_expect(bool(enemy_result.get("ok", false)), "enemy visual sample deploys without changing rules", failures)
	screen.last_action_cells.clear()
	screen.last_action_cells.append(Vector2i(8, 1))
	screen._refresh_board()
	await process_frame

	var player_cell: Button = screen.cell_buttons["1,1"]
	var enemy_cell: Button = screen.cell_buttons["8,1"]
	_expect(player_cell.text.find("我方") >= 0, "player piece text marks side", failures)
	_expect(player_cell.text.find("关羽") >= 0, "player piece text keeps hero name", failures)
	_expect(player_cell.text.find("HP") >= 0, "player piece text shows HP label", failures)
	_expect(player_cell.text.find("HP") >= 0 and player_cell.text.find("/") >= 0, "player piece text shows readable HP", failures)
	_expect(enemy_cell.text.find("敌方") >= 0, "enemy piece text marks side", failures)
	_expect(enemy_cell.text.find("周瑜") >= 0, "enemy piece text keeps hero name", failures)
	_expect(enemy_cell.text.find("HP") >= 0, "enemy piece text shows HP label", failures)
	var player_style := _cell_style(screen, "1,1")
	var enemy_style := _cell_style(screen, "8,1")
	_expect(_color_close(player_style.bg_color, screen.COLOR_PIECE_PLAYER.lightened(0.39), 0.05), "player piece keeps blue chess-piece color with active-side glow", failures)
	_expect(_color_close(enemy_style.border_color, screen.COLOR_HIGHLIGHT_ACTION, 0.04), "recent action highlight is strongly gold", failures)
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	var selected_style := _cell_style(screen, "1,1")
	_expect(screen.unit_detail_panel.visible, "piece click still opens unit detail", failures)
	_expect(_color_close(selected_style.border_color, screen.COLOR_HIGHLIGHT_SELECTED, 0.04), "selected piece highlight is strongly cyan", failures)

	var hand_button: Button = screen.hero_buttons["zhouyu"]
	_expect(hand_button.text.find("吴") >= 0, "hand buttons show faction only", failures)
	_expect(hand_button.text.find("*5") >= 0, "hand buttons show compact fee badge", failures)
	_expect(hand_button.text.find("法师") < 0 and hand_button.text.find("吴国") < 0, "hand buttons hide class token", failures)


func _cell_style(screen: Control, key: String) -> StyleBoxFlat:
	return screen.cell_buttons[key].get_theme_stylebox("normal") as StyleBoxFlat


func _color_close(left: Color, right: Color, tolerance: float) -> bool:
	return abs(left.r - right.r) <= tolerance and abs(left.g - right.g) <= tolerance and abs(left.b - right.b) <= tolerance and abs(left.a - right.a) <= tolerance


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
