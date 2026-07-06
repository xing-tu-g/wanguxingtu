extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const BattleDeckScript: GDScript = preload("res://scripts/battle/BattleDeck.gd")

const HERO_IDS := ["guanyu", "zhaoyun", "sunshangxiang", "zhangfei", "zhouyu", "zhangjiao"]
const ENEMY_DEFAULT_IDS := HERO_IDS
const MAX_SIDE_TURNS := 80
const TERRAIN_SEEDS := [1, 2, 3]
const POLICIES := ["fixed", "rotating"]
const STARTING_HAND_SIZE := 3
const DRAW_PER_SIDE_TURN := 1


func _init() -> void:
	var failures: Array[String] = []
	var samples := _run_samples()
	var summary := _summarize_samples(samples)
	_check_sample_shape(samples, summary, failures)
	_print_summary(samples, summary)
	await process_frame

	if failures.is_empty():
		print("M22 pacing multi-sample checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _run_samples() -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	for first_side in [BoardModelScript.SIDE_LEFT, BoardModelScript.SIDE_RIGHT]:
		for seed_value in TERRAIN_SEEDS:
			for player_policy in POLICIES:
				for enemy_policy in POLICIES:
					samples.append(_run_auto_play_sample(first_side, seed_value, player_policy, enemy_policy))
	return samples


func _run_auto_play_sample(first_side: String, seed_value: int, player_policy: String, enemy_policy: String) -> Dictionary:
	var state = BattleStateScript.new()
	state.terrain_system.generate_deterministic(seed_value)
	var turns = TurnControllerScript.new(state, first_side)
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(HERO_IDS, ENEMY_DEFAULT_IDS, STARTING_HAND_SIZE)
	var player_next_index := 0
	var enemy_next_index := 0
	var side_turns_taken := 0
	var result := {}
	while side_turns_taken < MAX_SIDE_TURNS:
		var acting_side: String = turns.current_side
		turns.start_side_turn()
		if acting_side == BoardModelScript.SIDE_LEFT:
			battle_deck.draw(BoardModelScript.SIDE_LEFT, DRAW_PER_SIDE_TURN)
			var player_deploy: Dictionary = _auto_deploy_from_hand(state, BoardModelScript.SIDE_LEFT, battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT), player_next_index, player_policy)
			if bool(player_deploy.get("ok", false)):
				battle_deck.consume_from_hand(BoardModelScript.SIDE_LEFT, str(player_deploy.get("hero_id", "")))
				player_next_index += 1
		else:
			battle_deck.draw(BoardModelScript.SIDE_RIGHT, DRAW_PER_SIDE_TURN)
			var enemy_deploy: Dictionary = _auto_deploy_from_hand(state, BoardModelScript.SIDE_RIGHT, battle_deck.hand_for_side(BoardModelScript.SIDE_RIGHT), enemy_next_index, enemy_policy)
			if bool(enemy_deploy.get("ok", false)):
				battle_deck.consume_from_hand(BoardModelScript.SIDE_RIGHT, str(enemy_deploy.get("hero_id", "")))
				enemy_next_index += 1
		turns.act_current_side()
		turns.end_side_turn()
		side_turns_taken += 1
		result = _battle_result(state, turns, battle_deck)
		if not result.is_empty():
			break

	var stats: Dictionary = state.battle_stats.snapshot()
	var card_snapshot: Dictionary = battle_deck.snapshot()
	return {
		"first_side": first_side,
		"seed": seed_value,
		"player_policy": player_policy,
		"enemy_policy": enemy_policy,
		"ended": not result.is_empty(),
		"outcome": str(result.get("outcome", "timeout")),
		"round_number": turns.turn_number,
		"side_turns": side_turns_taken,
		"left_hp": state.get_master_hp(BoardModelScript.SIDE_LEFT),
		"right_hp": state.get_master_hp(BoardModelScript.SIDE_RIGHT),
		"left_units": state.get_units_by_side(BoardModelScript.SIDE_LEFT).size(),
		"right_units": state.get_units_by_side(BoardModelScript.SIDE_RIGHT).size(),
		"left_deck": int(card_snapshot.get("left_deck", 0)),
		"right_deck": int(card_snapshot.get("right_deck", 0)),
		"left_hand": int(card_snapshot.get("left_hand", 0)),
		"right_hand": int(card_snapshot.get("right_hand", 0)),
		"left_discard": int(card_snapshot.get("left_discard", 0)),
		"right_discard": int(card_snapshot.get("right_discard", 0)),
		"deployments_left": _stat_value(stats, "deployments", BoardModelScript.SIDE_LEFT),
		"deployments_right": _stat_value(stats, "deployments", BoardModelScript.SIDE_RIGHT),
		"defeats_left": _stat_value(stats, "units_defeated", BoardModelScript.SIDE_LEFT),
		"defeats_right": _stat_value(stats, "units_defeated", BoardModelScript.SIDE_RIGHT),
		"unit_damage_left": _stat_value(stats, "unit_damage_dealt", BoardModelScript.SIDE_LEFT),
		"unit_damage_right": _stat_value(stats, "unit_damage_dealt", BoardModelScript.SIDE_RIGHT),
		"master_damage_left": _stat_value(stats, "master_damage_dealt", BoardModelScript.SIDE_LEFT),
		"master_damage_right": _stat_value(stats, "master_damage_dealt", BoardModelScript.SIDE_RIGHT),
	}



