extends SceneTree

const HeroIdentitySimulationV1Script: GDScript = preload("res://scripts/tools/HeroIdentitySimulationV1.gd")

const SAMPLE_COUNT := 100
const REPORT_PATH := "D:/wanguxingtu/tmp/hero_identity/hero_identity_simulation_v1_100.json"


func _init() -> void:
	var report: Dictionary = HeroIdentitySimulationV1Script.run(SAMPLE_COUNT)
	HeroIdentitySimulationV1Script.save_report(report, REPORT_PATH)
	print("HERO_IDENTITY_SIMULATION_V1")
	print("HERO_IDENTITY_SAMPLE_COUNT=%d" % int(report.get("sample_count", 0)))
	print("HERO_IDENTITY_ENDED_COUNT=%d" % int(report.get("ended_count", 0)))
	print("HERO_IDENTITY_TIMEOUTS=%d" % int(report.get("timeouts", 0)))
	print("HERO_IDENTITY_DUPLICATE_SIGNATURE_GROUPS=%d" % report.get("duplicate_skill_signature_groups", []).size())
	print("HERO_IDENTITY_UNTRIGGERED_SKILLS=%d" % report.get("untriggered_playable_skills", []).size())
	print("HERO_IDENTITY_LOW_PRESENCE=%s" % JSON.stringify(report.get("low_presence_heroes", [])))
	print("HERO_IDENTITY_HIGH_PRESENCE=%s" % JSON.stringify(report.get("high_presence_heroes", [])))
	print("HERO_IDENTITY_REPORT=%s" % REPORT_PATH)
	if bool(report.get("hero_identity_simulation_clean", false)):
		print("HERO_IDENTITY_SIMULATION_V1_CLEAN")
		quit(0)
		return
	printerr("HERO_IDENTITY_SIMULATION_V1_FAILED")
	quit(1)
