extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_master_hud_meters(screen, failures)
	_check_active_master_glow(screen, failures)
	await _check_active_glow_switches_after_turn(screen, failures)
	await process_frame

	screen.queue_free()
	if failures.is_empty():
		print("M43 master HUD glow checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_master_hud_meters(screen: Control, failures: Array[String]) -> void:
	var player_text := str(screen.player_hud_label.text)
	var enemy_text := str(screen.enemy_hud_label.text)
	_expect(player_text.find("我方 - ● 当前行动") >= 0, "player HUD marks current acting master", failures)
	_expect(enemy_text.find("敌方 - 待命观星") >= 0, "enemy HUD marks standby master", failures)
	_expect(player_text.find("HP ■■■■■■■■■■ 30/30") >= 0, "player HUD shows full HP bar", failures)
	_expect(enemy_text.find("HP ■■■■■■■■■■ 30/30") >= 0, "enemy HUD shows full HP bar", failures)
	_expect(player_text.find("星力 *****..... 5") >= 0, "player HUD shows star-power pips", failures)
	_expect(enemy_text.find("星力 ******.... 6") >= 0, "enemy HUD shows star-power pips", failures)


func _check_active_master_glow(screen: Control, failures: Array[String]) -> void:
	var player_style := _panel_style(screen.player_master_panel)
	var enemy_style := _panel_style(screen.enemy_master_panel)
	_expect(player_style.border_width_left > enemy_style.border_width_left, "active player master panel has stronger border", failures)
	_expect(_color_close(player_style.border_color, screen._active_side_feedback_color(BoardModelScript.SIDE_LEFT), 0.04), "active player master border uses player action cue", failures)


func _check_active_glow_switches_after_turn(screen: Control, failures: Array[String]) -> void:
	screen._advance_turn()
	await process_frame
	_expect(screen.turn_controller.current_side == BoardModelScript.SIDE_RIGHT, "turn advances to enemy side", failures)
	var player_text := str(screen.player_hud_label.text)
	var enemy_text := str(screen.enemy_hud_label.text)
	_expect(player_text.find("我方 - 待命观星") >= 0, "player HUD becomes standby after turn advance", failures)
	_expect(enemy_text.find("敌方 - ● 当前行动") >= 0, "enemy HUD becomes active after turn advance", failures)
	var player_style := _panel_style(screen.player_master_panel)
	var enemy_style := _panel_style(screen.enemy_master_panel)
	_expect(enemy_style.border_width_left > player_style.border_width_left, "enemy master panel becomes highlighted", failures)
	_expect(_color_close(enemy_style.border_color, screen._active_side_feedback_color(BoardModelScript.SIDE_RIGHT), 0.04), "enemy active border uses enemy action cue", failures)


func _panel_style(panel: PanelContainer) -> StyleBoxFlat:
	return panel.get_theme_stylebox("panel") as StyleBoxFlat


func _color_close(actual: Color, expected: Color, tolerance: float) -> bool:
	return absf(actual.r - expected.r) <= tolerance and absf(actual.g - expected.g) <= tolerance and absf(actual.b - expected.b) <= tolerance and absf(actual.a - expected.a) <= tolerance


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
