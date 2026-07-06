extends RefCounted
class_name SkillSystem

const AttackShapeSystemScript: GDScript = preload("res://scripts/battle/AttackShapeSystem.gd")

const TRIGGER_TURN_START := "turn_start"
const TRIGGER_ATTACK_HIT := "attack_hit"
const TRIGGER_DEPLOY := "deploy"
const STATUS_BURN := "burn"
const STATUS_SHIELD := "shield"
const STATUS_STUN := "stun"
const STATUS_ATTACK_BUFF := "attack_buff"
const STATUS_SLOW := "slow"


static func trigger_event(state, trigger: String, context: Dictionary = {}) -> Array:
	var results: Array = []
	var source_units: Array = _get_source_units(state, trigger, context)
	for source_unit: Dictionary in source_units:
		for skill_id in source_unit.get("skill_ids", []):
			var skill_def: Dictionary = _get_skill_def(state, str(skill_id))
			if skill_def.is_empty() or str(skill_def.get("trigger", "")) != trigger:
				continue
			if _is_skill_on_cooldown(source_unit, str(skill_id)):
				continue
			var skill_result: Dictionary = _apply_skill(state, skill_def, source_unit, context)
			if bool(skill_result.get("ok", false)):
				state.battle_stats.record_skill_trigger(source_unit, str(skill_def.get("id", "")))
				if state.has_method("on_skill_triggered"):
					skill_result["faction_energy_results"] = state.on_skill_triggered(source_unit, skill_def)
				_start_cooldown(source_unit, skill_def)
			results.append(skill_result)
	return results


static func process_end_turn_statuses(state, side: String = "") -> Array:
	var results: Array = []
	var units: Array = state.placed_units.values()
	for unit: Dictionary in units:
		if side != "" and str(unit.get("side", "")) != side:
			continue
		if int(unit.get("hp", 0)) <= 0:
			continue

		var statuses: Dictionary = unit.get("statuses", {})
		if statuses.has(STATUS_BURN):
			var burn_status: Dictionary = statuses[STATUS_BURN]
			var damage := int(burn_status.get("value", 0))
			var applied_damage: int = state.apply_damage_to_unit(unit, damage, "true")
			results.append({
				"status": STATUS_BURN,
				"target_id": str(unit.get("instance_id", "")),
				"damage": applied_damage,
			})
			if state.placed_units.has(str(unit.get("instance_id", ""))):
				_remove_status(unit, STATUS_BURN)
		_tick_status_durations(unit)
		_tick_skill_cooldowns(unit)
	return results


static func _get_source_units(state, trigger: String, context: Dictionary) -> Array:
	if trigger == TRIGGER_TURN_START:
		return state.get_units_by_side(str(context.get("side", state.current_side)))

	var source_unit = context.get("source_unit", {})
	if source_unit is Dictionary and not source_unit.is_empty():
		return [source_unit]
	return []


