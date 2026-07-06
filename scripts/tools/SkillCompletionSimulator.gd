extends RefCounted
class_name SkillCompletionSimulator

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BattleDeckScript: GDScript = preload("res://scripts/battle/BattleDeck.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")

const STARTING_HAND_SIZE := 5
const DRAW_PER_SIDE_TURN := 1
const MAX_SIDE_TURNS := 240


static func run(sample_count: int = 100) -> Dictionary:
	DataLoaderScript.load_all()
	var hero_defs := _hero_defs()
	var hero_ids := hero_defs.keys()
	hero_ids.sort()
	var aggregate := _empty_aggregate(sample_count)

	for index in range(sample_count):
		var sample := _run_sample(index, hero_ids, hero_defs)
		aggregate.samples.append(sample)
		_merge_sample(aggregate, sample, hero_defs)

	_finalize(aggregate, hero_defs)
	return aggregate


static func save_report(report: Dictionary, output_path: String) -> bool:
	var dir_path := output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true


static func _run_sample(index: int, hero_ids: Array, hero_defs: Dictionary) -> Dictionary:
	var state = BattleStateScript.new()
	state.terrain_system.generate_deterministic(index + 1)
	var first_side := BoardModelScript.SIDE_LEFT if index % 2 == 0 else BoardModelScript.SIDE_RIGHT
	var turns = TurnControllerScript.new(state, first_side)
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(_rotated(hero_ids, index), _rotated(hero_ids, index * 7 + 3), STARTING_HAND_SIZE, false, index + 1009)

	var deployed_by_side := {
		BoardModelScript.SIDE_LEFT: [],
		BoardModelScript.SIDE_RIGHT: [],
	}
	var side_turns_taken := 0
	var result := {}
	while side_turns_taken < MAX_SIDE_TURNS:
		var acting_side: String = turns.current_side
		turns.start_side_turn()
		battle_deck.draw(acting_side, DRAW_PER_SIDE_TURN)
		var deploy_result := _auto_deploy_from_hand(state, acting_side, battle_deck.hand_for_side(acting_side))
		if bool(deploy_result.get("ok", false)):
			var hero_id := str(deploy_result.get("hero_id", ""))
			battle_deck.consume_from_hand(acting_side, hero_id)
			battle_deck.draw(acting_side, 1)
			deployed_by_side[acting_side].append(hero_id)
		turns.act_current_side()
		turns.end_side_turn()
		side_turns_taken += 1
		result = _battle_result(state, battle_deck)
		if not result.is_empty():
			break

	var snapshot: Dictionary = state.battle_stats.snapshot()
	var outcome := str(result.get("outcome", "timeout"))
	return {
		"index": index,
		"first_side": first_side,
		"outcome": outcome,
		"ended": outcome != "timeout",
		"round_number": turns.turn_number,
		"side_turns": side_turns_taken,
		"left_hp": state.get_master_hp(BoardModelScript.SIDE_LEFT),
		"right_hp": state.get_master_hp(BoardModelScript.SIDE_RIGHT),
		"deployed_left": deployed_by_side[BoardModelScript.SIDE_LEFT],
		"deployed_right": deployed_by_side[BoardModelScript.SIDE_RIGHT],
		"stats": snapshot,
	}


static func _auto_deploy_from_hand(state, side: String, hand: Array) -> Dictionary:
	if hand.is_empty():
		return {"ok": false, "reason": "empty_hand"}
	for hero_id_value in hand:
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


static func _deployment_columns(side: String) -> Array[int]:
	if side == BoardModelScript.SIDE_RIGHT:
		return [8, 9, 10]
	return [3, 2, 1]


static func _battle_result(state, battle_deck) -> Dictionary:
	var left_hp: int = state.get_master_hp(BoardModelScript.SIDE_LEFT)
	var right_hp: int = state.get_master_hp(BoardModelScript.SIDE_RIGHT)
	var left_units: int = state.get_units_by_side(BoardModelScript.SIDE_LEFT).size()
	var right_units: int = state.get_units_by_side(BoardModelScript.SIDE_RIGHT).size()
	var left_defeated: bool = left_hp <= 0 or battle_deck.has_no_deck_hand_or_units(BoardModelScript.SIDE_LEFT, left_units)
	var right_defeated: bool = right_hp <= 0 or battle_deck.has_no_deck_hand_or_units(BoardModelScript.SIDE_RIGHT, right_units)
	if not left_defeated and not right_defeated:
		return {}
	if left_defeated and right_defeated:
		return {"outcome": "both_failed"}
	if right_defeated:
		return {"outcome": "left_wins"}
	return {"outcome": "right_wins"}


static func _hero_defs() -> Dictionary:
	var result := {}
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if bool(hero.get("is_summon", false)) or str(hero.get("id", "")) == "yellow_turban":
			continue
		result[str(hero.get("id", ""))] = hero
	return result


static func _empty_aggregate(sample_count: int) -> Dictionary:
	return {
		"sample_count": sample_count,
		"ended_count": 0,
		"timeouts": 0,
		"left_wins": 0,
		"right_wins": 0,
		"both_failed": 0,
		"faction": {},
		"class": {},
		"hero": {},
		"skill_triggers": {},
		"faction_energy_gained": {},
		"faction_energy_sources": {},
		"faction_energy_heroes": {},
		"hero_damage_dealt": {},
		"hero_healing_done": {},
		"hero_damage_taken": {},
		"top_damage_hero": {},
		"top_healing_hero": {},
		"top_tank_hero": {},
		"anomalies": [],
		"samples": [],
	}


