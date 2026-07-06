extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleUIThemeScript: GDScript = preload("res://scripts/ui/theme/BattleUITheme.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_master_hud_meters(screen, failures)
	_check_active_master_glow(screen, failures)
	await _check_active_glow_switches_after_turn(screen, failures)
	await process_frame

	screen.queue_free()
	await process_frame
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
	_expect(player_text.contains("HP 30/30"), "player HUD shows HP", failures)
	_expect(enemy_text.contains("HP 30/30"), "enemy HUD shows HP", failures)
	_expect(player_text.contains("牌库") and player_text.contains("手牌"), "player HUD shows deck and hand counts", failures)
	_expect(enemy_text.contains("牌库") and enemy_text.contains("手牌"), "enemy HUD shows deck and hand counts", failures)
	_expect(screen.player_star_label.text.begins_with("星力 "), "player star power is shown in compact row", failures)
	_expect(screen.enemy_star_label.text.begins_with("星力 "), "enemy star power is shown in compact row", failures)
	_expect(not player_text.contains("当前行动") and not enemy_text.contains("待命"), "master HUD avoids verbose turn-state copy", failures)


func _check_active_master_glow(screen: Control, failures: Array[String]) -> void:
	var player_style := _panel_style(screen.player_master_panel)
	var enemy_style := _panel_style(screen.enemy_master_panel)
	_expect(player_style.border_width_left > enemy_style.border_width_left, "active player master panel has stronger border", failures)
	_expect(_color_close(player_style.border_color, BattleUIThemeScript.PLAYER_BORDER, 0.04), "active player master border uses player action cue", failures)


func _check_active_glow_switches_after_turn(screen: Control, failures: Array[String]) -> void:
	screen._advance_turn()
	await process_frame
	_expect(screen.turn_controller.current_side == BoardModelScript.SIDE_RIGHT, "turn advances to enemy side", failures)
	var player_style := _panel_style(screen.player_master_panel)
	var enemy_style := _panel_style(screen.enemy_master_panel)
	_expect(enemy_style.border_width_left > player_style.border_width_left, "enemy master panel becomes highlighted", failures)
	_expect(_color_close(enemy_style.border_color, BattleUIThemeScript.ENEMY_BORDER, 0.04), "enemy active border uses enemy action cue", failures)


func _panel_style(panel: PanelContainer) -> StyleBoxFlat:
	return panel.get_theme_stylebox("panel") as StyleBoxFlat


func _color_close(actual: Color, expected: Color, tolerance: float) -> bool:
	return absf(actual.r - expected.r) <= tolerance and absf(actual.g - expected.g) <= tolerance and absf(actual.b - expected.b) <= tolerance and absf(actual.a - expected.a) <= tolerance


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
