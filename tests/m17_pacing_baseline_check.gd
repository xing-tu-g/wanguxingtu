extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")

const PLAYER_AUTO_HERO_IDS := ["guanyu", "zhaoyun", "sunshangxiang", "zhangfei", "zhouyu", "zhangjiao"]
const MAX_SIDE_TURNS := 80


func _init() -> void:
	var failures: Array[String] = []
	await _check_enemy_auto_pool(failures)
	await _check_auto_play_pacing(failures)
	await process_frame

	if failures.is_empty():
		print("M17 pacing baseline checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_enemy_auto_pool(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var enemy_hero_ids: Array = screen._enemy_battle_hero_ids()
	_expect(enemy_hero_ids.size() >= PLAYER_AUTO_HERO_IDS.size(), "enemy auto deploy pool covers configured roster", failures)
	for hero_id in PLAYER_AUTO_HERO_IDS:
		_expect(enemy_hero_ids.has(hero_id), "enemy auto deploy pool includes %s" % hero_id, failures)
	screen.queue_free()


func _check_auto_play_pacing(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)
	var turns = TurnControllerScript.new(state, BoardModelScript.SIDE_LEFT)
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var enemy_hero_ids: Array = screen._enemy_battle_hero_ids()
	screen.queue_free()
	var next_player_index := 0
	var side_turns_taken := 0
	var player_deploy_count := 0
	var enemy_deploy_count := 0
	var last_battle_result := {}
	while side_turns_taken < MAX_SIDE_TURNS:
		var acting_side: String = turns.current_side
		turns.start_side_turn()
		var deploy_result: Dictionary = {}
		if acting_side == BoardModelScript.SIDE_LEFT:
			deploy_result = _auto_deploy_from_pool(state, BoardModelScript.SIDE_LEFT, PLAYER_AUTO_HERO_IDS, next_player_index)
			if bool(deploy_result.get("ok", false)):
				next_player_index += 1
				player_deploy_count += 1
		else:
			deploy_result = _auto_deploy_from_pool(state, BoardModelScript.SIDE_RIGHT, enemy_hero_ids, 0)
			if bool(deploy_result.get("ok", false)):
				enemy_deploy_count += 1
		turns.act_current_side()
		turns.end_side_turn()
		side_turns_taken += 1
		last_battle_result = _battle_result(state, turns)
		if not last_battle_result.is_empty():
			break

	_expect(side_turns_taken == MAX_SIDE_TURNS or not last_battle_result.is_empty(), "auto-play simulation reaches cap or result without crashing", failures)
	_expect(turns.turn_number >= 2, "auto-play advances multiple rounds", failures)
	_expect(player_deploy_count >= 3, "player side deploys multiple roster units", failures)
	_expect(enemy_deploy_count >= 3, "enemy side deploys multiple roster units", failures)


func _auto_deploy_from_pool(state, side: String, hero_ids: Array, start_index: int) -> Dictionary:
	for offset in range(hero_ids.size()):
		var hero_id := str(hero_ids[(start_index + offset) % hero_ids.size()])
		if not state.can_afford(side, hero_id):
			continue
		for column in _deployment_columns(side):
			for row in range(1, BoardModelScript.ROWS + 1):
				if not state.board.can_deploy(side, column, row):
					continue
				var deploy_result: Dictionary = state.deploy_hero(hero_id, side, column, row)
				if bool(deploy_result.get("ok", false)):
					return deploy_result
	return {"ok": false, "reason": "no_affordable_deploy_cell"}


func _deployment_columns(side: String) -> Array[int]:
	if side == BoardModelScript.SIDE_RIGHT:
		return [8, 9, 10]
	return [3, 2, 1]


func _battle_result(state, turns) -> Dictionary:
	var left_hp: int = state.get_master_hp(BoardModelScript.SIDE_LEFT)
	var right_hp: int = state.get_master_hp(BoardModelScript.SIDE_RIGHT)
	if left_hp > 0 and right_hp > 0:
		return {}
	var outcome := ""
	if left_hp <= 0 and right_hp <= 0:
		outcome = "both_failed"
	elif right_hp <= 0:
		outcome = "left_wins"
	else:
		outcome = "right_wins"
	return {
		"outcome": outcome,
		"round_number": turns.turn_number,
		"left_hp": left_hp,
		"right_hp": right_hp,
	}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
