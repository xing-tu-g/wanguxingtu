extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const BattleDeckScript: GDScript = preload("res://scripts/battle/BattleDeck.gd")

const AUTO_HERO_IDS := ["guanyu", "zhaoyun", "sunshangxiang", "zhangfei", "zhouyu", "zhangjiao"]
const MAX_SIDE_TURNS := 80
const CHECKPOINT_ROUND := 4
const STARTING_HAND_SIZE := 3
const DRAW_PER_SIDE_TURN := 1


func _init() -> void:
	var failures: Array[String] = []
	var trend: Dictionary = _run_auto_play_probe()
	_check_probe_shape(trend, failures)
	_check_late_game_trend(trend, failures)
	_print_probe_summary(trend)
	await process_frame

	if failures.is_empty():
		print("M19 pacing trend probe checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _run_auto_play_probe() -> Dictionary:
	var state = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)
	var turns = TurnControllerScript.new(state, BoardModelScript.SIDE_LEFT)
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(AUTO_HERO_IDS, AUTO_HERO_IDS, STARTING_HAND_SIZE)
	var next_player_index := 0
	var next_enemy_index := 0
	var side_turns_taken := 0
	var checkpoint_snapshot: Dictionary = {}
	var final_result: Dictionary = {}
	while side_turns_taken < MAX_SIDE_TURNS:
		var acting_side: String = turns.current_side
		turns.start_side_turn()
		if acting_side == BoardModelScript.SIDE_LEFT:
			battle_deck.draw(BoardModelScript.SIDE_LEFT, DRAW_PER_SIDE_TURN)
			var player_deploy: Dictionary = _auto_deploy_from_hand(state, BoardModelScript.SIDE_LEFT, battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT), next_player_index)
			if bool(player_deploy.get("ok", false)):
				battle_deck.consume_from_hand(BoardModelScript.SIDE_LEFT, str(player_deploy.get("hero_id", "")))
				next_player_index += 1
		else:
			battle_deck.draw(BoardModelScript.SIDE_RIGHT, DRAW_PER_SIDE_TURN)
			var enemy_deploy: Dictionary = _auto_deploy_from_hand(state, BoardModelScript.SIDE_RIGHT, battle_deck.hand_for_side(BoardModelScript.SIDE_RIGHT), next_enemy_index)
			if bool(enemy_deploy.get("ok", false)):
				battle_deck.consume_from_hand(BoardModelScript.SIDE_RIGHT, str(enemy_deploy.get("hero_id", "")))
				next_enemy_index += 1
		turns.act_current_side()
		var end_result: Dictionary = turns.end_side_turn()
		side_turns_taken += 1
		if bool(end_result.get("completed_round", false)) and int(end_result.get("turn_number", 0)) == CHECKPOINT_ROUND + 1 and checkpoint_snapshot.is_empty():
			checkpoint_snapshot = _snapshot_probe(state, turns, side_turns_taken, battle_deck)
		final_result = _battle_result(state, turns, battle_deck)
		if not final_result.is_empty():
			break

	var final_snapshot: Dictionary = _snapshot_probe(state, turns, side_turns_taken, battle_deck)
	return {
		"checkpoint": checkpoint_snapshot,
		"final": final_snapshot,
		"battle_result": final_result,
		"post_checkpoint_delta": _snapshot_delta(checkpoint_snapshot, final_snapshot),
	}


func _snapshot_probe(
	state,
	turns,
	side_turns_taken: int,
	battle_deck
) -> Dictionary:
	var stats: Dictionary = state.battle_stats.snapshot()
	var card_snapshot: Dictionary = battle_deck.snapshot()
	return {
		"turn_number": turns.turn_number,
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


func _snapshot_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	if before.is_empty() or after.is_empty():
		return {}
	var delta := {}
	for key in after.keys():
		if after[key] is int and before.has(key):
			delta[key] = int(after[key]) - int(before[key])
	return delta


func _check_probe_shape(trend: Dictionary, failures: Array[String]) -> void:
	_expect(not trend.get("battle_result", {}).is_empty(), "auto-play battle ends before probe cap", failures)
	_expect(not trend.get("checkpoint", {}).is_empty(), "probe captures mid-battle checkpoint snapshot", failures)
	_expect(not trend.get("final", {}).is_empty(), "probe captures final snapshot", failures)
	_expect(not trend.get("post_checkpoint_delta", {}).is_empty(), "probe computes post-checkpoint delta", failures)
	_expect(int(trend.final.get("turn_number", 0)) <= 40, "final round remains within pacing baseline", failures)
	_expect(int(trend.final.get("left_discard", 0)) > 0, "probe tracks player discard from deployments", failures)
	_expect(int(trend.final.get("right_discard", 0)) > 0, "probe tracks enemy discard from deployments", failures)


func _check_late_game_trend(trend: Dictionary, failures: Array[String]) -> void:
	var post_checkpoint_delta: Dictionary = trend.get("post_checkpoint_delta", {})
	var post_checkpoint_unit_damage := int(post_checkpoint_delta.get("unit_damage_left", 0)) + int(post_checkpoint_delta.get("unit_damage_right", 0))
	var post_checkpoint_master_damage := int(post_checkpoint_delta.get("master_damage_left", 0)) + int(post_checkpoint_delta.get("master_damage_right", 0))
	var post_checkpoint_defeats := int(post_checkpoint_delta.get("defeats_left", 0)) + int(post_checkpoint_delta.get("defeats_right", 0))
	_expect(post_checkpoint_unit_damage > 0, "battle still has unit damage after checkpoint", failures)
	_expect(post_checkpoint_master_damage > 0, "battle has breakthrough master damage after checkpoint", failures)
	_expect(post_checkpoint_defeats > 0, "battle resolves at least one unit after checkpoint", failures)


func _print_probe_summary(trend: Dictionary) -> void:
	print("M19 checkpoint snapshot: %s" % JSON.stringify(trend.get("checkpoint", {})))
	print("M19 final snapshot: %s" % JSON.stringify(trend.get("final", {})))
	print("M19 post-checkpoint delta: %s" % JSON.stringify(trend.get("post_checkpoint_delta", {})))



func _auto_deploy_from_hand(state, side: String, hand: Array, start_index: int) -> Dictionary:
	if hand.is_empty():
		return {"ok": false, "reason": "empty_hand"}
	for offset in range(hand.size()):
		var hero_id := str(hand[(start_index + offset) % hand.size()])
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


func _stat_value(stats: Dictionary, section: String, side: String) -> int:
	var section_data = stats.get(section, {})
	if section_data is Dictionary:
		return int(section_data.get(side, 0))
	return 0


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