static func _merge_sample(aggregate: Dictionary, sample: Dictionary, hero_defs: Dictionary) -> void:
	var outcome := str(sample.get("outcome", "timeout"))
	if bool(sample.get("ended", false)):
		aggregate.ended_count += 1
	else:
		aggregate.timeouts += 1
	match outcome:
		"left_wins":
			aggregate.left_wins += 1
		"right_wins":
			aggregate.right_wins += 1
		"both_failed":
			aggregate.both_failed += 1

	_merge_deployed_side(aggregate, sample.get("deployed_left", []), outcome == "left_wins", hero_defs)
	_merge_deployed_side(aggregate, sample.get("deployed_right", []), outcome == "right_wins", hero_defs)

	var stats: Dictionary = sample.get("stats", {})
	_merge_counter(aggregate.skill_triggers, stats.get("skill_triggers", {}))
	_merge_nested_counter(aggregate.faction_energy_gained, stats.get("faction_energy_gained", {}))
	_merge_counter(aggregate.faction_energy_sources, stats.get("faction_energy_sources", {}))
	_merge_counter(aggregate.faction_energy_heroes, stats.get("faction_energy_heroes", {}))
	_merge_counter(aggregate.hero_damage_dealt, stats.get("hero_damage_dealt", {}))
	_merge_counter(aggregate.hero_healing_done, stats.get("hero_healing_done", {}))
	_merge_counter(aggregate.hero_damage_taken, stats.get("hero_damage_taken", {}))


static func _merge_deployed_side(aggregate: Dictionary, hero_ids: Array, won: bool, hero_defs: Dictionary) -> void:
	for hero_id_value in hero_ids:
		var hero_id := str(hero_id_value)
		if not hero_defs.has(hero_id):
			continue
		var hero_def: Dictionary = hero_defs[hero_id]
		_increment_nested(aggregate.hero, hero_id, "appearances", 1)
		_increment_nested(aggregate.faction, str(hero_def.get("faction", "")), "appearances", 1)
		_increment_nested(aggregate.class, str(hero_def.get("class", "")), "appearances", 1)
		if won:
			_increment_nested(aggregate.hero, hero_id, "wins", 1)
			_increment_nested(aggregate.faction, str(hero_def.get("faction", "")), "wins", 1)
			_increment_nested(aggregate.class, str(hero_def.get("class", "")), "wins", 1)


static func _finalize(aggregate: Dictionary, hero_defs: Dictionary) -> void:
	for section_name in ["hero", "faction", "class"]:
		for key in aggregate[section_name].keys():
			var row: Dictionary = aggregate[section_name][key]
			var appearances := int(row.get("appearances", 0))
			row["win_rate"] = 0.0 if appearances == 0 else float(row.get("wins", 0)) / float(appearances)
			aggregate[section_name][key] = row

	aggregate.top_damage_hero = _top_counter(aggregate.hero_damage_dealt)
	aggregate.top_healing_hero = _top_counter(aggregate.hero_healing_done)
	aggregate.top_tank_hero = _top_counter(aggregate.hero_damage_taken)
	_add_anomalies(aggregate, hero_defs)


static func _add_anomalies(aggregate: Dictionary, hero_defs: Dictionary) -> void:
	if int(aggregate.get("timeouts", 0)) > 0:
		aggregate.anomalies.append("存在 %d 局达到回合上限" % int(aggregate.get("timeouts", 0)))
	for hero_id in hero_defs.keys():
		if int(aggregate.hero.get(hero_id, {}).get("appearances", 0)) == 0:
			aggregate.anomalies.append("武将未出场：%s" % hero_id)
	for skill in DataLoaderScript.data.get("skills", []):
		var skill_id := str(skill.get("id", ""))
		if int(aggregate.skill_triggers.get(skill_id, 0)) == 0:
			aggregate.anomalies.append("技能未触发：%s" % skill_id)


static func _rotated(values: Array, offset: int) -> Array:
	var result := values.duplicate()
	if result.is_empty():
		return result
	var shift := offset % result.size()
	return result.slice(shift) + result.slice(0, shift)


static func _merge_counter(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		_increment(target, str(key), int(source.get(key, 0)))


static func _merge_nested_counter(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var source_row: Dictionary = source.get(key, {})
		if not target.has(key):
			target[str(key)] = {}
		var target_row: Dictionary = target.get(key, {})
		for field in source_row.keys():
			target_row[str(field)] = int(target_row.get(field, 0)) + int(source_row.get(field, 0))
		target[str(key)] = target_row


static func _increment_nested(target: Dictionary, key: String, field: String, amount: int) -> void:
	if key.is_empty():
		return
	if not target.has(key):
		target[key] = {"appearances": 0, "wins": 0}
	var row: Dictionary = target[key]
	row[field] = int(row.get(field, 0)) + amount
	target[key] = row


static func _increment(target: Dictionary, key: String, amount: int) -> void:
	if key.is_empty() or amount == 0:
		return
	target[key] = int(target.get(key, 0)) + amount


static func _top_counter(counter: Dictionary) -> Dictionary:
	var best_key := ""
	var best_value := -1
	for key in counter.keys():
		var value := int(counter.get(key, 0))
		if value > best_value:
			best_key = str(key)
			best_value = value
	return {"hero_id": best_key, "value": maxi(0, best_value)}
