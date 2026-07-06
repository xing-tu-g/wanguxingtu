extends SceneTree

const MainMenuScene: PackedScene = preload("res://scenes/ui/MainMenuScene.tscn")
const DeckBuilderScene: PackedScene = preload("res://scenes/ui/DeckBuilderScene.tscn")
const HeroCodexScene: PackedScene = preload("res://scenes/ui/HeroCodexScene.tscn")
const BattleReportScene: PackedScene = preload("res://scenes/ui/BattleReportScene.tscn")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BootScene: PackedScene = preload("res://scenes/boot/Boot.tscn")

const DeckDataManagerScript: GDScript = preload("res://scripts/data/DeckDataManager.gd")
const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const BattleReportManagerScript: GDScript = preload("res://scripts/data/BattleReportManager.gd")


func _init() -> void:
	var failures: Array[String] = []
	_check_boot_starts_main_menu(failures)
	await _check_main_menu_routes(failures)
	await _check_deck_builder(failures)
	await _check_hero_codex(failures)
	await _check_battle_to_report_payload(failures)
	await _check_report_screen(failures)

	if failures.is_empty():
		print("M95 game loop construction checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_boot_starts_main_menu(failures: Array[String]) -> void:
	var boot := BootScene.instantiate()
	_expect(str(boot.initial_screen) == "res://scenes/ui/MainMenuScene.tscn", "boot initial screen is MainMenuScene", failures)
	boot.queue_free()


func _check_main_menu_routes(failures: Array[String]) -> void:
	var screen: Control = MainMenuScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.has_node("LogoArea/ButtonColumn/BattleButton"), "main menu has start battle button", failures)
	_expect(screen.has_node("LogoArea/ButtonColumn/DeckBuilderButton"), "main menu has deck builder button", failures)
	_expect(screen.has_node("LogoArea/ButtonColumn/HeroCodexButton"), "main menu has hero codex button", failures)
	_expect(screen.has_node("LogoArea/ButtonColumn/ResultButton"), "main menu has battle report button", failures)
	_expect(screen.BATTLE_SCREEN == "res://scenes/ui/BattleScreen.tscn", "main menu battle route points to BattleScreen", failures)
	_expect(screen.DECK_SCREEN == "res://scenes/ui/DeckBuilderScene.tscn", "main menu deck route points to DeckBuilderScene", failures)
	_expect(screen.CODEX_SCREEN == "res://scenes/ui/HeroCodexScene.tscn", "main menu codex route points to HeroCodexScene", failures)
	_expect(screen.REPORT_SCREEN == "res://scenes/ui/BattleReportScene.tscn", "main menu report route points to BattleReportScene", failures)
	_expect(screen.get_node("LogoArea/ButtonColumn/BattleButton").text == "开始战斗", "main menu uses readable Chinese labels", failures)
	screen.queue_free()


func _check_deck_builder(failures: Array[String]) -> void:
	var screen: Control = DeckBuilderScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.player_deck.size() == DeckDataManagerScript.MAX_BATTLE_DECK_SIZE, "deck builder loads a 20-card battle deck", failures)
	_expect(screen.has_node("DeckMargin/DeckLayout/DeckFilterRow"), "deck builder has faction/class filter row", failures)
	_expect(screen.has_node("DeckMargin/DeckLayout/DeckFooter/StartBattleButton"), "deck builder can enter battle", failures)
	_expect(screen._grid.get_child_count() >= 55, "deck builder lists all playable heroes before filters", failures)
	_expect(screen._count_label.text.contains("当前卡组"), "deck builder summary is readable", failures)
	screen._apply_filter("faction", "shu")
	await process_frame
	_expect(screen._grid.get_child_count() > 0 and screen._grid.get_child_count() < 55, "deck builder faction filter changes hero list", failures)
	screen.queue_free()


func _check_hero_codex(failures: Array[String]) -> void:
	var screen: Control = HeroCodexScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen._grid.get_child_count() == HeroDataLoaderScript.all_hero_ids(false).size(), "hero codex shows all 55 playable heroes", failures)
	_expect(screen._detail.text.contains("一句话定位"), "hero codex detail shows hero identity positioning", failures)
	_expect(screen._detail.text.contains("技能"), "hero codex detail shows skills", failures)
	screen._apply_filter("class", "mage")
	await process_frame
	_expect(screen._grid.get_child_count() > 0 and screen._grid.get_child_count() < 55, "hero codex class filter changes list", failures)
	screen.queue_free()


func _check_battle_to_report_payload(failures: Array[String]) -> void:
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var deck: Array = DeckDataManagerScript.default_player_deck()
	screen.set_screen_data({"player_deck": deck})
	_expect(screen.configured_player_deck.size() == 20, "BattleScreen accepts configured deck data", failures)
	screen._add_battle_log("测试", "事件", "战报回放记录")
	screen.battle_state.master_hp["right"] = 0
	var result: Dictionary = screen._check_battle_end()
	result["battle_log"] = screen.battle_log_entries.duplicate()
	var report: Dictionary = BattleReportManagerScript.build_report(result)
	_expect(report.get("outcome", "") == "left_wins", "battle result converts to report outcome", failures)
	_expect(report.get("battle_log", []).size() > 0, "battle report receives battle log payload", failures)
	screen.queue_free()


func _check_report_screen(failures: Array[String]) -> void:
	var screen: Control = BattleReportScene.instantiate()
	screen.set_screen_data({
		"outcome": "left_wins",
		"round_number": 6,
		"left_hp": 12,
		"right_hp": 0,
		"stats": {
			"skill_triggers": {"guanyu": 2},
			"hero_damage_dealt": {"guanyu": 10},
			"units_defeated": {"left": 3, "right": 1},
			"faction_energy_heroes": {"guanyu": 1},
			"unit_damage_dealt": {"left": 10, "right": 4},
			"master_damage_dealt": {"left": 8, "right": 0},
		},
		"battle_log": ["R1 - 关羽 - 部署 - 测试"],
	})
	root.add_child(screen)
	await process_frame
	_expect(screen._title.text.contains("战报"), "battle report screen renders title", failures)
	_expect(screen._summary.text.contains("MVP:"), "battle report screen renders MVP", failures)
	_expect(screen._summary.text.contains("星力来源"), "battle report screen renders star source stats", failures)
	_expect(screen._summary.text.contains("战斗日志回放"), "battle report screen renders replay log", failures)
	screen.queue_free()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