func _auto_deploy_from_hand(state, side: String, hand: Array, start_index: int, policy: String) -> Dictionary:
	if hand.is_empty():
		return {"ok": false, "reason": "empty_hand"}
	var ordered_hand := hand.duplicate()
	if policy == "rotating":
		ordered_hand.clear()
		for offset in range(hand.size()):
			ordered_hand.append(hand[(start_index + offset) % hand.size()])
	for hero_id_value in ordered_hand:
		var hero_id := str(hero_id_value)
		if not state.can_afford(side, hero_id):
			continue
		for column in _deployment_columns(side):
			for row in range(1, BoardModelScript.ROWS + 1):
				if not state.board.can_deploy(side, column, row):
					continue
				var deploy_result: Dictionary = state.deploy_hero(hero_id, side, column, row)
				if bool(deploy_result.get("ok", false)):
					deploy_result["hero_id"] = hero_id
					return deploy_result
	return {"ok": false, "reason": "no_affordable_deploy_cell"}


func _deployment_columns(side: String) -> Array[int]:
	if side == BoardModelScript.SIDE_RIGHT:
		return [8, 9, 10]
	return [3, 2, 1]


func _battle_result(state, turns, battle_deck) -> Dictionary:
	var left_hp: int = state.get_master_hp(BoardModelScript.SIDE_LEFT)
	var right_hp: int = state.get_master_hp(BoardModelScript.SIDE_RIGHT)
	var left_units: int = state.get_units_by_side(BoardModelScript.SIDE_LEFT).size()
	var right_units: int = state.get_units_by_side(BoardModelScript.SIDE_RIGHT).size()
	var left_defeated: bool = left_hp <= 0 or battle_deck.has_no_deck_hand_or_units(BoardModelScript.SIDE_LEFT, left_units)
	var right_defeated: bool = right_hp <= 0 or battle_deck.has_no_deck_hand_or_units(BoardModelScript.SIDE_RIGHT, right_units)
	if not left_defeated and not right_defeated:
		return {}
	var outcome := ""
	if left_defeated and right_defeated:
		outcome = "both_failed"
	elif right_defeated:
		outcome = "left_wins"
	else:
		outcome = "right_wins"
	return {
		"outcome": outcome,
		"round_number": turns.turn_number,
		"left_hp": left_hp,
		"right_hp": right_hp,
	}


func _summarize_samples(samples: Array[Dictionary]) -> Dictionary:
	var summary := {
		"sample_count": samples.size(),
		"ended_count": 0,
		"left_wins": 0,
		"right_wins": 0,
		"both_failed": 0,
		"timeouts": 0,
		"round_total": 0,
		"first_left_left_wins": 0,
		"first_left_count": 0,
		"first_right_left_wins": 0,
		"first_right_count": 0,
		"symmetric_policy_count": 0,
		"asymmetric_policy_count": 0,
		"samples_with_discards": 0,
	}
	for sample: Dictionary in samples:
		if bool(sample.get("ended", false)):
			summary["ended_count"] += 1
		else:
			summary["timeouts"] += 1
		summary["round_total"] += int(sample.get("round_number", 0))
		if int(sample.get("left_discard", 0)) > 0 or int(sample.get("right_discard", 0)) > 0:
			summary["samples_with_discards"] += 1
		match str(sample.get("outcome", "")):
			"left_wins":
				summary["left_wins"] += 1
			"right_wins":
				summary["right_wins"] += 1
			"both_failed":
				summary["both_failed"] += 1
		if str(sample.get("first_side", "")) == BoardModelScript.SIDE_LEFT:
			summary["first_left_count"] += 1
			if str(sample.get("outcome", "")) == "left_wins":
				summary["first_left_left_wins"] += 1
		else:
			summary["first_right_count"] += 1
			if str(sample.get("outcome", "")) == "left_wins":
				summary["first_right_left_wins"] += 1
		if str(sample.get("player_policy", "")) == str(sample.get("enemy_policy", "")):
			summary["symmetric_policy_count"] += 1
		else:
			summary["asymmetric_policy_count"] += 1
	if samples.size() > 0:
		summary["average_round"] = float(summary["round_total"]) / float(samples.size())
	return summary


func _check_sample_shape(samples: Array[Dictionary], summary: Dictionary, failures: Array[String]) -> void:
	_expect(samples.size() == 24, "multi-sample probe covers first side, terrain seeds, and policies", failures)
	_expect(int(summary.get("ended_count", 0)) >= 20, "most pacing samples end before side-turn cap", failures)
	_expect(float(summary.get("average_round", 0.0)) >= 4.0, "average battle lasts at least four rounds", failures)
	_expect(float(summary.get("average_round", 0.0)) <= 60.0, "average battle remains bounded after shuffled hands", failures)
	_expect(int(summary.get("first_left_count", 0)) == 12, "half samples use left first", failures)
	_expect(int(summary.get("first_right_count", 0)) == 12, "half samples use right first", failures)
	_expect(int(summary.get("symmetric_policy_count", 0)) == 12, "half samples use symmetric deployment policies", failures)
	_expect(int(summary.get("asymmetric_policy_count", 0)) == 12, "half samples use asymmetric deployment policies", failures)
	_expect(int(summary.get("samples_with_discards", 0)) == samples.size(), "all samples exercise discard tracking", failures)


func _print_summary(samples: Array[Dictionary], summary: Dictionary) -> void:
	print("M22 pacing multi-sample summary: %s" % JSON.stringify(summary))
	for sample: Dictionary in samples:
		print("M22 sample: %s" % JSON.stringify(sample))


func _stat_value(stats: Dictionary, section: String, side: String) -> int:
	var section_data = stats.get(section, {})
	if section_data is Dictionary:
		return int(section_data.get(side, 0))
	return 0


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
