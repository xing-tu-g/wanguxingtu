extends SceneTree

const BootScene: PackedScene = preload("res://scenes/boot/Boot.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var boot: Control = BootScene.instantiate()
	root.add_child(boot)
	await _wait_transition()

	_expect(_screen_name(boot) == "MainMenuScene", "boot enters MainMenuScene", failures)
	await _open_deck_builder_and_return(boot, failures)
	await _open_codex_and_return(boot, failures)
	await _open_battle_report_history_and_return(boot, failures)
	await _open_battle_and_route_to_report(boot, failures)

	boot.queue_free()
	if failures.is_empty():
		print("M96 game loop router playthrough checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _open_deck_builder_and_return(boot: Control, failures: Array[String]) -> void:
	_press(boot.current_screen.get_node("LogoArea/ButtonColumn/DeckBuilderButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "DeckBuilderScene", "main menu opens DeckBuilderScene", failures)
	_expect(boot.current_screen.player_deck.size() == 20, "deck builder receives a 20-card deck", failures)
	_press(boot.current_screen.get_node("DeckMargin/DeckLayout/DeckHeader/BackButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "MainMenuScene", "deck builder returns to MainMenuScene", failures)


func _open_codex_and_return(boot: Control, failures: Array[String]) -> void:
	_press(boot.current_screen.get_node("LogoArea/ButtonColumn/HeroCodexButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "HeroCodexScene", "main menu opens HeroCodexScene", failures)
	_expect(boot.current_screen._grid.get_child_count() == 55, "hero codex lists 55 playable heroes", failures)
	_press(boot.current_screen.get_node("CodexMargin/CodexLayout/CodexHeader/BackButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "MainMenuScene", "hero codex returns to MainMenuScene", failures)


func _open_battle_report_history_and_return(boot: Control, failures: Array[String]) -> void:
	_press(boot.current_screen.get_node("LogoArea/ButtonColumn/ResultButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "BattleReportScene", "main menu opens BattleReportScene", failures)
	_expect(boot.current_screen._title.text.contains("战报") or boot.current_screen._title.text.contains("暂无"), "battle report history renders a report title", failures)
	_press(boot.current_screen.get_node("BattleReportMargin/BattleReportLayout/BattleReportHeader/HomeButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "MainMenuScene", "battle report returns to MainMenuScene", failures)


func _open_battle_and_route_to_report(boot: Control, failures: Array[String]) -> void:
	_press(boot.current_screen.get_node("LogoArea/ButtonColumn/BattleButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "BattleScreen", "main menu opens BattleScreen", failures)
	var battle_screen: Control = boot.current_screen
	_expect(battle_screen.configured_player_deck.size() >= 5, "battle receives configured player deck", failures)
	battle_screen._add_battle_log("测试", "事件", "路由战报回放")
	battle_screen._route_to_result({
		"outcome": "left_wins",
		"round_number": 3,
		"left_hp": 20,
		"right_hp": 0,
		"stats": {
			"skill_triggers": {"guanyu": 1},
			"hero_damage_dealt": {"guanyu": 8},
			"faction_energy_heroes": {"guanyu": 1},
			"unit_damage_dealt": {"left": 8, "right": 0},
			"master_damage_dealt": {"left": 6, "right": 0},
			"units_defeated": {"left": 1, "right": 0},
		},
	})
	await _wait_transition()
	_expect(_screen_name(boot) == "BattleReportScene", "BattleScreen routes result payload to BattleReportScene", failures)
	_expect(boot.current_screen._summary.text.contains("战斗日志回放"), "battle report renders replay log after battle", failures)
	_press(boot.current_screen.get_node("BattleReportMargin/BattleReportLayout/BattleReportHeader/HomeButton"))
	await _wait_transition()
	_expect(_screen_name(boot) == "MainMenuScene", "post-battle report returns to MainMenuScene", failures)


func _press(node: Node) -> void:
	var button := node as Button
	if button != null:
		button.pressed.emit()


func _screen_name(boot: Control) -> String:
	if boot.current_screen == null:
		return ""
	return String(boot.current_screen.name)


func _wait_transition() -> void:
	await process_frame
	await create_timer(0.38).timeout
	await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
