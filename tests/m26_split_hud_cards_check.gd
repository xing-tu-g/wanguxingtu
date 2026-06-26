extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_split_hud_layout(failures)
	await _check_hud_updates_after_actions(failures)
	await process_frame

	if failures.is_empty():
		print("M26 split HUD card checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_split_hud_layout(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var player_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerHudPanel")
	var enemy_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyHudPanel")
	_expect(player_panel.custom_minimum_size.y >= 96.0, "player HUD card has readable height", failures)
	_expect(enemy_panel.custom_minimum_size.y >= 96.0, "enemy HUD card has readable height", failures)
	_expect(screen.player_hud_label.text.begins_with("我方 - ") and screen.player_hud_label.text.find("\nHP ") >= 0, "player HUD is a dedicated multiline card", failures)
	_expect(screen.enemy_hud_label.text.begins_with("敌方 - ") and screen.enemy_hud_label.text.find("\nHP ") >= 0, "enemy HUD is a dedicated multiline card", failures)
	_expect(screen.star_label.text == "第 1 回合｜我方行动", "turn label no longer duplicates side resource HUD", failures)
	_expect(screen.star_label.text.find("牌库") == -1, "turn label omits deck count", failures)
	_expect(screen.star_label.text.find("手牌") == -1, "turn label omits hand count", failures)
	screen.queue_free()


func _check_hud_updates_after_actions(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(_hud_has_star_power(screen.player_hud_label.text, 5), "player HUD updates star power after deploy", failures)
	_expect(screen.player_hud_label.text.find("手牌 2") >= 0, "player HUD updates hand after deploy", failures)
	screen._advance_turn()
	await process_frame
	_expect(screen.player_hud_label.text.find("牌库 2") >= 0, "player HUD updates deck after draw", failures)
	_expect(screen.player_hud_label.text.find("手牌 3") >= 0, "player HUD combines deploy and draw counts", failures)
	_expect(screen.star_label.text == "第 1 回合｜敌方行动", "turn label updates next acting side", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _hud_has_star_power(hud_text: String, expected_value: int) -> bool:
	return hud_text.find("星力 ") >= 0 and hud_text.find(" %d" % expected_value) >= 0


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
