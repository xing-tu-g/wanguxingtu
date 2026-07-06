extends RefCounted
class_name FactionEnergySystem

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const STATUS_ATTACK_BUFF := "attack_buff"
const STATUS_SHIELD := "shield"

const ENERGY_HEROES := {
	"shu": {
		"producer": "zhaoyun",
		"amplifier": "zhugeliang",
	},
	"wei": {
		"producer": "caocao",
		"amplifier": "xunyu",
	},
	"wu": {
		"producer": "sunquan",
		"amplifier": "zhouyu",
	},
	"qun": {
		"producer": "yuanshao",
		"amplifier": "jiaxu",
	},
}

var turn_state: Dictionary = {}


func reset() -> void:
	turn_state = {
		SIDE_LEFT: _new_side_turn_state(),
		SIDE_RIGHT: _new_side_turn_state(),
	}


func start_side_turn(state, side: String) -> Array:
	turn_state[side] = _new_side_turn_state()
	var results: Array = []
	if _side_has_hero(state, side, "caocao") and state.get_units_by_side(side).size() >= state.get_enemy_units(side).size():
		results.append(_grant_energy(state, side, "wei", "condition", "caocao", 1))
	return results


func on_star_spent(state, side: String, amount: int) -> Array:
	if amount < 5 or not _side_has_hero(state, side, "xunyu"):
		return []
	var side_state: Dictionary = turn_state.get(side, _new_side_turn_state())
	if bool(side_state.get("xunyu_refunded", false)):
		return []
	side_state["xunyu_refunded"] = true
	turn_state[side] = side_state
	return [_grant_energy(state, side, "wei", "refund", "xunyu", 1, false)]


func on_skill_triggered(state, source_unit: Dictionary, skill_def: Dictionary) -> Array:
	var side := str(source_unit.get("side", ""))
	if side.is_empty() or not _side_has_hero(state, side, "sunquan"):
		return []
	var side_state: Dictionary = turn_state.get(side, _new_side_turn_state())
	side_state["wu_skill_count"] = int(side_state.get("wu_skill_count", 0)) + 1
	turn_state[side] = side_state
	if int(side_state.get("wu_skill_count", 0)) % 2 != 0:
		return []
	return [_grant_energy(state, side, "wu", "skill", "sunquan", 1)]


func on_unit_defeated(state, defeated_unit: Dictionary, attacker: Variant) -> Array:
	var results: Array = []
	var defeated_side := str(defeated_unit.get("side", ""))
	if defeated_side.is_empty():
		return results

	var attacker_side := ""
	if attacker is Dictionary:
		attacker_side = str(attacker.get("side", ""))

	if not attacker_side.is_empty() and attacker_side != defeated_side:
		if _side_has_hero(state, attacker_side, "zhaoyun"):
			var attacker_state: Dictionary = turn_state.get(attacker_side, _new_side_turn_state())
			if not bool(attacker_state.get("shu_kill_granted", false)):
				attacker_state["shu_kill_granted"] = true
				turn_state[attacker_side] = attacker_state
				results.append(_grant_energy(state, attacker_side, "shu", "kill", "zhaoyun", 1))
		if _side_has_hero(state, attacker_side, "jiaxu"):
			var jiaxu_state: Dictionary = turn_state.get(attacker_side, _new_side_turn_state())
			if not bool(jiaxu_state.get("jiaxu_amplified", false)):
				jiaxu_state["jiaxu_amplified"] = true
				turn_state[attacker_side] = jiaxu_state
				results.append(_apply_jiaxu_amplifier(state, attacker_side))

	if _side_has_hero(state, defeated_side, "yuanshao") or str(defeated_unit.get("hero_id", "")) == "yuanshao":
		var defeated_state: Dictionary = turn_state.get(defeated_side, _new_side_turn_state())
		if not bool(defeated_state.get("qun_death_granted", false)):
			defeated_state["qun_death_granted"] = true
			turn_state[defeated_side] = defeated_state
			results.append(_grant_energy(state, defeated_side, "qun", "death", "yuanshao", 1))
	return results


func validate_energy_hero_limits() -> Dictionary:
	var problems: Array[String] = []
	for faction in ENERGY_HEROES.keys():
		var row: Dictionary = ENERGY_HEROES.get(faction, {})
		var seen: Array[String] = []
		for role in ["producer", "amplifier"]:
			var hero_id := str(row.get(role, ""))
			if hero_id.is_empty():
				continue
			if seen.has(hero_id):
				problems.append("%s uses %s more than once" % [faction, hero_id])
			seen.append(hero_id)
		if seen.size() > 2:
			problems.append("%s has more than 2 faction energy heroes" % faction)
	return {"ok": problems.is_empty(), "problems": problems}


func energy_heroes() -> Dictionary:
	return ENERGY_HEROES.duplicate(true)


