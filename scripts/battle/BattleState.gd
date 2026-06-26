extends RefCounted
class_name BattleState

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleStatsScript: GDScript = preload("res://scripts/battle/BattleStats.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const DamageSystemScript: GDScript = preload("res://scripts/battle/DamageSystem.gd")
const SkillSystemScript: GDScript = preload("res://scripts/battle/SkillSystem.gd")
const TerrainSystemScript: GDScript = preload("res://scripts/battle/TerrainSystem.gd")

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const STAR_POWER_CAP := 10

var board: BoardModel = BoardModelScript.new()
var terrain_system: TerrainSystem = TerrainSystemScript.new()
var current_side: String = SIDE_LEFT
var master_hp: Dictionary = {}
var master_max_hp: Dictionary = {}
var star_power: Dictionary = {}
var star_tide_master_damage_bonus: int = 0
var placed_units: Dictionary = {}
var next_unit_sequence: int = 1
var side_turn_effects: Dictionary = {}
var battle_stats: BattleStats = BattleStatsScript.new()

func _init() -> void:
	reset()

func reset() -> void:
	if DataLoaderScript.data.is_empty():
		DataLoaderScript.load_all()

	board.reset()
	terrain_system.reset()
	current_side = SIDE_LEFT
	star_tide_master_damage_bonus = 0
	placed_units.clear()
	next_unit_sequence = 1
	battle_stats.reset()
	side_turn_effects = {
		SIDE_LEFT: {},
		SIDE_RIGHT: {},
	}

	var initial_master_hp := _get_master_max_hp(1)
	master_max_hp = {
		SIDE_LEFT: initial_master_hp,
		SIDE_RIGHT: initial_master_hp,
	}
	master_hp = {
		SIDE_LEFT: initial_master_hp,
		SIDE_RIGHT: initial_master_hp,
	}
	star_power = {
		SIDE_LEFT: 5,
		SIDE_RIGHT: 6,
	}

func get_star_power(side: String) -> int:
	return int(star_power.get(side, 0))

func set_star_power(side: String, value: int) -> int:
	star_power[side] = clampi(value, 0, STAR_POWER_CAP)
	return get_star_power(side)

func change_star_power(side: String, delta: int) -> int:
	var new_value: int = set_star_power(side, get_star_power(side) + delta)
	pass  # EventBus emit moved to BattleScreen
	return new_value

func restore_star_power(side: String, amount: int) -> int:
	return change_star_power(side, maxi(0, amount))

func get_master_hp(side: String) -> int:
	return int(master_hp.get(side, 0))

func get_master_max_hp(side: String) -> int:
	return int(master_max_hp.get(side, 0))

func heal_master(side: String, amount: int) -> int:
	var before_hp := get_master_hp(side)
	master_hp[side] = mini(get_master_max_hp(side), before_hp + maxi(0, amount))
	return get_master_hp(side) - before_hp

func get_hero_def(hero_id: String) -> Dictionary:
	var heroes: Array = DataLoaderScript.data.get("heroes", [])
	for hero: Dictionary in heroes:
		if str(hero.get("id", "")) == hero_id:
			return hero
	return {}

func can_afford(side: String, hero_id: String) -> bool:
	var hero_def: Dictionary = get_hero_def(hero_id)
	if hero_def.is_empty():
		return false
	return get_star_power(side) >= int(hero_def.get("cost", 0))

func deploy_hero(hero_id: String, side: String, column: int, row: int) -> Dictionary:
	var hero_def: Dictionary = get_hero_def(hero_id)
	if hero_def.is_empty():
		return {"ok": false, "reason": "unknown_hero"}

	var board_validation: Dictionary = board.validate_deployment(side, column, row)
	if not board_validation.ok:
		return board_validation

	var cost := int(hero_def.get("cost", 0))
	if get_star_power(side) < cost:
		return {"ok": false, "reason": "not_enough_star_power"}

	var unit_id := "unit_%03d" % next_unit_sequence
	next_unit_sequence += 1

	var unit_data := build_unit_data(hero_id, hero_def)
	unit_data["instance_id"] = unit_id
	unit_data["entry_order"] = next_unit_sequence - 1

	var place_result: Dictionary = board.place_unit(unit_data, side, column, row)
	if not place_result.ok:
		return place_result

	var placed_unit: Dictionary = place_result.unit
	placed_units[unit_id] = placed_unit
	change_star_power(side, -cost)
	battle_stats.record_deployment(side)
	var skill_results: Array = trigger_skill_event(SkillSystemScript.TRIGGER_DEPLOY, {"source_unit": placed_unit})
	pass  # EventBus emit moved to BattleScreen

	return {
		"ok": true,
		"reason": "",
		"unit": placed_unit,
		"cost": cost,
		"remaining_star_power": get_star_power(side),
		"skill_results": skill_results,
	}

func build_unit_data(hero_id: String, hero_def: Dictionary) -> Dictionary:
	var max_hp := int(hero_def.get("max_hp", 1))
	return {
		"instance_id": "",
		"entry_order": next_unit_sequence,
		"hero_id": hero_id,
		"name": hero_def.get("name", hero_id),
		"cost": int(hero_def.get("cost", 0)),
		"max_hp": max_hp,
		"hp": max_hp,
		"attack": int(hero_def.get("attack", 0)),
		"range": int(hero_def.get("range", 1)),
		"move": int(hero_def.get("move", 0)),
		"class": str(hero_def.get("class", "")),
		"physical_block": int(hero_def.get("physical_block", 0)),
		"magic_block": int(hero_def.get("magic_block", 0)),
		"damage_type": str(hero_def.get("damage_type", "physical")),
		"can_pass_blockers": bool(hero_def.get("can_pass_blockers", false)),
		"skill_ids": hero_def.get("skill_ids", []).duplicate(true),
		"statuses": {},
		"stats": {},
	}

func create_unit_instance(unit_data: Dictionary, side: String, column: int, row: int) -> Dictionary:
	var unit_id := str(unit_data.get("instance_id", ""))
	if unit_id.is_empty():
		unit_id = "unit_%03d" % next_unit_sequence
		next_unit_sequence += 1
	else:
		next_unit_sequence = maxi(next_unit_sequence, int(unit_data.get("entry_order", next_unit_sequence)) + 1)

	var instance := unit_data.duplicate(true)
	instance["instance_id"] = unit_id
	instance["entry_order"] = int(instance.get("entry_order", next_unit_sequence - 1))
	instance["side"] = side
	instance["column"] = column
	instance["row"] = row
	instance["max_hp"] = int(instance.get("max_hp", instance.get("hp", 1)))
	instance["hp"] = int(instance.get("hp", instance.get("max_hp", 1)))
	instance["attack"] = int(instance.get("attack", 0))
	instance["range"] = int(instance.get("range", 1))
	instance["move"] = int(instance.get("move", 0))
	instance["class"] = str(instance.get("class", ""))
	instance["physical_block"] = int(instance.get("physical_block", 0))
	instance["magic_block"] = int(instance.get("magic_block", 0))
	instance["damage_type"] = str(instance.get("damage_type", "physical"))
	instance["can_pass_blockers"] = bool(instance.get("can_pass_blockers", false))
	instance["skill_ids"] = instance.get("skill_ids", []).duplicate(true)
	var statuses_value = instance.get("statuses", {})
	if statuses_value is Dictionary:
		instance["statuses"] = statuses_value.duplicate(true)
	elif statuses_value is Array:
		var migrated_statuses := {}
		for status: Dictionary in statuses_value:
			var status_id := str(status.get("id", ""))
			if not status_id.is_empty():
				migrated_statuses[status_id] = status.duplicate(true)
		instance["statuses"] = migrated_statuses
	else:
		instance["statuses"] = {}
	instance["stats"] = instance.get("stats", {}).duplicate(true)

	var place_result: Dictionary = board.place_unit_anywhere(instance, side, column, row)
	if not place_result.ok:
		return place_result

	var placed_unit: Dictionary = place_result.unit
	placed_units[unit_id] = placed_unit
	return {"ok": true, "reason": "", "unit": placed_unit}

func get_units_by_side(side: String) -> Array:
	var units: Array = []
	for unit: Dictionary in placed_units.values():
		if str(unit.get("side", "")) == side:
			units.append(unit)
	return units

func get_enemy_side(side: String) -> String:
	if side == SIDE_LEFT:
		return SIDE_RIGHT
	return SIDE_LEFT

func get_enemy_units(side: String) -> Array:
	return get_units_by_side(get_enemy_side(side))

func get_unit_by_id(unit_id: String) -> Dictionary:
	return placed_units.get(unit_id, {})

func move_unit(unit: Dictionary, column: int, row: int) -> Dictionary:
	var unit_id := str(unit.get("instance_id", ""))
	var move_result: Dictionary = board.move_unit(unit_id, column, row)
	if move_result.ok:
		placed_units[unit_id] = move_result.unit
	return move_result

func apply_damage_to_unit(unit: Dictionary, raw_damage: int, damage_type: String = "physical", attacker: Variant = null) -> int:
	var damage: int = DamageSystemScript.calculate_unit_damage(raw_damage, damage_type, unit, terrain_system)
	damage = _apply_adjacent_guard_reduction(unit, damage, damage_type)
	var unit_id := str(unit.get("instance_id", ""))
	var was_defeated := int(unit.get("hp", 0)) > 0 and int(unit.get("hp", 0)) - damage <= 0
	unit["hp"] = maxi(0, int(unit.get("hp", 0)) - damage)
	if int(unit.get("hp", 0)) <= 0:
		remove_unit(unit_id)
	battle_stats.record_unit_damage(attacker, unit, damage, was_defeated)
	pass  # EventBus emit moved to BattleScreen
	if attacker is Dictionary:
		pass  # EventBus emit moved to BattleScreen
	if was_defeated:
		pass  # EventBus emit moved to BattleScreen
	return damage

func trigger_skill_event(trigger: String, context: Dictionary = {}) -> Array:
	return SkillSystemScript.trigger_event(self, trigger, context)

func process_end_turn_statuses(side: String = "") -> Array:
	return SkillSystemScript.process_end_turn_statuses(self, side)

func get_skill_defs() -> Array:
	return DataLoaderScript.data.get("skills", [])

func apply_master_damage(side: String, damage: int, star_tide_bonus: int = -1, attacker: Variant = null) -> int:
	var bonus := star_tide_master_damage_bonus
	if star_tide_bonus >= 0:
		bonus = star_tide_bonus
	var terrain_delta := 0
	if attacker is Dictionary:
		terrain_delta = int(terrain_system.get_master_damage_delta(attacker))
	var applied_damage := maxi(0, damage + bonus + terrain_delta)
	master_hp[side] = maxi(0, get_master_hp(side) - applied_damage)
	battle_stats.record_master_damage(attacker, applied_damage)
	pass  # EventBus emit moved to BattleScreen
	return applied_damage

func get_unit_attack(unit: Dictionary) -> int:
	var side := str(unit.get("side", ""))
	var attack := int(unit.get("attack", 0))
	attack += int(terrain_system.get_attack_delta(unit))
	attack += get_side_attack_delta(side, unit)
	return maxi(0, attack)

func get_movement_cost(unit: Dictionary, column: int, row: int) -> int:
	return terrain_system.get_movement_cost(unit, column, row)

func get_unit_move(unit: Dictionary) -> int:
	var side := str(unit.get("side", ""))
	var move_value := int(unit.get("move", 0))
	move_value += get_side_move_delta(side, unit)
	return maxi(0, move_value)

func add_side_turn_effect(side: String, effect_id: String, effect_data: Dictionary) -> void:
	if not side_turn_effects.has(side):
		side_turn_effects[side] = {}
	side_turn_effects[side][effect_id] = effect_data.duplicate(true)

func clear_side_turn_effects(side: String) -> void:
	if side_turn_effects.has(side):
		side_turn_effects[side].clear()

func get_side_attack_delta(side: String, unit: Dictionary = {}) -> int:
	var effects: Dictionary = side_turn_effects.get(side, {})
	var attack_delta := 0
	for effect: Dictionary in effects.values():
		if not _side_effect_applies_to_unit(effect, unit):
			continue
		attack_delta += int(effect.get("attack_delta", 0))
	return attack_delta

func get_side_move_delta(side: String, unit: Dictionary = {}) -> int:
	var effects: Dictionary = side_turn_effects.get(side, {})
	var move_delta := 0
	for effect: Dictionary in effects.values():
		if not _side_effect_applies_to_unit(effect, unit):
			continue
		move_delta += int(effect.get("move_delta", 0))
	return move_delta

func remove_unit(unit_id: String) -> bool:
	if not placed_units.has(unit_id):
		return false

	var removed: bool = board.remove_unit(unit_id)
	placed_units.erase(unit_id)
	return removed

func _apply_adjacent_guard_reduction(target_unit: Dictionary, damage: int, damage_type: String) -> int:
	if damage <= 0 or damage_type == DamageSystemScript.DAMAGE_TRUE:
		return damage
	var target_side := str(target_unit.get("side", ""))
	var target_column := int(target_unit.get("column", 0))
	var target_row := int(target_unit.get("row", 0))
	var reduction := 0
	for ally: Dictionary in get_units_by_side(target_side):
		if str(ally.get("instance_id", "")) == str(target_unit.get("instance_id", "")):
			continue
		if int(ally.get("hp", 0)) <= 0:
			continue
		if not ally.get("skill_ids", []).has("zhangfei_guard"):
			continue
		var distance := absi(int(ally.get("column", 0)) - target_column) + absi(int(ally.get("row", 0)) - target_row)
		if distance == 1:
			reduction = maxi(reduction, _get_skill_param_int("zhangfei_guard", "damage_reduction", 0))
	return maxi(0, damage - reduction)

func _get_skill_param_int(skill_id: String, param_name: String, default_value: int = 0) -> int:
	for skill_def: Dictionary in get_skill_defs():
		if str(skill_def.get("id", "")) != skill_id:
			continue
		var params: Dictionary = skill_def.get("params", {})
		return int(params.get(param_name, default_value))
	return default_value

func _side_effect_applies_to_unit(effect: Dictionary, unit: Dictionary) -> bool:
	var required_class := str(effect.get("class", ""))
	if required_class.is_empty():
		return true
	if unit.is_empty():
		return false
	return str(unit.get("class", "")) == required_class

func _get_master_max_hp(level: int) -> int:
	var levels: Array = DataLoaderScript.data.get("master_levels", [])
	for level_def: Dictionary in levels:
		if int(level_def.get("level", 0)) == level:
			return int(level_def.get("max_hp", 0))
	push_error("Missing master level data for level %d." % level)
	return 0
