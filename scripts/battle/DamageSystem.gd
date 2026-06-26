extends RefCounted
class_name DamageSystem

const DAMAGE_PHYSICAL := "physical"
const DAMAGE_MAGIC := "magic"
const DAMAGE_TRUE := "true"


static func calculate_damage(raw_damage: int, damage_type: String, target: Dictionary) -> int:
	var damage := maxi(0, raw_damage)
	match damage_type:
		DAMAGE_PHYSICAL:
			damage -= int(target.get("physical_block", 0))
		DAMAGE_MAGIC:
			damage -= int(target.get("magic_block", 0))
		DAMAGE_TRUE:
			pass
		_:
			damage -= int(target.get("physical_block", 0))
	return maxi(0, damage)


static func calculate_unit_damage(raw_damage: int, damage_type: String, target: Dictionary, terrain_system = null) -> int:
	var damage := calculate_damage(raw_damage, damage_type, target)
	if terrain_system != null:
		damage += int(terrain_system.get_incoming_damage_delta(target))
	return maxi(0, damage)