static func _apply_skill(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	match str(skill_def.get("effect_type", "")):
		"damage":
			return _apply_damage(state, skill_def, source_unit, context)
		"area_damage":
			return _apply_area_damage(state, skill_def, source_unit, context)
		"heal":
			return _apply_heal(state, skill_def, source_unit, context)
		"shield":
			return _apply_named_status(state, skill_def, source_unit, context, STATUS_SHIELD)
		"stun":
			return _apply_named_status(state, skill_def, source_unit, context, STATUS_STUN)
		"attack_buff":
			return _apply_named_status(state, skill_def, source_unit, context, STATUS_ATTACK_BUFF)
		"slow":
			return _apply_named_status(state, skill_def, source_unit, context, STATUS_SLOW)
		"modify_stat":
			return _apply_modify_stat(skill_def, source_unit)
		"apply_status":
			return _apply_status(skill_def, context)
		"summon":
			return _apply_summon(state, skill_def, source_unit)
		"bonus_damage":
			return _apply_bonus_damage(state, skill_def, source_unit, context)
		"side_move":
			return _apply_side_move(state, skill_def, source_unit)
		"enemy_attack_delta":
			return _apply_enemy_attack_delta(state, skill_def, source_unit)
		"adjacent_modify":
			return _apply_adjacent_modify(state, skill_def, source_unit)
	return {"ok": false, "reason": "unknown_effect_type", "skill_id": str(skill_def.get("id", ""))}


static func _apply_damage(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	var target_unit: Dictionary = _resolve_target_unit(state, skill_def, source_unit, context)
	if target_unit.is_empty():
		return {"ok": false, "reason": "missing_target", "skill_id": str(skill_def.get("id", ""))}
	var params: Dictionary = skill_def.get("params", {})
	var raw_damage := int(params.get("damage", params.get("value", 0)))
	var damage_type := str(params.get("damage_type", source_unit.get("damage_type", "physical")))
	var applied_damage: int = state.apply_damage_to_unit(target_unit, raw_damage, damage_type, source_unit)
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"effect_type": "damage",
		"target_id": str(target_unit.get("instance_id", "")),
		"damage": applied_damage,
		"damage_type": damage_type,
	}


static func _apply_area_damage(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	var center: Dictionary = _resolve_target_unit(state, skill_def, source_unit, context)
	if center.is_empty():
		return {"ok": false, "reason": "missing_target", "skill_id": str(skill_def.get("id", ""))}
	var params: Dictionary = skill_def.get("params", {})
	var radius := int(params.get("radius", 1))
	var attack_shape := str(skill_def.get("attack_shape", params.get("attack_shape", AttackShapeSystemScript.SHAPE_CROSS)))
	var raw_damage := int(params.get("damage", params.get("value", 0)))
	var damage_type := str(params.get("damage_type", source_unit.get("damage_type", "physical")))
	var damaged: Array = []
	for enemy: Dictionary in AttackShapeSystemScript.select_area_units(center, state.get_enemy_units(str(source_unit.get("side", ""))), attack_shape, radius):
		var applied_damage: int = state.apply_damage_to_unit(enemy, raw_damage, damage_type, source_unit)
		damaged.append({"target_id": str(enemy.get("instance_id", "")), "damage": applied_damage})
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"effect_type": "area_damage",
		"attack_shape": attack_shape,
		"damaged": damaged,
		"damage_type": damage_type,
	}


static func _apply_heal(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	var targets: Array = _resolve_friendly_targets(state, skill_def, source_unit, context)
	if targets.is_empty():
		return {"ok": false, "reason": "missing_target", "skill_id": str(skill_def.get("id", ""))}
	var params: Dictionary = skill_def.get("params", {})
	var amount := int(params.get("heal", params.get("value", 0)))
	var healed: Array = []
	var total_heal := 0
	for target_unit: Dictionary in targets:
		var before_hp := int(target_unit.get("hp", 0))
		target_unit["hp"] = mini(int(target_unit.get("max_hp", before_hp)), before_hp + amount)
		var actual_heal := int(target_unit.get("hp", 0)) - before_hp
		total_heal += actual_heal
		healed.append({
			"target_id": str(target_unit.get("instance_id", "")),
			"heal": actual_heal,
		})
	state.battle_stats.record_heal(source_unit, total_heal)
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"effect_type": "heal",
		"healed": healed,
	}


static func _apply_named_status(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary, status_id: String) -> Dictionary:
	var target_unit: Dictionary = _resolve_target_unit(state, skill_def, source_unit, context)
	if status_id in [STATUS_SHIELD, STATUS_ATTACK_BUFF]:
		target_unit = _resolve_friendly_target(state, skill_def, source_unit, context)
	if target_unit.is_empty():
		return {"ok": false, "reason": "missing_target", "skill_id": str(skill_def.get("id", ""))}
	var params: Dictionary = skill_def.get("params", {})
	var value := int(params.get("value", params.get("amount", 0)))
	if status_id == STATUS_STUN:
		value = maxi(value, 1)
	var statuses: Dictionary = target_unit.get("statuses", {})
	statuses[status_id] = {
		"id": status_id,
		"duration_turns": int(skill_def.get("duration_turns", params.get("duration_turns", 1))),
		"source_unit_id": str(source_unit.get("instance_id", "")),
		"value": value,
	}
	target_unit["statuses"] = statuses
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"effect_type": status_id,
		"target_id": str(target_unit.get("instance_id", "")),
		"status_id": status_id,
		"value": value,
	}


