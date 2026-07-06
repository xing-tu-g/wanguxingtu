extends SceneTree

const BattleReportScene: PackedScene = preload("res://scenes/ui/BattleReportScene.tscn")
const BattleReportManagerScript: GDScript = preload("res://scripts/data/BattleReportManager.gd")


func _init() -> void:
	var failures: Array[String] = []
	_check_report_manager_localizes_skill_ids(failures)
	await _check_report_screen_presentation(failures)

	if failures.is_empty():
		print("M97 battle report presentation checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_report_manager_localizes_skill_ids(failures: Array[String]) -> void:
	var report: Dictionary = BattleReportManagerScript.build_report(_sample_payload())
	_expect(str(report.get("mvp", "")) == "zhouyu", "MVP maps skill trigger ids back to owner hero", failures)
	_expect(str(report.get("skill_trigger_lines", [])).contains("周瑜·赤壁灼烧"), "skill trigger lines use localized skill names", failures)
	_expect(not str(report.get("skill_trigger_lines", [])).contains("zhouyu_burn"), "skill trigger lines hide raw skill ids", failures)
	_expect(str(report.get("hero_contributions", [])).contains("周瑜"), "hero contribution lines use hero names", failures)


func _check_report_screen_presentation(failures: Array[String]) -> void:
	var screen: Control = BattleReportScene.instantiate()
	screen.set_screen_data(_sample_payload())
	root.add_child(screen)
	await process_frame
	var text := str(screen._summary.text)
	_expect(text.contains("星轨:"), "legacy report summary includes star track result", failures)
	_expect(text.contains("[b]战斗结果[/b]"), "report has result layer", failures)
	_expect(text.contains("[b]阵营表现[/b]"), "report has faction performance layer", failures)
	_expect(text.contains("[b]英雄表现[/b]"), "report has hero performance layer", failures)
	_expect(text.contains("周瑜·赤壁灼烧"), "screen localizes zhouyu skill id", failures)
	_expect(text.contains("孙权·制衡令"), "screen localizes sunquan skill id", failures)
	_expect(not text.contains("zhouyu_burn"), "screen hides zhouyu raw skill id", failures)
	_expect(not text.contains("sunquan_command"), "screen hides sunquan raw skill id", failures)
	_expect(not text.contains("："), "screen avoids full-width colon separators", failures)
	_expect(not text.contains("□"), "screen avoids missing-glyph separator boxes", failures)
	_expect(text.contains(": ") and text.contains(" - "), "screen uses compatible ASCII separators", failures)
	_expect(screen.has_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/SummaryCard"), "report renders Summary Card", failures)
	_expect(screen.has_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/FactionCard"), "report renders Faction Card", failures)
	_expect(screen.has_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/HeroCardList"), "report renders Hero Card List", failures)
	_expect(screen.has_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/SummaryCard/CardMargin/CardBody/SummaryTopRow/MvpHighlight"), "Summary Card highlights MVP", failures)
	_expect(screen.has_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/SummaryCard/CardMargin/CardBody/SummaryTopRow/OutcomeBlock/StarTrackResult"), "Summary Card shows star track result", failures)
	var star_track_label: Label = screen.get_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/SummaryCard/CardMargin/CardBody/SummaryTopRow/OutcomeBlock/StarTrackResult")
	_expect(star_track_label.text.contains("星轨:"), "star track label is readable", failures)
	_expect(screen.has_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/HeroCardList/CardMargin/CardBody/HeroRow_zhouyu"), "Hero Card List includes MVP hero row", failures)
	var hero_list: VBoxContainer = screen.get_node("BattleReportMargin/BattleReportLayout/BattleReportPanel/BattleReportScroll/BattleReportCards/HeroCardList/CardMargin/CardBody")
	_expect(hero_list.get_child_count() >= 2 and hero_list.get_child(1).name == "HeroRow_zhouyu", "MVP hero row is first contribution row", failures)
	_expect(not screen._summary.visible, "legacy text summary is hidden from visual UI", failures)
	screen.queue_free()


func _sample_payload() -> Dictionary:
	return {
		"outcome": "left_wins",
		"round_number": 8,
		"left_hp": 16,
		"right_hp": 0,
		"stats": {
			"skill_triggers": {"zhouyu_burn": 6, "sunquan_command": 1},
			"hero_damage_dealt": {"zhouyu": 8, "sunquan": 2},
			"hero_damage_taken": {"zhouyu": 3, "sunquan": 1},
			"hero_healing_done": {"sunquan": 1},
			"units_defeated": {"left": 3, "right": 1},
			"faction_energy_heroes": {"sunquan": 2},
			"unit_damage_dealt": {"left": 12, "right": 4},
			"master_damage_dealt": {"left": 8, "right": 0},
		},
		"battle_log": [
			"R8 - zhouyu - 技能 - zhouyu_burn：造成伤害",
			"R8 - sunquan - 技能 - sunquan_command：触发",
		],
	}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
