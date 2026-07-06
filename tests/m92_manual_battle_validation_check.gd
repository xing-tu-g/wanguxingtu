extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const ManualBattleValidationV1Script: GDScript = preload("res://scripts/tools/ManualBattleValidationV1.gd")

const REPORT_PATH := "D:/wanguxingtu/tmp/manual_validation/manual_battle_validation_v1.json"
const DOC_PATH := "D:/wanguxingtu/docs/MANUAL_BATTLE_VALIDATION_2026-07-04.md"


func _init() -> void:
	var failures: Array[String] = []
	await _check_manual_battle_mode(failures)
	_check_manual_validation_report(failures)
	if failures.is_empty():
		print("M92 manual battle validation checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_manual_battle_mode(failures: Array[String]) -> void:
	var screen: Control = BattleScreenScene.instantiate()
	screen.set_screen_data({
		"manual_battle_test_mode": true,
		"manual_battle_test_name": "M92 manual mode",
		"player_deck": ["zhaoyun", "huaxiong", "machao", "xusheng", "zhangfei"],
		"enemy_deck": ["caoren", "xuchu", "dianwei", "huangzhong", "yanliang"],
	})
	root.add_child(screen)
	await process_frame
	await process_frame
	_expect(screen.manual_battle_test_mode, "manual mode flag is enabled from screen data", failures)
	_expect(screen.get_node_or_null("ManualValidationPanel") != null, "manual validation panel is created only for manual mode", failures)
	var reset_button := screen.get_node_or_null("BottomHand/Controls/ResetButton") as Button
	_expect(reset_button != null and reset_button.visible, "manual mode exposes quick restart button", failures)
	_expect(screen.player_hand.size() == 5, "manual mode uses provided player deck and draws 5", failures)
	var snapshot: Dictionary = screen.get_manual_validation_snapshot()
	_expect(bool(snapshot.get("enabled", false)), "manual snapshot marks mode enabled", failures)
	_expect(str(snapshot.get("name", "")) == "M92 manual mode", "manual snapshot carries test name", failures)
	_expect(snapshot.has("turn_number") and snapshot.has("left_star_power"), "manual snapshot includes turn and star power", failures)
	_expect(snapshot.get("stats", {}).has("skill_triggers"), "manual snapshot includes skill trigger stats", failures)
	screen.queue_free()


func _check_manual_validation_report(failures: Array[String]) -> void:
	var report: Dictionary = ManualBattleValidationV1Script.run()
	var saved_report: bool = ManualBattleValidationV1Script.save_report(report, REPORT_PATH)
	var saved_doc: bool = ManualBattleValidationV1Script.save_markdown(report, DOC_PATH)
	_expect(saved_report, "manual validation report is written", failures)
	_expect(saved_doc, "manual validation doc is written", failures)
	_expect(int(report.get("scenario_count", 0)) == 15, "manual validation covers 5 heroes x 3 scenarios", failures)
	_expect(bool(report.get("manual_validation_clean", false)), "manual validation clean sentinel is true", failures)
	for hero_id in ["zhaoyun", "huaxiong", "machao", "xusheng", "zhangfei"]:
		var item: Dictionary = report.get("hero_summary", {}).get(hero_id, {})
		_expect(int(item.get("scenario_count", 0)) == 3, "manual validation covers 3 scenarios for %s" % hero_id, failures)
		_expect(str(item.get("judgement", "")).length() > 0, "manual validation records judgement for %s" % hero_id, failures)
	var doc := FileAccess.get_file_as_string("res://docs/MANUAL_BATTLE_VALIDATION_2026-07-04.md")
	_expect(doc.contains("Manual Battle Validation Sprint v1"), "manual validation doc records sprint name", failures)
	_expect(doc.contains("赵云") and doc.contains("张飞"), "manual validation doc records focus heroes", failures)
	_expect(doc.contains("ManualValidationPanel"), "manual validation doc records manual mode panel", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