static func _apply_modify_stat(skill_def: Dictionary, source_unit: Dictionary) -> Dictionary:
	var params: Dictionary = skill_def.get("params", {})
	var attack_delta := int(params.get("attack", 0))
	var max_hp_delta := int(params.get("max_hp", 0))
	var heal_amount := int(params.get("heal", 0))

	source_unit["attack"] = int(source_unit.get("attack", 0)) + attack_delta
	source_unit["max_hp"] = int(source_unit.get("max_hp", 0)) + max_hp_delta
	var before_hp := int(source_unit.get("hp", 0))
	source_unit["hp"] = mini(int(source_unit.get("max_hp", 0)), before_hp + heal_amount)

	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"target_id": str(source_unit.get("instance_id", "")),
		"attack_delta": attack_delta,
		"max_hp_delta": max_hp_delta,
		"healed": int(source_unit.get("hp", 0)) - before_hp,
	}


static func _apply_status(skill_def: Dictionary, context: Dictionary) -> Dictionary:
	var target_unit = context.get("target_unit", {})
	if not (target_unit is Dictionary) or target_unit.is_empty() or int(target_unit.get("hp", 0)) <= 0:
		return {"ok": false, "reason": "missing_target", "skill_id": str(skill_def.get("id", ""))}

	var params: Dictionary = skill_def.get("params", {})
	var status_id := str(params.get("status_id", STATUS_BURN))
	var statuses: Dictionary = target_unit.get("statuses", {})
	if statuses.has(status_id):
		return {"ok": true, "reason": "status_already_present", "skill_id": str(skill_def.get("id", ""))}

	statuses[status_id] = {
		"id": status_id,
		"duration_turns": int(skill_def.get("duration_turns", 1)),
		"source_unit_id": str(context.get("source_unit", {}).get("instance_id", "")),
		"value": int(params.get("value", 0)),
	}
	target_unit["statuses"] = statuses
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"target_id": str(target_unit.get("instance_id", "")),
		"status_id": status_id,
	}


static func _apply_summon(state, skill_def: Dictionary, source_unit: Dictionary) -> Dictionary:
	var params: Dictionary = skill_def.get("params", {})
	var summon_id := str(params.get("unit_id", ""))
	var max_count := int(params.get("count", 0))
	var summon_def: Dictionary = state.get_hero_def(summon_id)
	if summon_def.is_empty():
		return {"ok": false, "reason": "unknown_summon", "skill_id": str(skill_def.get("id", ""))}

	var summoned: Array = []
	for cell: Vector2i in AttackShapeSystemScript.adjacent_cells(source_unit):
		if summoned.size() >= max_count:
			break
		if not state.board.is_in_bounds(cell.x, cell.y) or state.board.is_occupied(cell.x, cell.y):
			continue

		var unit_data: Dictionary = state.build_unit_data(summon_id, summon_def)
		unit_data["is_summon"] = true
		unit_data["summoner_id"] = str(source_unit.get("instance_id", ""))
		var summon_result: Dictionary = state.create_unit_instance(unit_data, str(source_unit.get("side", "")), cell.x, cell.y)
		if summon_result.ok:
			summoned.append(summon_result.unit)
			var stats: Dictionary = source_unit.get("stats", {})
			stats["summons_created"] = int(stats.get("summons_created", 0)) + 1
			source_unit["stats"] = stats

	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"summoned_count": summoned.size(),
		"summoned": summoned,
	}


