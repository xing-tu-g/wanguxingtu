extends RefCounted
class_name BattleStats

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"

var deployments: Dictionary = {}
var unit_damage_dealt: Dictionary = {}
var master_damage_dealt: Dictionary = {}
var units_defeated: Dictionary = {}


func reset() -> void:
	deployments = _side_counter()
	unit_damage_dealt = _side_counter()
	master_damage_dealt = _side_counter()
	units_defeated = _side_counter()


func record_deployment(side: String) -> void:
	_increment(deployments, side, 1)


func record_unit_damage(attacker: Variant, target_unit: Dictionary, damage: int, was_defeated: bool) -> void:
	if damage <= 0:
		return
	var side := _attacker_side(attacker)
	if side.is_empty():
		return
	_increment(unit_damage_dealt, side, damage)
	if was_defeated:
		_increment(units_defeated, side, 1)


func record_master_damage(attacker: Variant, damage: int) -> void:
	if damage <= 0:
		return
	var side := _attacker_side(attacker)
	if side.is_empty():
		return
	_increment(master_damage_dealt, side, damage)


func snapshot() -> Dictionary:
	return {
		"deployments": deployments.duplicate(true),
		"unit_damage_dealt": unit_damage_dealt.duplicate(true),
		"master_damage_dealt": master_damage_dealt.duplicate(true),
		"units_defeated": units_defeated.duplicate(true),
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


func _attacker_side(attacker: Variant) -> String:
	if attacker is Dictionary:
		return str(attacker.get("side", ""))
	return ""
