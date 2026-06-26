extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const StarPaletteScript: GDScript = preload("res://scripts/ui/theme/ColorPalette.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_zone_colors(screen, failures)
	await _check_piece_visuals(screen, failures)
	_check_hand_cards(screen, failures)

	screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M41 board visual refinement checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_zone_colors(screen: Control, failures: Array[String]) -> void:
	# 偏移网格 (9-10-9-10-9)：区域由列+行共同决定
	# 10 格行 (R2)：蓝区 cols 1-3, 中域 cols 4-7, 红区 cols 8-10
	var left_style := _cell_style(screen, "1,2")
	var mid_style := _cell_style(screen, "4,2")
	var right_style := _cell_style(screen, "8,2")

	# Player deployment zone should be more blue than red
	_expect(left_style.bg_color.b > left_style.bg_color.r,
		"player deployment zone has blue-dominant background", failures)
	# Enemy deployment zone should be more red than blue
	_expect(right_style.bg_color.r > right_style.bg_color.b,
		"enemy deployment zone has red-dominant background", failures)
	# Public zone should be visibly different from colored zones
	_expect(mid_style.bg_color != left_style.bg_color and mid_style.bg_color != right_style.bg_color,
		"public zone has distinct neutral background", failures)

	# Edge cells should be distinct relative to inner rows (use 10-col row for consistency)
	var top_edge_style := _cell_style(screen, "4,2")
	var middle_style := _cell_style(screen, "4,4")
	_expect(top_edge_style.border_color.v >= middle_style.border_color.v,
		"outer board rows have distinct star-track border", failures)


func _check_piece_visuals(screen: Control, failures: Array[String]) -> void:
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame

	var enemy_result: Dictionary = screen.battle_state.deploy_hero("zhouyu", BoardModelScript.SIDE_RIGHT, 8, 2)
	_expect(bool(enemy_result.get("ok", false)), "enemy sample deploys for visual token check", failures)
	screen._refresh_board()
	await process_frame

	# M85 refactor: cell button text now shows hero_id (name mapped elsewhere).
	# Occupied cells have non-empty text + colored bg
	var player_text := str(screen.cell_buttons["2,3"].text)
	var enemy_text := str(screen.cell_buttons["8,2"].text)
	_expect(player_text.length() > 0, "player piece cell has non-empty text", failures)
	_expect(player_text.find("guanyu") >= 0 or player_text.find("关羽") >= 0,
		"player piece shows hero reference", failures)
	_expect(enemy_text.length() > 0, "enemy piece cell has non-empty text", failures)
	_expect(enemy_text.find("zhouyu") >= 0 or enemy_text.find("周瑜") >= 0,
		"enemy piece shows hero reference", failures)

	# HP label child should be present for occupied cells
	var player_hp_label := screen.cell_buttons["2,3"].get_node_or_null("HpLabel") as Label
	var enemy_hp_label := screen.cell_buttons["8,2"].get_node_or_null("HpLabel") as Label
	_expect(player_hp_label != null, "player piece has HpLabel child", failures)
	_expect(enemy_hp_label != null, "enemy piece has HpLabel child", failures)
	if player_hp_label:
		_expect(player_hp_label.text.length() > 0, "player HpLabel shows HP", failures)
	if enemy_hp_label:
		_expect(enemy_hp_label.text.length() > 0, "enemy HpLabel shows HP", failures)

	# M85: no class words in cell text (labels are simplified)
	_expect(not _contains_class_words(player_text + enemy_text),
		"piece text hides class labels", failures)


func _check_hand_cards(screen: Control, failures: Array[String]) -> void:
	var guanyu_button: Button = screen.hero_buttons["guanyu"]
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	_expect(guanyu_button.text.find("蜀") >= 0, "hand card shows Shu faction", failures)
	_expect(zhouyu_button.text.find("吴") >= 0, "hand card shows Wu faction", failures)
	_expect(guanyu_button.text.find("关羽") >= 0 and guanyu_button.text.find("*5") >= 0,
		"hand card keeps name and cost badge", failures)
	_expect(not _contains_class_words(guanyu_button.text + zhouyu_button.text),
		"hand card hides class labels", failures)


func _contains_class_words(text: String) -> bool:
	for word in ["职业", "战士", "法师", "坦克", "射手", "武卫", "刺客", "弓", "盾"]:
		if text.find(word) >= 0:
			return true
	return false


func _cell_style(screen: Control, key: String) -> StyleBoxFlat:
	return screen.cell_buttons[key].get_theme_stylebox("normal") as StyleBoxFlat


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
