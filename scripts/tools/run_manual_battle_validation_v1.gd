extends SceneTree

const ManualBattleValidationV1Script: GDScript = preload("res://scripts/tools/ManualBattleValidationV1.gd")

const REPORT_PATH := "D:/wanguxingtu/tmp/manual_validation/manual_battle_validation_v1.json"
const DOC_PATH := "D:/wanguxingtu/docs/MANUAL_BATTLE_VALIDATION_2026-07-04.md"


func _init() -> void:
	var report: Dictionary = ManualBattleValidationV1Script.run()
	var saved_report: bool = ManualBattleValidationV1Script.save_report(report, REPORT_PATH)
	var saved_doc: bool = ManualBattleValidationV1Script.save_markdown(report, DOC_PATH)
	print("MANUAL_BATTLE_VALIDATION_V1")
	print("MANUAL_VALIDATION_SCENARIO_COUNT=%d" % int(report.get("scenario_count", 0)))
	print("MANUAL_VALIDATION_FOCUS_HERO_COUNT=%d" % report.get("focus_heroes", []).size())
	print("MANUAL_VALIDATION_REPORT=%s" % REPORT_PATH)
	print("MANUAL_VALIDATION_DOC=%s" % DOC_PATH)
	print("MANUAL_VALIDATION_REPORT_SAVED=%s" % str(saved_report))
	print("MANUAL_VALIDATION_DOC_SAVED=%s" % str(saved_doc))
	for hero_id in report.get("focus_heroes", []):
		var item: Dictionary = report.get("hero_summary", {}).get(str(hero_id), {})
		print("MANUAL_VALIDATION_HERO=%s passed=%d/3 avg=%.1f judgement=%s" % [
			str(item.get("hero_name", hero_id)),
			int(item.get("passed_count", 0)),
			float(item.get("average_score", 0.0)),
			str(item.get("judgement", "")),
		])
	var clean: bool = bool(report.get("manual_validation_clean", false)) and saved_report and saved_doc
	if clean:
		print("MANUAL_BATTLE_VALIDATION_V1_CLEAN")
		quit(0)
		return
	printerr("MANUAL_BATTLE_VALIDATION_V1_FAILED")
	quit(1)
