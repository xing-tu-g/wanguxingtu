extends SceneTree

const BalanceSimulationV2Script: GDScript = preload("res://scripts/tools/BalanceSimulationV2.gd")

const SAMPLE_COUNT := 200
const OUTPUT_PATH := "D:/wanguxingtu/tmp/skill_balance/balance_simulation_v2_200.json"


func _init() -> void:
	var report: Dictionary = BalanceSimulationV2Script.run(SAMPLE_COUNT)
	var saved: bool = BalanceSimulationV2Script.save_report(report, OUTPUT_PATH)
	print("SKILL_BALANCE_SIMULATION_v2")
	print("BALANCE_SIM_SAMPLE_COUNT=%d" % int(report.get("sample_count", 0)))
	print("BALANCE_SIM_ENDED_COUNT=%d" % int(report.get("ended_count", 0)))
	print("BALANCE_SIM_TIMEOUTS=%d" % int(report.get("timeouts", 0)))
	print("BALANCE_SIM_AVERAGE_ROUNDS=%.2f" % float(report.get("average_rounds", 0.0)))
	print("BALANCE_SIM_CLASS_WIN_RATES=%s" % JSON.stringify(report.get("class", {})))
	print("BALANCE_SIM_FACTION_WIN_RATES=%s" % JSON.stringify(report.get("faction", {})))
	print("BALANCE_SIM_HERO_TOP_10=%s" % JSON.stringify(report.get("hero_top_10", [])))
	print("BALANCE_SIM_HERO_BOTTOM_10=%s" % JSON.stringify(report.get("hero_bottom_10", [])))
	print("BALANCE_SIM_ONE_SIDED_COUNT=%d" % int(report.get("one_sided_count", 0)))
	print("BALANCE_SIM_UNANSWERABLE_HEROES=%s" % JSON.stringify(report.get("unanswerable_heroes", [])))
	print("BALANCE_SIM_UNDERPOWERED_HEROES=%s" % JSON.stringify(report.get("underpowered_heroes", [])))
	print("BALANCE_SIM_ANOMALY_COUNT=%d" % report.get("anomalies", []).size())
	if not saved:
		printerr("BALANCE_SIM_REPORT_WRITE_FAILED")
		quit(1)
		return
	print("BALANCE_SIM_REPORT=%s" % OUTPUT_PATH)
	if bool(report.get("class_balance_clean", false)) and bool(report.get("hero_balance_clean", false)) and bool(report.get("battle_pace_clean", false)) and int(report.get("timeouts", 0)) == 0 and report.get("anomalies", []).is_empty():
		print("SKILL_BALANCE_SIMULATION_V2_CLEAN")
		quit(0)
		return
	printerr("SKILL_BALANCE_SIMULATION_V2_FAILED")
	quit(1)
