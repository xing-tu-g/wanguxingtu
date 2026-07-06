extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const StrategyCardSystemScript: GDScript = preload("res://scripts/battle/StrategyCardSystem.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()

	_check_master_levels(failures)
	_check_terrain_data(failures)
	_check_strategy_card_data(failures)
	_check_strategy_card_rules(failures)
	_check_mvp_12_heroes_and_skills(failures)

	if failures.is_empty():
		print("M73 content completion checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_master_levels(failures: Array[String]) -> void:
	var levels: Array = DataLoaderScript.data.get("master_levels", [])
	_expect(levels.size() == 10, "master level table contains levels 1-10", failures)
	for index in range(10):
		var level_def: Dictionary = levels[index]
		var expected_level := index + 1
		_expect(int(level_def.get("level", 0)) == expected_level, "master levels are in ascending order", failures)
		_expect(int(level_def.get("max_hp", 0)) == 24 + expected_level * 6, "master HP follows MVP 30-84 curve", failures)


func _check_terrain_data(failures: Array[String]) -> void:
	var terrains_by_id := _by_id(DataLoaderScript.data.get("terrains", []))
	for terrain_id in ["grass", "swamp", "river", "highland"]:
		_expect(terrains_by_id.has(terrain_id), "terrain table includes %s" % terrain_id, failures)
		_expect(bool(terrains_by_id.get(terrain_id, {}).get("walkable", false)), "%s is walkable" % terrain_id, failures)

	var swamp_effects: Dictionary = terrains_by_id.get("swamp", {}).get("effects", {})
	var highland_effects: Dictionary = terrains_by_id.get("highland", {}).get("effects", {})
	_expect(int(swamp_effects.get("movement_cost_delta", 0)) == 1, "swamp data declares +1 movement cost", failures)
	_expect(swamp_effects.get("ignore_classes", []).has("warrior"), "swamp data exempts warriors", failures)
	_expect(int(highland_effects.get("range_delta", 0)) == 1, "highland data declares +1 range", failures)
	_expect(highland_effects.get("affected_classes", []).has("mage"), "highland data affects mages", failures)


func _check_strategy_card_data(failures: Array[String]) -> void:
	var cards_by_id := _by_id(DataLoaderScript.data.get("strategy_cards", []))
	for card_id in ["fire_arrow", "inspire", "rockfall", "supply", "march", "earthquake"]:
		_expect(cards_by_id.has(card_id), "strategy card table includes %s" % card_id, failures)
		_expect(str(cards_by_id.get(card_id, {}).get("timing", "")) == "strategy_phase", "%s uses strategy phase timing" % card_id, failures)

	_expect(str(cards_by_id.fire_arrow.effect_type) == "side_class_attack_delta", "fire arrow data targets a class attack buff", failures)
	_expect(str(cards_by_id.march.effect_type) == "side_move_delta", "march data targets movement buff", failures)
	_expect(str(cards_by_id.rockfall.effect_type) == "enemy_half_random_cell_damage", "rockfall data targets enemy half cells", failures)


func _check_strategy_card_rules(failures: Array[String]) -> void:
	var attack_state = BattleStateScript.new()
	var archer: Dictionary = _add_unit(attack_state, "archer", "left", 4, 1, {"class": "archer", "attack": 2, "range": 1})
	var warrior: Dictionary = _add_unit(attack_state, "warrior", "left", 4, 2, {"class": "warrior", "attack": 2, "range": 1})
	StrategyCardSystemScript.play_card(attack_state, "left", StrategyCardSystemScript.CARD_FIRE_ARROW)
	_expect(attack_state.get_unit_attack(archer) == 4, "fire arrow gives allied archers +2 attack", failures)
	_expect(attack_state.get_unit_attack(warrior) == 2, "fire arrow does not buff warriors", failures)
	StrategyCardSystemScript.play_card(attack_state, "left", StrategyCardSystemScript.CARD_INSPIRE)
	_expect(attack_state.get_unit_attack(archer) == 6, "inspire stacks as a separate side attack effect", failures)
	_expect(attack_state.get_unit_attack(warrior) == 4, "inspire buffs all allied units", failures)
	attack_state.clear_side_turn_effects("left")
	_expect(attack_state.get_unit_attack(archer) == 2, "strategy attack effects clear at turn end", failures)

	var march_state = BattleStateScript.new()
	var runner: Dictionary = _add_unit(march_state, "runner", "left", 2, 3, {"move": 1})
	StrategyCardSystemScript.play_card(march_state, "left", StrategyCardSystemScript.CARD_MARCH)
	var move_result: Dictionary = MovementSystemScript.move_unit_forward(march_state, runner)
	_expect(march_state.get_unit_move(runner) == 2, "march records +1 movement on current side", failures)
	_expect(move_result.steps == 1 and int(runner.column) == 3, "march does not break one-cell forward movement rule", failures)

	var rock_state = BattleStateScript.new()
	var target: Dictionary = _add_unit(rock_state, "rock_target", "right", 7, 3, {"hp": 15, "max_hp": 15})
	var chosen_cell := _first_rockfall_cell("left", 73)
	rock_state.move_unit(target, chosen_cell.x, chosen_cell.y)
	var rock_result: Dictionary = StrategyCardSystemScript.play_card(rock_state, "left", StrategyCardSystemScript.CARD_ROCKFALL, {"seed": 73})
	_expect(rock_result.selected_cells.size() == 3, "rockfall selects three enemy-half cells", failures)
	_expect(rock_result.hits.size() == 1, "rockfall damages unit occupying a selected cell", failures)
	_expect(int(target.hp) == 10, "rockfall deals 5 true damage", failures)


func _check_mvp_12_heroes_and_skills(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var mvp_ids := [
		"guanyu",
		"zhouyu",
		"zhangjiao",
		"zhaoyun",
		"zhangfei",
		"sunshangxiang",
		"zhugeliang",
		"caocao",
		"simayi",
		"zhangliao",
		"luxun",
		"lvbu",
	]
	for hero_id in mvp_ids:
		var hero_def: Dictionary = state.get_hero_def(hero_id)
		_expect(not hero_def.is_empty(), "MVP 12 hero exists: %s" % hero_id, failures)
		_expect(not hero_def.get("skill_ids", []).is_empty(), "MVP 12 hero has observable skill: %s" % hero_id, failures)

	state.set_star_power("left", 10)
	var zhuge_result: Dictionary = state.deploy_hero("zhugeliang", "left", 2, 1)
	_expect(zhuge_result.ok and int(zhuge_result.get("unit", {}).max_hp) == 8, "Zhuge Liang deploy skill modifies HP", failures)

	var caocao: Dictionary = _add_unit(state, "caocao_unit", "left", 2, 2, {"hero_id": "caocao", "skill_ids": ["caocao_march"], "move": 1})
	var turns = TurnControllerScript.new(state, "left")
	turns.start_side_turn()
	_expect(state.get_unit_move(caocao) == 2, "Cao Cao turn-start skill grants side movement", failures)
	turns.end_side_turn()
	_expect(state.get_unit_move(caocao) == 1, "Cao Cao movement effect clears at turn end", failures)

	var sima_state = BattleStateScript.new()
	sima_state.set_star_power("left", 10)
	var enemy: Dictionary = _add_unit(sima_state, "enemy", "right", 8, 3, {"attack": 3})
	var sima_result: Dictionary = sima_state.deploy_hero("simayi", "left", 2, 3)
	_expect(sima_result.ok and sima_state.get_unit_attack(enemy) == 2, "Sima Yi deploy skill applies enemy attack down", failures)

	var luxun_state = BattleStateScript.new()
	var luxun: Dictionary = _add_unit(luxun_state, "luxun_unit", "left", 4, 3, {"hero_id": "luxun", "skill_ids": ["luxun_burn_link"], "attack": 3, "range": 3, "damage_type": "magic"})
	var burn_target: Dictionary = _add_unit(luxun_state, "burn_target", "right", 6, 3, {"hp": 10, "max_hp": 10})
	MovementSystemScript.act_unit(luxun_state, luxun)
	_expect(burn_target.get("statuses", {}).has("burn"), "Lu Xun applies burn on hit", failures)

	var burst_state = BattleStateScript.new()
	var lvbu: Dictionary = _add_unit(burst_state, "lvbu_unit", "left", 4, 4, {"hero_id": "lvbu", "skill_ids": ["lvbu_rage"], "attack": 5, "range": 1})
	var burst_target: Dictionary = _add_unit(burst_state, "burst_target", "right", 5, 4, {"hp": 10, "max_hp": 10})
	var burst_result: Dictionary = MovementSystemScript.act_unit(burst_state, lvbu)
	var lvbu_skill: Dictionary = _skill_by_id("lvbu_rage")
	var expected_hp := 10 - int(lvbu.get("attack", 0)) - int(lvbu_skill.get("params", {}).get("damage", 0))
	_expect(burst_result.skill_results.size() == 1 and int(burst_target.hp) == expected_hp, "Lu Bu configured bonus damage is observable", failures)


func _first_rockfall_cell(side: String, seed_value: int) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cells: Array[Vector2i] = []
	var min_column := 6
	var max_column := 10
	if side == "right":
		min_column = 1
		max_column = 5
	for column in range(min_column, max_column + 1):
		for row in range(1, 6):
			cells.append(Vector2i(column, row))
	for index in range(cells.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var current_value = cells[index]
		cells[index] = cells[swap_index]
		cells[swap_index] = current_value
	return cells[0]


func _add_unit(state, unit_id: String, side: String, column: int, row: int, overrides: Dictionary = {}) -> Dictionary:
	var unit_data := {
		"instance_id": unit_id,
		"entry_order": state.next_unit_sequence,
		"hero_id": unit_id,
		"name": unit_id,
		"max_hp": 10,
		"hp": 10,
		"attack": 2,
		"range": 1,
		"move": 1,
		"class": "warrior",
		"physical_block": 0,
		"magic_block": 0,
		"damage_type": "physical",
		"skill_ids": [],
		"statuses": {},
		"stats": {},
	}
	for key in overrides:
		unit_data[key] = overrides[key]
	var result: Dictionary = state.create_unit_instance(unit_data, side, column, row)
	return result.get("unit", {})


func _by_id(rows: Array) -> Dictionary:
	var result := {}
	for row: Dictionary in rows:
		result[str(row.get("id", ""))] = row
	return result


func _skill_by_id(skill_id: String) -> Dictionary:
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			return skill
	return {}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)

