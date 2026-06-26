extends SceneTree

const M19_PATH := "res://tests/m19_pacing_trend_probe_check.gd"
const M22_PATH := "res://tests/m22_pacing_multi_sample_check.gd"
const M23_PATH := "res://tests/m23_left_right_symmetry_check.gd"
const EXPECTED_POOL_LITERAL := "[\"guanyu\", \"zhaoyun\", \"sunshangxiang\", \"zhangfei\", \"zhouyu\", \"zhangjiao\"]"


func _init() -> void:
	var failures: Array[String] = []
	var m19_source := FileAccess.get_file_as_string(M19_PATH)
	var m22_source := FileAccess.get_file_as_string(M22_PATH)
	var m23_source := FileAccess.get_file_as_string(M23_PATH)
	_check_m19_uses_explicit_symmetric_pool(m19_source, failures)
	_check_m22_uses_same_pool_for_both_sides(m22_source, failures)
	_check_m23_locks_pool_consistency(m23_source, failures)
	await process_frame

	if failures.is_empty():
		print("M24 symmetric pacing probe checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_m19_uses_explicit_symmetric_pool(source: String, failures: Array[String]) -> void:
	_expect(source.contains("const AUTO_HERO_IDS := %s" % EXPECTED_POOL_LITERAL), "M19 declares one shared auto hero pool", failures)
	_expect(source.contains("BattleDeckScript"), "M19 uses shared battle deck helper", failures)
	_expect(source.contains("battle_deck.setup(AUTO_HERO_IDS, AUTO_HERO_IDS, STARTING_HAND_SIZE)"), "M19 initializes both sides through helper", failures)
	_expect(source.contains("battle_deck.draw(BoardModelScript.SIDE_LEFT, DRAW_PER_SIDE_TURN)"), "M19 draws left side through helper", failures)
	_expect(source.contains("battle_deck.consume_from_hand(BoardModelScript.SIDE_RIGHT"), "M19 consumes right deployments through helper", failures)
	_expect(source.contains("CHECKPOINT_ROUND"), "M19 uses a mid-battle checkpoint instead of stale round-20 assumption", failures)
	_expect(source.contains("post_checkpoint_delta"), "M19 reports post-checkpoint trend delta", failures)
	_expect(not source.contains("func _draw_cards"), "M19 no longer owns private draw helper", failures)
	_expect(not source.contains("func _consume_card"), "M19 no longer owns private consume helper", failures)
	_expect(not source.contains("round_20"), "M19 no longer requires old round-20 snapshot after M23 symmetry fix", failures)
	_expect(not source.contains("BattleScreenScene"), "M19 no longer reads BattleScreen enemy UI constants", failures)
	_expect(not source.contains("ENEMY_AUTO_HERO_IDS"), "M19 no longer depends on old enemy auto pool order", failures)


func _check_m22_uses_same_pool_for_both_sides(source: String, failures: Array[String]) -> void:
	_expect(source.contains("const HERO_IDS := %s" % EXPECTED_POOL_LITERAL), "M22 declares expected MVP hero pool", failures)
	_expect(source.contains("const ENEMY_DEFAULT_IDS := HERO_IDS"), "M22 enemy pool reuses player pool order", failures)


func _check_m23_locks_pool_consistency(source: String, failures: Array[String]) -> void:
	_expect(source.contains("_check_m22_hero_pools_are_consistent"), "M23 keeps M22 pool consistency regression", failures)
	_expect(source.contains("const ENEMY_DEFAULT_IDS := HERO_IDS"), "M23 expects M22 enemy pool to reuse HERO_IDS", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