func _grant_energy(state, side: String, faction: String, source: String, hero_id: String, amount: int, trigger_amplifier: bool = true) -> Dictionary:
	var before: int = state.get_star_power(side)
	var after: int = state.change_star_power(side, amount)
	var gained: int = after - before
	var result := {
		"ok": gained > 0,
		"side": side,
		"faction": faction,
		"source": source,
		"hero_id": hero_id,
		"amount": gained,
		"before": before,
		"after": after,
		"amplifier_results": [],
	}
	if gained > 0:
		state.battle_stats.record_faction_energy(side, faction, source, hero_id, gained)
		if trigger_amplifier:
			result["amplifier_results"] = _on_faction_energy_gained(state, side, faction)
	return result


func _on_faction_energy_gained(state, side: String, faction: String) -> Array:
	var side_state: Dictionary = turn_state.get(side, _new_side_turn_state())
	if bool(side_state.get("energy_gain_amplified", false)):
		return []
	side_state["energy_gain_amplified"] = true
	turn_state[side] = side_state
	match faction:
		"shu":
			if _side_has_hero(state, side, "zhugeliang"):
				return [_apply_zhugeliang_amplifier(state, side)]
		"wu":
			if _side_has_hero(state, side, "zhouyu"):
				return [_apply_zhouyu_amplifier(state, side)]
	return []


func _apply_zhugeliang_amplifier(state, side: String) -> Dictionary:
	var target := _nearest_ally(state, side)
	if target.is_empty():
		return {"ok": false, "reason": "missing_ally", "hero_id": "zhugeliang"}
	_add_status_value(target, STATUS_ATTACK_BUFF, 1, 1, "zhugeliang")
	return {
		"ok": true,
		"hero_id": "zhugeliang",
		"effect": "attack_buff",
		"target_id": str(target.get("instance_id", "")),
		"value": 1,
	}


func _apply_zhouyu_amplifier(state, side: String) -> Dictionary:
	var source := _hero_unit(state, side, "zhouyu")
	var target := _nearest_enemy(state, side)
	if source.is_empty() or target.is_empty():
		return {"ok": false, "reason": "missing_target", "hero_id": "zhouyu"}
	var damage: int = state.apply_damage_to_unit(target, 1, "true", source)
	return {
		"ok": damage > 0,
		"hero_id": "zhouyu",
		"effect": "burn_damage",
		"target_id": str(target.get("instance_id", "")),
		"damage": damage,
	}


func _apply_jiaxu_amplifier(state, side: String) -> Dictionary:
	var target := _nearest_ally(state, side)
	if target.is_empty():
		return {"ok": false, "reason": "missing_ally", "hero_id": "jiaxu"}
	_add_status_value(target, STATUS_SHIELD, 1, 1, "jiaxu")
	return {
		"ok": true,
		"hero_id": "jiaxu",
		"effect": "shield",
		"target_id": str(target.get("instance_id", "")),
		"value": 1,
	}


func _add_status_value(unit: Dictionary, status_id: String, value: int, duration_turns: int, source_hero_id: String) -> void:
	var statuses: Dictionary = unit.get("statuses", {})
	var current: Dictionary = statuses.get(status_id, {
		"id": status_id,
		"duration_turns": duration_turns,
		"source_unit_id": source_hero_id,
		"value": 0,
	})
	current["value"] = int(current.get("value", 0)) + value
	current["duration_turns"] = maxi(int(current.get("duration_turns", 0)), duration_turns)
	statuses[status_id] = current
	unit["statuses"] = statuses


func _side_has_hero(state, side: String, hero_id: String) -> bool:
	return not _hero_unit(state, side, hero_id).is_empty()


func _hero_unit(state, side: String, hero_id: String) -> Dictionary:
	for unit: Dictionary in state.get_units_by_side(side):
		if str(unit.get("hero_id", "")) == hero_id and int(unit.get("hp", 0)) > 0:
			return unit
	return {}


func _nearest_ally(state, side: String) -> Dictionary:
	var allies: Array = state.get_units_by_side(side)
	return _lowest_entry_unit(allies)


func _nearest_enemy(state, side: String) -> Dictionary:
	var enemies: Array = state.get_enemy_units(side)
	return _lowest_entry_unit(enemies)


func _lowest_entry_unit(units: Array) -> Dictionary:
	var best: Dictionary = {}
	for unit: Dictionary in units:
		if int(unit.get("hp", 0)) <= 0:
			continue
		if best.is_empty() or int(unit.get("entry_order", 999999)) < int(best.get("entry_order", 999999)):
			best = unit
	return best


func _new_side_turn_state() -> Dictionary:
	return {
		"shu_kill_granted": false,
		"qun_death_granted": false,
		"wu_skill_count": 0,
		"xunyu_refunded": false,
		"jiaxu_amplified": false,
		"energy_gain_amplified": false,
	}