static func _apply_bonus_damage(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	var target_unit = context.get("target_unit", {})
	if not (target_unit is Dictionary) or target_unit.is_empty() or int(target_unit.get("hp", 0)) <= 0:
		return {"ok": false, "reason": "missing_target", "skill_id": str(skill_def.get("id", ""))}
	var params: Dictionary = skill_def.get("params", {})
	var raw_damage := int(params.get("damage", 0))
	if bool(params.get("require_backstab", false)) and not AttackShapeSystemScript.is_backstab_target(source_unit, target_unit):
		raw_damage = int(params.get("fallback_damage", 0))
		if raw_damage <= 0:
			return {"ok": false, "reason": "backstab_required", "skill_id": str(skill_def.get("id", ""))}
	var damage_type := str(params.get("damage_type", "physical"))
	var applied_damage: int = state.apply_damage_to_unit(target_unit, raw_damage, damage_type, source_unit)
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"target_id": str(target_unit.get("instance_id", "")),
		"bonus_damage": applied_damage,
		"damage_type": damage_type,
	}


static func _apply_side_move(state, skill_def: Dictionary, source_unit: Dictionary) -> Dictionary:
	var params: Dictionary = skill_def.get("params", {})
	var side := str(source_unit.get("side", ""))
	var move_delta := int(params.get("move_delta", 0))
	state.add_side_turn_effect(side, str(skill_def.get("id", "")), {
		"move_delta": move_delta,
		"duration_turns": int(skill_def.get("duration_turns", 1)),
	})
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"side": side,
		"move_delta": move_delta,
	}


static func _apply_enemy_attack_delta(state, skill_def: Dictionary, source_unit: Dictionary) -> Dictionary:
	var params: Dictionary = skill_def.get("params", {})
	var target_side: String = state.get_enemy_side(str(source_unit.get("side", "")))
	var attack_delta := int(params.get("attack_delta", 0))
	state.add_side_turn_effect(target_side, str(skill_def.get("id", "")), {
		"attack_delta": attack_delta,
		"duration_turns": int(skill_def.get("duration_turns", 1)),
	})
	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"side": target_side,
		"attack_delta": attack_delta,
	}


static func _apply_adjacent_modify(state, skill_def: Dictionary, source_unit: Dictionary) -> Dictionary:
	var params: Dictionary = skill_def.get("params", {})
	var heal_amount := int(params.get("heal", 0))
	var healed_count: int = 0
	var total_heal := 0
	for unit: Dictionary in _resolve_friendly_targets(state, {"target": "adjacent_allies"}, source_unit, {}):
		var before_hp := int(unit.get("hp", 0))
		unit["hp"] = mini(int(unit.get("max_hp", 0)), before_hp + heal_amount)
		var actual_heal := int(unit.get("hp", 0)) - before_hp
		total_heal += actual_heal
		if actual_heal > 0:
			healed_count += 1
	state.battle_stats.record_heal(source_unit, total_heal)

	return {
		"ok": true,
		"skill_id": str(skill_def.get("id", "")),
		"source_id": str(source_unit.get("instance_id", "")),
		"healed_count": healed_count,
	}


static func _remove_status(unit: Dictionary, status_id: String) -> void:
	var statuses: Dictionary = unit.get("statuses", {})
	statuses.erase(status_id)
	unit["statuses"] = statuses


static func _tick_status_durations(unit: Dictionary) -> void:
	var statuses = unit.get("statuses", {})
	if not (statuses is Dictionary):
		unit["statuses"] = {}
		return
	for status_id in statuses.keys().duplicate():
		if status_id == STATUS_BURN:
			continue
		var status: Dictionary = statuses.get(status_id, {})
		var duration := int(status.get("duration_turns", 1))
		if duration <= 0:
			continue
		duration -= 1
		if duration <= 0:
			statuses.erase(status_id)
		else:
			status["duration_turns"] = duration
			statuses[status_id] = status
	unit["statuses"] = statuses


