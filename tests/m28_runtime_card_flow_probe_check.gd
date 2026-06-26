extends SceneTree

const M19_PATH := "res://tests/m19_pacing_trend_probe_check.gd"
const M22_PATH := "res://tests/m22_pacing_multi_sample_check.gd"
const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"


func _init() -> void:
	var failures: Array[String] = []
	var m19_source := FileAccess.get_file_as_string(M19_PATH)
	var m22_source := FileAccess.get_file_as_string(M22_PATH)
	var battle_screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	_check_probe_uses_shared_card_flow("M19", m19_source, failures)
	_check_probe_uses_shared_card_flow("M22", m22_source, failures)
	_check_battle_screen_uses_shared_card_flow(battle_screen_source, failures)
	_check_probe_outputs_card_zone_stats("M19", m19_source, failures)
	_check_probe_outputs_card_zone_stats("M22", m22_source, failures)
	await process_frame

	if failures.is_empty():
		print("M28 runtime card-flow probe checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_probe_uses_shared_card_flow(label: String, source: String, failures: Array[String]) -> void:
	_expect(source.contains("BattleDeckScript"), "%s preloads shared battle deck helper" % label, failures)
	_expect(source.contains("battle_deck.setup"), "%s initializes card flow through helper" % label, failures)
	_expect(source.contains("battle_deck.draw"), "%s draws through helper" % label, failures)
	_expect(source.contains("battle_deck.consume_from_hand"), "%s moves deployments to discard through helper" % label, failures)
	_expect(source.contains("battle_deck.has_no_deck_hand"), "%s uses helper for exhaustion", failures)
	_expect(not source.contains("func _draw_cards"), "%s does not keep private draw helper" % label, failures)
	_expect(not source.contains("func _consume_card"), "%s does not keep private consume helper" % label, failures)


func _check_battle_screen_uses_shared_card_flow(source: String, failures: Array[String]) -> void:
	_expect(source.contains("BattleDeckScript"), "BattleScreen preloads shared battle deck helper", failures)
	_expect(source.contains("var battle_deck = BattleDeckScript.new()"), "BattleScreen owns one battle deck helper instance", failures)
	_expect(source.contains("battle_deck.setup(_player_battle_hero_ids(), _enemy_battle_hero_ids(), STARTING_HAND_SIZE, RECYCLE_DISCARD_ON_EMPTY)"), "BattleScreen initializes runtime piles through helper", failures)
	_expect(source.contains("func set_screen_data"), "BattleScreen can receive configured deck data", failures)
	_expect(source.contains("battle_deck.draw(side, count)"), "BattleScreen draw wrapper delegates to helper", failures)
	_expect(source.contains("battle_deck.consume_from_hand(side, hero_id)"), "BattleScreen consume wrapper delegates to helper", failures)
	_expect(source.contains("battle_deck.has_no_deck_hand(side)"), "BattleScreen exhaustion check delegates to helper", failures)


func _check_probe_outputs_card_zone_stats(label: String, source: String, failures: Array[String]) -> void:
	for key in ["left_deck", "right_deck", "left_hand", "right_hand", "left_discard", "right_discard"]:
		_expect(source.contains("\"%s\"" % key), "%s outputs %s" % [label, key], failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
