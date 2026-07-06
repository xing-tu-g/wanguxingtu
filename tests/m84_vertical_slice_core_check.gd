extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const SkillDataLoaderScript: GDScript = preload("res://scripts/data/SkillDataLoader.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")


func _init() -> void:
	var failures: Array[String] = []
	DataLoaderScript.load_all()

	_check_hero_roster_and_resources(failures)
	await _check_battle_screen_uses_full_default_roster(failures)
	_check_nearest_enemy_ai(failures)
	_check_generic_skill_effects(failures)

	if failures.is_empty():
		print("M84 vertical slice core checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hero_roster_and_resources(failures: Array[String]) -> void:
	var hero_ids: Array = HeroDataLoaderScript.all_hero_ids(false)
	_expect(hero_ids.size() == 55, "vertical slice uses 55 playable heroes, excluding summons", failures)
	_expect(not hero_ids.has("yellow_turban"), "summon Yellow Turban is not counted as playable hero", failures)
	_expect(HeroDataLoaderScript.missing_resource_report(false).is_empty(), "all playable heroes have configured visual resources", failures)


func _check_battle_screen_uses_full_default_roster(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen._player_battle_hero_ids().size() == 55, "default player deck is built from full hero config", failures)
	_expect(screen._enemy_battle_hero_ids().size() == 55, "default enemy deck is built from full hero config", failures)
	_expect(screen.player_hand.size() == 5, "battle starts with five hand cards", failures)
	_expect(screen.player_deck.size() == 50, "draw_queue keeps 50 cards after opening draw", failures)
	screen.queue_free()
	await process_frame


func _check_nearest_enemy_ai(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var mover: Dictionary = _add_unit(state, "mover", "left", 2, 1, {"move": 3, "range": 1})
	_add_unit(state, "near_enemy", "right", 4, 3, {"hp": 8})
	_add_unit(state, "far_enemy", "right", 8, 1, {"hp": 8})
	var result: Dictionary = MovementSystemScript.act_unit(state, mover)
	var move_result: Dictionary = result.get("move", {})
	_expect(str(move_result.get("target_id", "")) == "", "forward-only auto battle does not route toward a nearest enemy", failures)
	_expect(Vector2i(int(mover.get("column", 0)), int(mover.get("row", 0))) == Vector2i(3, 1), "left unit advances one cell to the right only", failures)
	_expect(int(mover.get("row", 0)) == 1, "auto battle never changes row while moving", failures)
	_expect(str(result.get("target_id", "")) != "near_enemy", "off-row nearest enemy is not attacked by melee movement AI", failures)


func _check_generic_skill_effects(failures: Array[String]) -> void:
	_expect(SkillDataLoaderScript.supported_effect_types().has("area_damage"), "skill loader exposes area damage support", failures)
	_expect(SkillDataLoaderScript.supported_effect_types().has("shield"), "skill loader exposes shield support", failures)
	var state = BattleStateScript.new()
	var caster: Dictionary = _add_unit(state, "caster", "left", 2, 2, {
		"attack": 2,
		"move": 2,
		"skill_ids": ["vs_damage", "vs_area", "vs_heal", "vs_shield", "vs_stun", "vs_attack_buff", "vs_slow"],
	})
	var target: Dictionary = _add_unit(state, "target", "right", 4, 2, {"hp": 12, "max_hp": 12})
	var splash: Dictionary = _add_unit(state, "splash", "right", 4, 3, {"hp": 12, "max_hp": 12})
	var ally: Dictionary = _add_unit(state, "ally", "left", 2, 3, {"hp": 3, "max_hp": 8})

	var original_skills: Array = DataLoaderScript.data.get("skills", []).duplicate(true)
	DataLoaderScript.data["skills"] = original_skills + [
		{"id": "vs_damage", "name": "VS Damage", "trigger": "deploy", "effect_type": "damage", "target": "nearest_enemy", "params": {"damage": 2, "damage_type": "true"}},
		{"id": "vs_area", "name": "VS Area", "trigger": "deploy", "effect_type": "area_damage", "target": "nearest_enemy", "params": {"damage": 1, "damage_type": "true", "radius": 1}},
		{"id": "vs_heal", "name": "VS Heal", "trigger": "deploy", "effect_type": "heal", "target": "adjacent_allies", "params": {"heal": 2}},
		{"id": "vs_shield", "name": "VS Shield", "trigger": "deploy", "effect_type": "shield", "target": "self", "params": {"value": 3}, "duration_turns": 2},
		{"id": "vs_stun", "name": "VS Stun", "trigger": "deploy", "effect_type": "stun", "target": "nearest_enemy", "params": {"value": 1}, "duration_turns": 1},
		{"id": "vs_attack_buff", "name": "VS Buff", "trigger": "deploy", "effect_type": "attack_buff", "target": "self", "params": {"value": 2}, "duration_turns": 1},
		{"id": "vs_slow", "name": "VS Slow", "trigger": "deploy", "effect_type": "slow", "target": "nearest_enemy", "params": {"value": 1}, "duration_turns": 1},
	]
	var results: Array = state.trigger_skill_event("deploy", {"source_unit": caster})
	DataLoaderScript.data["skills"] = original_skills

	_expect(results.size() == 7, "generic deploy trigger executes seven vertical slice skill effects", failures)
	_expect(int(target.get("hp", 0)) < 12, "damage and area damage reduce nearest enemy HP", failures)
	_expect(int(splash.get("hp", 0)) == 11, "area damage hits adjacent enemy", failures)
	_expect(int(ally.get("hp", 0)) == 5, "heal effect restores adjacent ally", failures)
	_expect(caster.get("statuses", {}).has("shield"), "shield status is applied", failures)
	_expect(target.get("statuses", {}).has("stun"), "stun status is applied", failures)
	_expect(caster.get("statuses", {}).has("attack_buff"), "attack buff status is applied", failures)
	_expect(target.get("statuses", {}).has("slow"), "slow status is applied", failures)


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
	}
	for key in overrides:
		unit_data[key] = overrides[key]
	var result: Dictionary = state.create_unit_instance(unit_data, side, column, row)
	return result.get("unit", {})


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
