extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_initial_master_huds(failures)
	await _check_hud_updates_after_deploy_and_draw(failures)
	await _check_hud_updates_after_enemy_auto_deploy(failures)
	await process_frame

	if failures.is_empty():
		print("M26 battle HUD card checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_master_huds(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var player_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerHudPanel")
	var enemy_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyHudPanel")
	_expect(player_panel.custom_minimum_size.y >= 100.0, "player HUD lives inside left master panel", failures)
	_expect(enemy_panel.custom_minimum_size.y >= 100.0, "enemy HUD lives inside right master panel", failures)
	_expect(_hud_has_resources(screen.player_hud_label.text, "我方", "30/30", "5", "3", "3"), "player HUD shows initial resources", failures)
	_expect(_hud_has_resources(screen.enemy_hud_label.text, "敌方", "30/30", "6", "3", "3"), "enemy HUD shows initial resources", failures)
	_expect(screen.star_label.text.contains("第 1 回合") and screen.star_label.text.contains("我方行动"), "top turn label remains compact", failures)
	screen.queue_free()


func _check_hud_updates_after_deploy_and_draw(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(_hud_has_resources(screen.player_hud_label.text, "我方", "30/30", "5", "3", "2"), "player HUD updates after deployment", failures)
	screen._advance_turn()
	await process_frame
	_expect(_hud_has_resources(screen.player_hud_label.text, "我方", "30/30", "7", "2", "3"), "player HUD updates after turn draw", failures)
	screen.queue_free()


func _check_hud_updates_after_enemy_auto_deploy(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var result: Dictionary = screen._auto_deploy_enemy()
	screen._update_status("敌方 HUD 测试。")
	await process_frame
	_expect(bool(result.get("ok", false)), "enemy auto deploy succeeds for HUD check", failures)
	_expect(_hud_has_resources(screen.enemy_hud_label.text, "敌方", "30/30", "1", "3", "2"), "enemy HUD updates after auto deployment", failures)
	screen.queue_free()


func _hud_has_resources(text: String, side: String, hp: String, star_power: String, deck: String, hand: String) -> bool:
	return text.contains(side) \
		and text.contains("HP") and text.contains(hp) \
		and text.contains("星力") and text.contains(star_power) \
		and text.contains("牌库 %s" % deck) \
		and text.contains("手牌 %s" % hand)


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
