extends SceneTree

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const HeroIdentitySimulationV1Script: GDScript = preload("res://scripts/tools/HeroIdentitySimulationV1.gd")

const EXPECTED_PLAYABLE_HERO_COUNT := 55
const SAMPLE_COUNT := 100
const REPORT_PATH := "D:/wanguxingtu/tmp/hero_identity/hero_identity_simulation_v1_100.json"
const IDENTITY_DOC := "res://docs/HERO_IDENTITY_BIBLE.md"


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()
	_check_identity_doc(failures)
	_check_identity_simulation(failures)
	if failures.is_empty():
		print("M91 hero identity checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_identity_doc(failures: Array[String]) -> void:
	var heroes := _playable_heroes()
	_expect(heroes.size() == EXPECTED_PLAYABLE_HERO_COUNT, "playable hero count is 55", failures)
	var source := FileAccess.get_file_as_string(IDENTITY_DOC)
	_expect(not source.is_empty(), "HERO_IDENTITY_BIBLE exists", failures)
	_expect(source.contains("Hero Identity Sprint v1"), "identity bible records sprint name", failures)
	_expect(source.contains("需要重新设计"), "identity bible has redesign section", failures)
	for hero: Dictionary in heroes:
		var hero_id := str(hero.get("id", ""))
		_expect(source.contains("| `%s` |" % hero_id), "identity bible covers hero %s" % hero_id, failures)


func _check_identity_simulation(failures: Array[String]) -> void:
	var report: Dictionary = HeroIdentitySimulationV1Script.run(SAMPLE_COUNT)
	var saved: bool = HeroIdentitySimulationV1Script.save_report(report, REPORT_PATH)
	_expect(saved, "hero identity report is written", failures)
	_expect(int(report.get("sample_count", 0)) == SAMPLE_COUNT, "identity simulation runs 100 samples", failures)
	_expect(int(report.get("ended_count", 0)) == SAMPLE_COUNT, "identity simulation finishes every sample", failures)
	_expect(int(report.get("timeouts", 0)) == 0, "identity simulation has no timeouts", failures)
	_expect(report.get("anomalies", []).is_empty(), "identity simulation reports no anomalies", failures)
	_expect(report.get("hero_identity_rows", []).size() == EXPECTED_PLAYABLE_HERO_COUNT, "identity report covers 55 heroes", failures)
	_expect(report.get("duplicate_skill_signature_groups", []).is_empty(), "no two heroes share the same complete skill signature", failures)
	_expect(report.get("untriggered_playable_skills", []).is_empty(), "every playable hero skill has simulation presence", failures)
	_expect(bool(report.get("hero_identity_simulation_clean", false)), "identity simulation clean sentinel is true", failures)


func _playable_heroes() -> Array:
	var result: Array = []
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if bool(hero.get("is_summon", false)) or str(hero.get("id", "")) == "yellow_turban":
			continue
		result.append(hero)
	return result


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
