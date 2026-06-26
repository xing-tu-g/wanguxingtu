extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_background_readability(screen, failures)
	_check_master_panel_backplates(screen, failures)
	_check_hand_card_density(screen, failures)
	_check_board_shape(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M67 battle readability hierarchy checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_background_readability(screen: Control, failures: Array[String]) -> void:
	_expect(screen.background_readability_wash.color.a >= 0.56, "main readability wash is stronger than M66", failures)
	_expect(screen.has_node("Background/TopReadabilityWash"), "top local readability wash exists", failures)
	_expect(screen.has_node("Background/BattleReadabilityWash"), "battle area local readability wash exists", failures)
	var top_wash: ColorRect = screen.get_node("Background/TopReadabilityWash")
	var battle_wash: ColorRect = screen.get_node("Background/BattleReadabilityWash")
	_expect(top_wash.color.a >= 0.16 and top_wash.color.a <= 0.28, "top wash darkens text zone without killing art", failures)
	_expect(battle_wash.color.a >= 0.08 and battle_wash.color.a <= 0.18, "board wash is present but restrained", failures)

	for dot_name in ["StarDotA", "StarDotB", "StarDotC", "StarDotD", "StarDotE"]:
		var dot: ColorRect = screen.get_node("Background/StarDots/%s" % dot_name)
		_expect(dot.color.a <= 0.34, "%s alpha is subdued" % dot_name, failures)

	var blue_orbit: Line2D = screen.get_node("Background/StarOrbitBlue")
	var gold_orbit: Line2D = screen.get_node("Background/StarOrbitGold")
	_expect(blue_orbit.default_color.a <= 0.12, "blue star orbit alpha is lower than M66", failures)
	_expect(gold_orbit.default_color.a <= 0.10, "gold star orbit alpha is lower than M66", failures)
	_expect(blue_orbit.width <= 2.0 and gold_orbit.width <= 1.5, "star orbit strokes are thinner", failures)


func _check_master_panel_backplates(screen: Control, failures: Array[String]) -> void:
	var player_style := screen.player_master_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var enemy_style := screen.enemy_master_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(player_style != null and enemy_style != null, "master panel styleboxes are applied", failures)
	if player_style == null or enemy_style == null:
		return
	_expect(player_style.bg_color.a >= 0.95, "player master panel has stronger backplate opacity", failures)
	_expect(enemy_style.bg_color.a >= 0.95, "enemy master panel has stronger backplate opacity", failures)
	_expect(player_style.border_color.a >= 0.95, "player master panel border is clearer", failures)
	_expect(enemy_style.border_color.a >= 0.95, "enemy master panel border is clearer", failures)
	_expect(player_style.get_border_width(SIDE_LEFT) >= 6 or enemy_style.get_border_width(SIDE_LEFT) >= 6, "active master panel keeps a strong outline", failures)


func _check_hand_card_density(screen: Control, failures: Array[String]) -> void:
	screen._update_hero_buttons()
	await process_frame
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	var text := str(zhouyu_button.text)
	_expect(_contains_any(text, ["周瑜", "Zhou Yu"]), "hand card keeps hero name", failures)
	_expect(text.contains("5"), "hand card keeps cost value", failures)
	_expect(not text.contains("faction"), "hand card does not spend space on faction label prefix", failures)
	_expect(text.length() >= 8 and text.length() <= 80, "hand card keeps concise state text", failures)
	_expect(not _contains_long_card_copy(text), "hand card hides long descriptions, class words, and blood bars", failures)
	_expect(zhouyu_button.custom_minimum_size.y <= 116.0, "hand card height stays compact after text trim", failures)


func _check_board_shape(screen: Control, failures: Array[String]) -> void:
	_expect(screen.grid.columns == BoardModelScript.COLUMNS, "board grid still has 10 columns", failures)
	_expect(screen.grid.get_child_count() == BoardModelScript.COLUMNS * BoardModelScript.ROWS, "board grid still has 10x5 cells", failures)


func _contains_long_card_copy(text: String) -> bool:
	for forbidden in ["class", "skill", "HP ", "||||", "attack", "range", "move"]:
		if text.contains(forbidden):
			return true
	return false


func _contains_any(text: String, fragments: Array) -> bool:
	for fragment in fragments:
		if text.contains(str(fragment)):
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
