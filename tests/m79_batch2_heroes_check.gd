extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const SkillSystemScript: GDScript = preload("res://scripts/battle/SkillSystem.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const StrategyCardSystemScript: GDScript = preload("res://scripts/battle/StrategyCardSystem.gd")

const BATCH2_HERO_IDS := [
	"huangzhong", "guojia", "dianwei", "xunyu",
	"dongzhuo", "diaochan", "gongsunzan", "huaxiong",
]

const BATCH2_EXPECTED := {
	"huangzhong": {"faction": "shu", "rarity": "legendary", "class": "archer", "cost": 4, "range": 5},
	"guojia":     {"faction": "wei", "rarity": "legendary", "class": "mage", "cost": 5, "range": 4},
	"dianwei":    {"faction": "wei", "rarity": "legendary", "class": "tank", "cost": 5, "physical_block": 2},
	"xunyu":      {"faction": "wei", "rarity": "legendary", "class": "mage", "cost": 4},
	"dongzhuo":   {"faction": "qun", "rarity": "legendary", "class": "tank", "cost": 6, "max_hp": 12},
	"diaochan":   {"faction": "qun", "rarity": "legendary", "class": "mage", "cost": 4},
	"gongsunzan": {"faction": "qun", "rarity": "epic", "class": "archer", "cost": 4},
	"huaxiong":   {"faction": "qun", "rarity": "epic", "class": "warrior", "cost": 4},
}


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()

	_check_hero_definitions(failures)
	_check_skill_definitions(failures)
	_check_huangzhong_snipe_damage(failures)
	_check_dongzhuo_self_heal(failures)
	_check_xunyu_adjacent_heal(failures)
	_check_diaochan_deploy_debuff(failures)
	_check_strategy_card_names(failures)

	if failures.is_empty():
		print("M79 batch2 heroes check passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hero_definitions(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	for hero_id in BATCH2_HERO_IDS:
		var def: Dictionary = state.get_hero_def(hero_id)
		_expect(not def.is_empty(), "batch2 hero '%s' exists in hero data" % hero_id, failures)
		if def.is_empty():
			continue
		var expected: Dictionary = BATCH2_EXPECTED.get(hero_id, {})
		for key in expected:
			var actual: Variant = def.get(key, "")
			var expected_value: Variant = expected[key]
			if actual is float or actual is int or expected_value is float or expected_value is int:
				_expect(
					is_equal_approx(float(actual), float(expected_value)),
					"hero '%s' %s should be %s (got %s)" % [hero_id, key, expected_value, actual],
					failures,
				)
				continue
			_expect(
				str(actual) == str(expected_value),
				"hero '%s' %s should be %s (got %s)" % [hero_id, key, expected_value, actual],
				failures,
			)
		_expect(def.get("skill_ids", []).size() >= 1, "hero '%s' has at least one skill" % hero_id, failures)


func _check_skill_definitions(failures: Array[String]) -> void:
	var skill_ids := [
		"huangzhong_snipe", "guojia_strategy", "dianwei_rage",
		"xunyu_aid", "dongzhuo_feast", "diaochan_charm",
		"gongsunzan_cavalry", "huaxiong_execute",
	]
	var skills: Array = DataLoaderScript.data.get("skills", [])

	for skill_id in skill_ids:
		var found := false
		for skill in skills:
			if str(skill.get("id", "")) == skill_id:
				found = true
				_expect(
					str(skill.get("name", "")) != "" and skill.get("name", "").find("Prototype") == -1,
					"skill '%s' has a Chinese display name" % skill_id,
					failures,
				)
				break
		_expect(found, "skill '%s' defined in skills.json" % skill_id, failures)


func _check_huangzhong_snipe_damage(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)

	var attacker: Dictionary = state.build_unit_data("huangzhong", state.get_hero_def("huangzhong"))
	attacker["side"] = "left"
	attacker["column"] = 3
	attacker["row"] = 3
	var attack_result: Dictionary = state.create_unit_instance(attacker, "left", 3, 3)
	_expect(attack_result.ok, "huangzhong deploys with correct stats", failures)

	var target: Dictionary = state.build_unit_data("yellow_turban", state.get_hero_def("yellow_turban"))
	target["column"] = 8
	target["row"] = 3
	var target_result: Dictionary = state.create_unit_instance(target, "right", 8, 3)
	_expect(target_result.ok, "target unit deployed for snipe test", failures)
	await process_frame

	var hp_before: int = int(target_result.get("unit", {}).get("hp", 0))
	var skill_results: Array = SkillSystemScript.trigger_event(state, SkillSystemScript.TRIGGER_ATTACK_HIT, {
		"source_unit": attack_result.get("unit", {}),
		"target_unit": target_result.get("unit", {}),
	})
	var hp_after: int = int(target_result.get("unit", {}).get("hp", 0))
	var bonus_total: int = 0
	for r in skill_results:
		bonus_total += int(r.get("bonus_damage", 0))
	_expect(bonus_total == 2, "huangzhong snipe deals 2 true bonus damage (got %d)" % bonus_total, failures)
	_expect(hp_before - hp_after == bonus_total, "target HP reduced by exactly bonus damage", failures)


func _check_dongzhuo_self_heal(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)

	var unit: Dictionary = state.build_unit_data("dongzhuo", state.get_hero_def("dongzhuo"))
	unit["hp"] = 5
	unit["side"] = "left"
	var deploy_result: Dictionary = state.create_unit_instance(unit, "left", 2, 3)
	_expect(deploy_result.ok, "dongzhuo deploys with reduced HP", failures)

	var hp_before: int = int(deploy_result.get("unit", {}).get("hp", 0))
	var skill_results: Array = SkillSystemScript.trigger_event(state, SkillSystemScript.TRIGGER_TURN_START, {
		"side": "left",
		"source_unit": deploy_result.get("unit", {}),
	})
	var hp_after: int = int(deploy_result.get("unit", {}).get("hp", 0))
	var healed: int = hp_after - hp_before
	_expect(healed == 3, "dongzhuo feast heals 3 HP (got %d)" % healed, failures)


func _check_xunyu_adjacent_heal(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)

	var xunyu_def: Dictionary = state.get_hero_def("xunyu")
	var xunyu: Dictionary = state.build_unit_data("xunyu", xunyu_def)
	xunyu["side"] = "left"
	var xr: Dictionary = state.create_unit_instance(xunyu, "left", 3, 3)
	_expect(xr.ok, "xunyu deployed", failures)

	var ally_def: Dictionary = state.get_hero_def("zhaoyun")
	var ally: Dictionary = state.build_unit_data("zhaoyun", ally_def)
	ally["hp"] = 2
	ally["side"] = "left"
	var ar: Dictionary = state.create_unit_instance(ally, "left", 4, 3)
	_expect(ar.ok, "adjacent ally deployed at low HP", failures)
	_expect(xr.get("unit", {}).get("skill_ids", []).has("xunyu_aid"), "xunyu carries adjacent heal skill", failures)


func _check_diaochan_deploy_debuff(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)

	var diaochan_def: Dictionary = state.get_hero_def("diaochan")
	var diaochan: Dictionary = state.build_unit_data("diaochan", diaochan_def)
	diaochan["side"] = "left"
	var dr: Dictionary = state.create_unit_instance(diaochan, "left", 3, 3)
	_expect(dr.ok, "diaochan deployed", failures)

	var skill_results: Array = SkillSystemScript.trigger_event(state, SkillSystemScript.TRIGGER_DEPLOY, {
		"source_unit": dr.get("unit", {}),
	})
	_expect(skill_results.size() >= 1, "diaochan charm triggers on deploy", failures)
	if skill_results.size() > 0:
		_expect(
			int(skill_results[0].get("attack_delta", 0)) == -1,
			"diaochan charm applies -1 attack to enemy side",
			failures,
		)


func _check_strategy_card_names(failures: Array[String]) -> void:
	var cards: Array = DataLoaderScript.data.get("strategy_cards", [])
	var expected_ids := ["fire_arrow", "inspire", "rockfall", "supply", "march", "earthquake"]
	var found_ids: Array[String] = []
	for card in cards:
		var card_id := str(card.get("id", ""))
		if expected_ids.has(card_id):
			found_ids.append(card_id)
			_expect(str(card.get("name", "")).length() > 0, "strategy card '%s' has a display name" % card_id, failures)
	for expected_id in expected_ids:
		_expect(found_ids.has(expected_id), "strategy card '%s' exists" % expected_id, failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)

