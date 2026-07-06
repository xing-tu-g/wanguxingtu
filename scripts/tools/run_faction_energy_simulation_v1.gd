extends SceneTree

const FactionEnergySimulationV1Script: GDScript = preload("res://scripts/tools/FactionEnergySimulationV1.gd")

const SAMPLE_COUNT := 100
const REPORT_PATH := "D:/wanguxingtu/tmp/faction_energy/faction_energy_simulation_v1_100.json"


func _init() -> void:
	var report: Dictionary = FactionEnergySimulationV1Script.run(SAMPLE_COUNT)
	FactionEnergySimulationV1Script.save_report(report, REPORT_PATH)
	print("FACTION_ENERGY_SIMULATION_v1")
	print("FACTION_ENERGY_SAMPLE_COUNT=%d" % int(report.get("sample_count", 0)))
	print("FACTION_ENERGY_ENDED_COUNT=%d" % int(report.get("ended_count", 0)))
	print("FACTION_ENERGY_TIMEOUTS=%d" % int(report.get("timeouts", 0)))
	print("FACTION_ENERGY_AVERAGE_ROUNDS=%.2f" % float(report.get("average_rounds", 0.0)))
	print("FACTION_ENERGY_AVERAGES=%s" % JSON.stringify(report.get("faction_energy_average", {})))
	print("FACTION_ENERGY_SOURCES=%s" % JSON.stringify(report.get("faction_energy_source_distribution", {})))
	print("FACTION_ENERGY_TOTAL=%s" % JSON.stringify(report.get("faction_energy_total", {})))
	print("FACTION_ENERGY_CLASS_WIN_RATES=%s" % JSON.stringify(report.get("class", {})))
	print("FACTION_ENERGY_HERO_LIMIT_CLEAN=%s" % str(bool(report.get("faction_energy_hero_limit_clean", false))))
	print("FACTION_ENERGY_DOMINANCE_CLEAN=%s" % str(bool(report.get("faction_energy_dominance_clean", false))))
	print("FACTION_ENERGY_INFINITE_LOOP_CLEAN=%s" % str(bool(report.get("infinite_energy_loop_clean", false))))
	print("FACTION_ENERGY_CLASS_BALANCE_CLEAN=%s" % str(bool(report.get("class_balance_clean", false))))
	print("FACTION_ENERGY_REPORT=%s" % REPORT_PATH)
	if bool(report.get("faction_energy_simulation_clean", false)):
		print("FACTION_ENERGY_SIMULATION_V1_CLEAN")
		quit(0)
		return
	printerr("FACTION_ENERGY_SIMULATION_V1_FAILED")
	quit(1)
