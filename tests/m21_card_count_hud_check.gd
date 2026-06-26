extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_initial_deck_hand_status(failures)
	await _check_deploy_updates_player_hand_status(failures)
	await _check_advance_turn_draws_player_card(failures)
	await _check_enemy_auto_deploy_updates_enemy_hand_status(failures)
	await _check_reset_restores_hand_status(failures)
	await process_frame

	if failures.is_empty():
		print("M21 card count HUD checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_initial_deck_hand_status(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.player_hud_label.text.find("我方") >= 0, "initial player HUD names side", failures)
	_expect(_hud_has_hp(screen.player_hud_label.text, "30/30"), "initial player HP shown", failures)
	_expect(_hud_has_star_power(screen.player_hud_label.text, 5), "initial player star power shown", failures)
	_expect(screen.player_hud_label.text.find("牌库 3") >= 0, "initial player deck count shown", failures)
	_expect(screen.player_hud_label.text.find("手牌 3") >= 0, "initial player hand count shown", failures)
	_expect(screen.enemy_hud_label.text.find("敌方") >= 0, "initial enemy HUD names side", failures)
	_expect(_hud_has_hp(screen.enemy_hud_label.text, "30/30"), "initial enemy HP shown", failures)
	_expect(_hud_has_star_power(screen.enemy_hud_label.text, 6), "initial enemy star power shown", failures)
	_expect(screen.enemy_hud_label.text.find("牌库 3") >= 0, "initial enemy deck count shown", failures)
	_expect(screen.enemy_hud_label.text.find("手牌 3") >= 0, "initial enemy hand count shown", failures)
	screen.queue_free()


func _check_deploy_updates_player_hand_status(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(_hud_has_star_power(screen.player_hud_label.text, 5), "player deployment updates star power", failures)
	_expect(screen.player_hud_label.text.find("牌库 3") >= 0, "player deployment keeps deck count", failures)
	_expect(screen.player_hud_label.text.find("手牌 2") >= 0, "player deployment updates hand count", failures)
	_expect(screen.hero_buttons["guanyu"].disabled, "deployed player card button is disabled", failures)
	_expect(str(screen.hero_buttons["guanyu"].text).find("已出") >= 0, "deployed player card button shows spent state", failures)
	screen.queue_free()


func _check_advance_turn_draws_player_card(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._advance_turn()
	await process_frame
	_expect(_hud_has_star_power(screen.player_hud_label.text, 7), "player turn start updates star power", failures)
	_expect(screen.player_hud_label.text.find("牌库 2") >= 0, "player turn start draws one card from deck", failures)
	_expect(screen.player_hud_label.text.find("手牌 4") >= 0, "player turn start updates hand count", failures)
	_expect(not screen.hero_buttons["zhaoyun"].disabled, "drawn player card becomes selectable", failures)
	screen.queue_free()


func _check_enemy_auto_deploy_updates_enemy_hand_status(failures: Array[String]) -> void:
	var screen = await _make_screen()
	var result: Dictionary = screen._auto_deploy_enemy()
	screen._update_status("敌方自动部署测试。")
	await process_frame
	_expect(bool(result.get("ok", false)), "enemy auto deployment succeeds", failures)
	_expect(_hud_has_star_power(screen.enemy_hud_label.text, 1), "enemy deployment updates star power", failures)
	_expect(screen.enemy_hud_label.text.find("牌库 3") >= 0, "enemy deployment keeps deck count", failures)
	_expect(screen.enemy_hud_label.text.find("手牌 2") >= 0, "enemy deployment updates hand count", failures)
	screen.queue_free()


func _check_reset_restores_hand_status(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	screen._reset_debug_battle()
	await process_frame
	_expect(_hud_has_star_power(screen.player_hud_label.text, 5), "reset restores player star power", failures)
	_expect(screen.player_hud_label.text.find("牌库 3") >= 0, "reset restores player deck count", failures)
	_expect(screen.player_hud_label.text.find("手牌 3") >= 0, "reset restores player hand count", failures)
	_expect(_hud_has_star_power(screen.enemy_hud_label.text, 6), "reset restores enemy star power", failures)
	_expect(screen.enemy_hud_label.text.find("牌库 3") >= 0, "reset restores enemy deck count", failures)
	_expect(screen.enemy_hud_label.text.find("手牌 3") >= 0, "reset restores enemy hand count", failures)
	_expect(not screen.hero_buttons["guanyu"].disabled, "reset re-enables spent card button", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _hud_has_hp(hud_text: String, hp_text: String) -> bool:
	return hud_text.find("HP ") >= 0 and hud_text.find(hp_text) >= 0


func _hud_has_star_power(hud_text: String, expected_value: int) -> bool:
	return hud_text.find("星力 ") >= 0 and hud_text.find(" %d" % expected_value) >= 0


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
