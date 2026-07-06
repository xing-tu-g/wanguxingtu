extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const TargetingSystemScript: GDScript = preload("res://scripts/battle/TargetingSystem.gd")
const AttackShapeSystemScript: GDScript = preload("res://scripts/battle/AttackShapeSystem.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")

const ALLOWED_CLASSES := ["mage", "warrior", "tank", "assassin", "archer"]


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()

	_check_forward_only_movement(failures)
	_check_basic_attack_shapes(failures)
	_check_assassin_backstab(failures)
	_check_skill_attack_shape(failures)
	_check_roster_classes_and_skill_numbers(failures)

	if failures.is_empty():
		print("M87 combat refactor core checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_forward_only_movement(failures: Array[String]) -> void:
	var left_state = BattleStateScript.new()
	var left_unit: Dictionary = _add_unit(left_state, "left_forward", "left", 2, 2, {"move": 3})
	var left_result: Dictionary = MovementSystemScript.act_unit(left_state, left_unit)
	var left_move: Dictionary = left_result.get("move", left_result)
	_expect(Vector2i(int(left_move.get("from", Vector2i.ZERO).x), int(left_move.get("from", Vector2i.ZERO).y)) == Vector2i(2, 2), "left move starts from original cell", failures)
	_expect(Vector2i(int(left_unit.get("column", 0)), int(left_unit.get("row", 0))) == Vector2i(3, 2), "left side advances one cell right", failures)

	var right_state = BattleStateScript.new()
	var right_unit: Dictionary = _add_unit(right_state, "right_forward", "right", 8, 2, {"move": 3})
	MovementSystemScript.act_unit(right_state, right_unit)
	_expect(Vector2i(int(right_unit.get("column", 0)), int(right_unit.get("row", 0))) == Vector2i(7, 2), "right side advances one cell left", failures)

	var blocked_state = BattleStateScript.new()
	var blocked: Dictionary = _add_unit(blocked_state, "blocked", "left", 2, 1, {"move": 3})
	_add_unit(blocked_state, "blocker", "left", 3, 1)
	_add_unit(blocked_state, "off_row_enemy", "right", 4, 2)
	var blocked_result: Dictionary = MovementSystemScript.act_unit(blocked_state, blocked)
	_expect(Vector2i(int(blocked.get("column", 0)), int(blocked.get("row", 0))) == Vector2i(2, 1), "blocked unit waits instead of routing around", failures)
	_expect(str(blocked_result.get("action", "")) == "move", "blocked non-attacker returns move/wait result", failures)


func _check_basic_attack_shapes(failures: Array[String]) -> void:
	var melee_state = BattleStateScript.new()
	var melee: Dictionary = _add_unit(melee_state, "melee", "left", 4, 2, {"class": "tank", "range": 2})
	var off_row_close: Dictionary = _add_unit(melee_state, "off_row_close", "right", 5, 3)
	var same_row_far: Dictionary = _add_unit(melee_state, "same_row_far", "right", 6, 2)
	var melee_target: Dictionary = TargetingSystemScript.select_target(melee, melee_state.get_enemy_units("left"))
	_expect(melee_target.get("instance_id", "") == same_row_far.get("instance_id", ""), "melee only attacks same row", failures)
	_expect(melee_target.get("instance_id", "") != off_row_close.get("instance_id", ""), "melee ignores adjacent row even when closer", failures)

	var ranged_state = BattleStateScript.new()
	var ranged: Dictionary = _add_unit(ranged_state, "ranged", "left", 4, 2, {"class": "mage", "range": 3})
	var adjacent: Dictionary = _add_unit(ranged_state, "adjacent", "right", 5, 3)
	var outside_band: Dictionary = _add_unit(ranged_state, "outside_band", "right", 5, 4)
	var far_same: Dictionary = _add_unit(ranged_state, "far_same", "right", 6, 2)
	var ranged_target: Dictionary = TargetingSystemScript.select_target(ranged, ranged_state.get_enemy_units("left"))
	_expect(ranged_target.get("instance_id", "") == adjacent.get("instance_id", ""), "ranged attacks nearest enemy inside three-row band", failures)
	_expect(ranged_target.get("instance_id", "") != outside_band.get("instance_id", ""), "ranged ignores enemies two rows away", failures)
	_expect(ranged_target.get("instance_id", "") != far_same.get("instance_id", ""), "ranged nearest target wins before same-row preference at longer distance", failures)


func _check_assassin_backstab(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var assassin: Dictionary = _add_unit(state, "assassin", "left", 5, 2, {"class": "assassin", "attack": 2, "range": 1})
	var behind: Dictionary = _add_unit(state, "behind", "right", 4, 2, {"hp": 10, "max_hp": 10})
	var target: Dictionary = TargetingSystemScript.select_target(assassin, state.get_enemy_units("left"))
	_expect(target.get("instance_id", "") == behind.get("instance_id", ""), "assassin can target enemy one cell behind", failures)
	var result: Dictionary = MovementSystemScript.act_unit(state, assassin)
	_expect(result.get("target_id", "") == behind.get("instance_id", ""), "assassin attacks backstab target", failures)
	_expect(int(result.get("backstab_bonus_damage", 0)) == AttackShapeSystemScript.ASSASSIN_BACKSTAB_BONUS_DAMAGE, "assassin backstab uses fixed bonus damage", failures)
	_expect(int(behind.get("hp", 0)) == 10 - 2 - AttackShapeSystemScript.ASSASSIN_BACKSTAB_BONUS_DAMAGE, "assassin backstab damage is base plus fixed bonus", failures)


func _check_skill_attack_shape(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var caster: Dictionary = _add_unit(state, "shape_caster", "left", 2, 2, {"skill_ids": ["m87_cross"]})
	var center: Dictionary = _add_unit(state, "center", "right", 5, 2, {"hp": 10, "max_hp": 10})
	var row_target: Dictionary = _add_unit(state, "row_target", "right", 6, 2, {"hp": 10, "max_hp": 10})
	var column_target: Dictionary = _add_unit(state, "column_target", "right", 5, 3, {"hp": 10, "max_hp": 10})
	var diagonal: Dictionary = _add_unit(state, "diagonal", "right", 6, 3, {"hp": 10, "max_hp": 10})

	var original_skills: Array = DataLoaderScript.data.get("skills", []).duplicate(true)
	DataLoaderScript.data["skills"] = original_skills + [
		{
			"id": "m87_cross",
			"name": "M87 Cross",
			"trigger": "deploy",
			"effect_type": "area_damage",
			"target": "nearest_enemy",
			"attack_shape": AttackShapeSystemScript.SHAPE_CROSS,
			"params": {"damage": 1, "damage_type": "true", "radius": 1}
		}
	]
	var results: Array = state.trigger_skill_event("deploy", {"source_unit": caster})
	DataLoaderScript.data["skills"] = original_skills

	_expect(results.size() == 1, "shape skill executes once", failures)
	_expect(str(results[0].get("attack_shape", "")) == AttackShapeSystemScript.SHAPE_CROSS, "skill result records AttackShapeSystem shape", failures)
	_expect(int(center.get("hp", 0)) == 9, "cross skill hits center target", failures)
	_expect(int(row_target.get("hp", 0)) == 9, "cross skill hits same-row target", failures)
	_expect(int(column_target.get("hp", 0)) == 9, "cross skill hits same-column target", failures)
	_expect(int(diagonal.get("hp", 0)) == 10, "cross skill does not hit diagonal target", failures)


func _check_roster_classes_and_skill_numbers(failures: Array[String]) -> void:
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if bool(hero.get("is_summon", false)) or str(hero.get("id", "")) == "yellow_turban":
			continue
		var hero_class := str(hero.get("class", hero.get("profession", "")))
		_expect(hero_class in ALLOWED_CLASSES, "hero %s uses one of five classes" % str(hero.get("id", "")), failures)

	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		var text := "%s %s" % [str(skill.get("name", "")), str(skill.get("description", ""))]
		_expect(not text.contains("%"), "skill %s does not use percent notation" % str(skill.get("id", "")), failures)
		_expect(not text.contains("百分比"), "skill %s does not describe percentage scaling" % str(skill.get("id", "")), failures)
		_expect(not text.contains("双倍"), "skill %s does not describe double damage scaling" % str(skill.get("id", "")), failures)


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


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