static func _tick_skill_cooldowns(unit: Dictionary) -> void:
	var cooldowns = unit.get("skill_cooldowns", {})
	if not (cooldowns is Dictionary):
		unit["skill_cooldowns"] = {}
		return
	for skill_id in cooldowns.keys().duplicate():
		var turns_left := int(cooldowns.get(skill_id, 0)) - 1
		if turns_left <= 0:
			cooldowns.erase(skill_id)
		else:
			cooldowns[skill_id] = turns_left
	unit["skill_cooldowns"] = cooldowns


static func _is_skill_on_cooldown(source_unit: Dictionary, skill_id: String) -> bool:
	var cooldowns = source_unit.get("skill_cooldowns", {})
	return cooldowns is Dictionary and int(cooldowns.get(skill_id, 0)) > 0


static func _start_cooldown(source_unit: Dictionary, skill_def: Dictionary) -> void:
	var cooldown := int(skill_def.get("cooldown_turns", skill_def.get("cooldown", 0)))
	if cooldown <= 0:
		return
	var cooldowns = source_unit.get("skill_cooldowns", {})
	if not (cooldowns is Dictionary):
		cooldowns = {}
	cooldowns[str(skill_def.get("id", ""))] = cooldown
	source_unit["skill_cooldowns"] = cooldowns


static func _resolve_target_unit(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	var target_rule := str(skill_def.get("target", "attack_target"))
	if target_rule in ["self", "source"]:
		return source_unit
	var target_unit = context.get("target_unit", {})
	if target_unit is Dictionary and not target_unit.is_empty() and int(target_unit.get("hp", 0)) > 0:
		return target_unit
	if target_rule in ["nearest_enemy", "enemy"] and state != null:
		var enemies: Array = state.get_enemy_units(str(source_unit.get("side", "")))
		var shape := str(skill_def.get("attack_shape", AttackShapeSystemScript.SHAPE_ALL_ENEMIES))
		var selected: Array = AttackShapeSystemScript.select_units(source_unit, enemies, shape, 99)
		if not selected.is_empty():
			return selected[0]
		return {}
	return {}


static func _resolve_friendly_target(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Dictionary:
	var target_rule := str(skill_def.get("target", "self"))
	if target_rule in ["self", "source", "self_side"]:
		return source_unit
	var target_unit = context.get("target_unit", {})
	if target_unit is Dictionary and not target_unit.is_empty() and str(target_unit.get("side", "")) == str(source_unit.get("side", "")):
		return target_unit
	if state != null:
		var allies: Array = state.get_units_by_side(str(source_unit.get("side", "")))
		var lowest: Dictionary = {}
		var lowest_hp_ratio := 2.0
		for ally: Dictionary in allies:
			if int(ally.get("hp", 0)) <= 0:
				continue
			var ratio := float(ally.get("hp", 0)) / float(maxi(1, int(ally.get("max_hp", 1))))
			if ratio < lowest_hp_ratio:
				lowest_hp_ratio = ratio
				lowest = ally
		return lowest
	return {}


static func _resolve_friendly_targets(state, skill_def: Dictionary, source_unit: Dictionary, context: Dictionary) -> Array:
	var target_rule := str(skill_def.get("target", "self"))
	if target_rule == "adjacent_allies" and state != null:
		var targets: Array = []
		for cell: Vector2i in AttackShapeSystemScript.adjacent_cells(source_unit):
			var unit: Dictionary = state.get_unit_at(cell.x, cell.y)
			if unit.is_empty() or int(unit.get("hp", 0)) <= 0:
				continue
			if str(unit.get("side", "")) == str(source_unit.get("side", "")):
				targets.append(unit)
		return targets
	if target_rule == "all_allies" and state != null:
		return state.get_units_by_side(str(source_unit.get("side", "")))
	var target := _resolve_friendly_target(state, skill_def, source_unit, context)
	return [] if target.is_empty() else [target]


static func _get_skill_def(state, skill_id: String) -> Dictionary:
	for skill_def: Dictionary in state.get_skill_defs():
		if str(skill_def.get("id", "")) == skill_id:
			return skill_def
	return {}
