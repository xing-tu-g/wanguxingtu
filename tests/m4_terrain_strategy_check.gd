extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const StrategyCardSystemScript: GDScript = preload("res://scripts/battle/StrategyCardSystem.gd")
const TargetingSystemScript: GDScript = preload("res://scripts/battle/TargetingSystem.gd")
const TerrainSystemScript: GDScript = preload("res://scripts/battle/TerrainSystem.gd")


func _init() -> void:
	var failures: Array[String] = []

	_check_terrain_generation_zones(failures)
	_check_highland_range(failures)
	_check_swamp_movement(failures)
	_check_river_damage_modifiers(failures)
	_check_supply_cap(failures)
	_check_earthquake_simultaneous_damage(failures)
	_check_inspire_one_turn_attack(failures)

	if failures.is_empty():
		print("M4 terrain and strategy checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_terrain_generation_zones(failures: Array[String]) -> void:
	var terrain_system = TerrainSystemScript.new()
	terrain_system.generate_deterministic(42)

	var left_count := 0
	var right_count := 0
	var public_count := 0
	for key in terrain_system.terrain_cells.keys():
		var parts := str(key).split(",")
		var column := int(parts[0])
		var zone: String = terrain_system.get_zone_for_column(column)
		if zone == TerrainSystemScript.ZONE_LEFT_DEPLOYMENT:
			left_count += 1
		elif zone == TerrainSystemScript.ZONE_RIGHT_DEPLOYMENT:
			right_count += 1
		elif zone == TerrainSystemScript.ZONE_PUBLIC:
			public_count += 1

	_expect(terrain_system.terrain_cells.size() == 5, "deterministic terrain creates five special cells", failures)
	_expect(left_count == 1, "terrain generation places one special cell in left deployment", failures)
	_expect(right_count == 1, "terrain generation places one special cell in right deployment", failures)
	_expect(public_count == 3, "terrain generation places three special cells in public zone", failures)


func _check_highland_range(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.terrain_system.set_terrain(4, 3, TerrainSystemScript.TERRAIN_HIGHLAND)
	var archer: Dictionary = _add_unit(state, "archer", "left", 4, 3, {"class": "archer", "range": 2})
	var target: Dictionary = _add_unit(state, "target", "right", 7, 3)
	var selected: Dictionary = TargetingSystemScript.select_target(archer, state.get_enemy_units("left"), state.terrain_system)
	_expect(selected.get("instance_id", "") == target.instance_id, "highland gives archer +1 attack range", failures)

	var warrior: Dictionary = _add_unit(state, "warrior", "left", 4, 4, {"class": "warrior", "range": 2})
	var far_target: Dictionary = _add_unit(state, "far_target", "right", 7, 4)
	var warrior_selected: Dictionary = TargetingSystemScript.select_target(warrior, [far_target], state.terrain_system)
	_expect(warrior_selected.is_empty(), "highland does not extend warrior range", failures)


func _check_swamp_movement(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.terrain_system.set_terrain(3, 3, TerrainSystemScript.TERRAIN_SWAMP)
	var mage: Dictionary = _add_unit(state, "mage", "left", 2, 3, {"class": "mage", "move": 2})
	var mage_result: Dictionary = MovementSystemScript.move_unit_forward(state, mage)
	_expect(mage_result.steps == 1 and int(mage.column) == 3, "swamp costs non-assassin/non-warrior 2 movement", failures)

	var warrior_state = BattleStateScript.new()
	warrior_state.terrain_system.set_terrain(3, 3, TerrainSystemScript.TERRAIN_SWAMP)
	var warrior: Dictionary = _add_unit(warrior_state, "warrior", "left", 2, 3, {"class": "warrior", "move": 2})
	var warrior_result: Dictionary = MovementSystemScript.move_unit_forward(warrior_state, warrior)
	_expect(warrior_result.steps == 2 and int(warrior.column) == 4, "warrior ignores swamp extra movement cost", failures)


func _check_river_damage_modifiers(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.terrain_system.set_terrain(4, 2, TerrainSystemScript.TERRAIN_RIVER)
	state.terrain_system.set_terrain(5, 2, TerrainSystemScript.TERRAIN_RIVER)
	var attacker: Dictionary = _add_unit(state, "river_attacker", "left", 4, 2, {"attack": 5, "range": 1})
	var target: Dictionary = _add_unit(state, "river_target", "right", 5, 2, {"hp": 10})
	var result: Dictionary = MovementSystemScript.act_unit(state, attacker)
	_expect(result.damage == 5, "river attacker -1 attack and river target +1 incoming damage both apply", failures)
	_expect(int(target.hp) == 5, "river unit damage changes target HP", failures)

	var master_state = BattleStateScript.new()
	master_state.terrain_system.set_terrain(10, 1, TerrainSystemScript.TERRAIN_RIVER)
	var master_attacker: Dictionary = _add_unit(master_state, "master_attacker", "left", 10, 1, {"attack": 5, "range": 1})
	var master_result: Dictionary = MovementSystemScript.act_unit(master_state, master_attacker)
	_expect(master_result.damage == 3, "river master attack applies attack -1 and master damage -1", failures)
	_expect(master_state.get_master_hp("right") == 27, "river master damage changes master HP", failures)


func _check_supply_cap(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	state.apply_master_damage("left", 5, 0)
	var result: Dictionary = StrategyCardSystemScript.play_card(state, "left", StrategyCardSystemScript.CARD_SUPPLY)
	_expect(result.healed == 5, "supply heals only up to master max HP", failures)
	_expect(state.get_master_hp("left") == state.get_master_max_hp("left"), "supply does not exceed master max HP", failures)


func _check_earthquake_simultaneous_damage(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var result: Dictionary = StrategyCardSystemScript.play_card(state, "left", StrategyCardSystemScript.CARD_EARTHQUAKE)
	_expect(result.left_damage == 10 and result.right_damage == 10, "earthquake damages both masters for 10", failures)
	_expect(state.get_master_hp("left") == 20 and state.get_master_hp("right") == 20, "earthquake reduces both master HP equally", failures)


func _check_inspire_one_turn_attack(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var attacker: Dictionary = _add_unit(state, "inspired", "left", 4, 1, {"attack": 2, "range": 1})
	var target: Dictionary = _add_unit(state, "target", "right", 5, 1, {"hp": 10})
	StrategyCardSystemScript.play_card(state, "left", StrategyCardSystemScript.CARD_INSPIRE)
	var result: Dictionary = MovementSystemScript.act_unit(state, attacker)
	_expect(result.damage == 4 and int(target.hp) == 6, "inspire grants current side +2 attack this turn", failures)
	state.clear_side_turn_effects("left")
	_expect(state.get_unit_attack(attacker) == 2, "inspire can be cleared as a one-turn effect", failures)


func _add_unit(state, unit_id: String, side: String, column: int, row: int, overrides: Dictionary = {}) -> Dictionary:
	var unit_data := {
		"instance_id": unit_id,
		"entry_order": state.next_unit_sequence,
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
	}
	for key in overrides:
		unit_data[key] = overrides[key]
	var create_result: Dictionary = state.create_unit_instance(unit_data, side, column, row)
	return create_result.unit


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
