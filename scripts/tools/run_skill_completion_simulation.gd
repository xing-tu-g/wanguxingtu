extends SceneTree

const SkillCompletionSimulatorScript: GDScript = preload("res://scripts/tools/SkillCompletionSimulator.gd")

const OUTPUT_PATH := "D:/wanguxingtu/tmp/skill_completion/simulation_100.json"


func _init() -> void:
	var report: Dictionary = SkillCompletionSimulatorScript.run(100)
	var saved: bool = SkillCompletionSimulatorScript.save_report(report, OUTPUT_PATH)
	print("SKILL_SIM_SAMPLE_COUNT=%d" % int(report.get("sample_count", 0)))
	print("SKILL_SIM_ENDED_COUNT=%d" % int(report.get("ended_count", 0)))
	print("SKILL_SIM_TIMEOUTS=%d" % int(report.get("timeouts", 0)))
	print("SKILL_SIM_LEFT_WINS=%d" % int(report.get("left_wins", 0)))
	print("SKILL_SIM_RIGHT_WINS=%d" % int(report.get("right_wins", 0)))
	print("SKILL_SIM_TOP_DAMAGE=%s" % JSON.stringify(report.get("top_damage_hero", {})))
	print("SKILL_SIM_TOP_HEALING=%s" % JSON.stringify(report.get("top_healing_hero", {})))
	print("SKILL_SIM_TOP_TANK=%s" % JSON.stringify(report.get("top_tank_hero", {})))
	print("SKILL_SIM_ANOMALY_COUNT=%d" % report.get("anomalies", []).size())
	if saved:
		print("SKILL_SIM_REPORT=%s" % OUTPUT_PATH)
		print("SKILL_COMPLETION_SIMULATION_CLEAN")
		quit(0)
		return
	printerr("SKILL_SIM_REPORT_WRITE_FAILED")
	quit(1)
