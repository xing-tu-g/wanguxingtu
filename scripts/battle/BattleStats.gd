extends RefCounted
class_name BattleStats

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"

var deployments: Dictionary = {}
var unit_damage_dealt: Dictionary = {}
var master_damage_dealt: Dictionary = {}
var units_defeated: Dictionary = {}
var hero_damage_dealt: Dictionary = {}
var hero_healing_done: Dictionary = {}
var hero_damage_taken: Dictionary = {}
var skill_triggers: Dictionary = {}
var faction_energy_gained: Dictionary = {}
var faction_energy_sources: Dictionary = {}
var faction_energy_heroes: Dictionary = {}


func reset() -> void:
	deployments = _side_counter()
	unit_damage_dealt = _side_counter()
	master_damage_dealt = _side_counter()
	units_defeated = _side_counter()
	hero_damage_dealt = {}
	hero_healing_done = {}
	hero_damage_taken = {}
	skill_triggers = {}
	faction_energy_gained = {}
	faction_energy_sources = {}
	faction_energy_heroes = {}


func record_deployment(side: String) -> void:
	_increment(deployments, side, 1)


func record_unit_damage(attacker: Variant, target_unit: Dictionary, damage: int, was_defeated: bool) -> void:
	if damage <= 0:
		return
	var side := _attacker_side(attacker)
	if side.is_empty():
		return
	_increment(unit_damage_dealt, side, damage)
	_increment(hero_damage_dealt, _unit_hero_id(attacker), damage)
	_increment(hero_damage_taken, _unit_hero_id(target_unit), damage)
	if was_defeated:
		_increment(units_defeated, side, 1)


func record_master_damage(attacker: Variant, damage: int) -> void:
	if damage <= 0:
		return
	var side := _attacker_side(attacker)
	if side.is_empty():
		return
	_increment(master_damage_dealt, side, damage)
	_increment(hero_damage_dealt, _unit_hero_id(attacker), damage)


func record_heal(source_unit: Variant, amount: int) -> void:
	if amount <= 0:
		return
	_increment(hero_healing_done, _unit_hero_id(source_unit), amount)


func record_skill_trigger(source_unit: Variant, skill_id: String) -> void:
	if skill_id.is_empty():
		return
	_increment(skill_triggers, skill_id, 1)


func record_faction_energy(side: String, faction: String, source: String, hero_id: String, amount: int) -> void:
	if amount <= 0:
		return
	_increment_nested(faction_energy_gained, faction, side, amount)
	_increment(faction_energy_sources, source, amount)
	_increment(faction_energy_heroes, hero_id, amount)


func snapshot() -> Dictionary:
	return {
		"deployments": deployments.duplicate(true),
		"unit_damage_dealt": unit_damage_dealt.duplicate(true),
		"master_damage_dealt": master_damage_dealt.duplicate(true),
		"units_defeated": units_defeated.duplicate(true),
		"hero_damage_dealt": hero_damage_dealt.duplicate(true),
		"hero_healing_done": hero_healing_done.duplicate(true),
		"hero_damage_taken": hero_damage_taken.duplicate(true),
		"skill_triggers": skill_triggers.duplicate(true),
		"faction_energy_gained": faction_energy_gained.duplicate(true),
		"faction_energy_sources": faction_energy_sources.duplicate(true),
		"faction_energy_heroes": faction_energy_heroes.duplicate(true),
	}


func _side_counter() -> Dictionary:
	return {
		SIDE_LEFT: 0,
		SIDE_RIGHT: 0,
	}


func _increment(counter: Dictionary, side: String, amount: int) -> void:
	if not counter.has(side):
		counter[side] = 0
	counter[side] = int(counter.get(side, 0)) + amount


func _increment_nested(counter: Dictionary, key: String, field: String, amount: int) -> void:
	if key.is_empty() or field.is_empty():
		return
	if not counter.has(key):
		counter[key] = {}
	var row: Dictionary = counter[key]
	row[field] = int(row.get(field, 0)) + amount
	counter[key] = row


func _attacker_side(attacker: Variant) -> String:
	if attacker is Dictionary:
		return str(attacker.get("side", ""))
	return ""


func _unit_hero_id(unit: Variant) -> String:
	if unit is Dictionary:
		return str(unit.get("hero_id", unit.get("instance_id", "")))
	return ""
