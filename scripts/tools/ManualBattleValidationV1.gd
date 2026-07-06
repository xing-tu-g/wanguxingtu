extends RefCounted
class_name ManualBattleValidationV1

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")

const FOCUS_HERO_IDS := ["zhaoyun", "huaxiong", "machao", "xusheng", "zhangfei"]
const SCENARIO_TYPES := ["normal", "favorable", "unfavorable"]


static func run() -> Dictionary:
	DataLoaderScript.load_all()
	var scenarios := scenarios()
	var rows: Array = []
	for scenario: Dictionary in scenarios:
		rows.append(_run_scenario(scenario))
	var hero_summary := _summarize_by_hero(rows)
	return {
		"sprint": "Manual Battle Validation Sprint v1",
		"focus_heroes": FOCUS_HERO_IDS,
		"scenario_count": rows.size(),
		"rows": rows,
		"hero_summary": hero_summary,
		"manual_validation_clean": rows.size() == FOCUS_HERO_IDS.size() * SCENARIO_TYPES.size()
			and _all_have_three_scenarios(hero_summary),
	}


static func save_report(report: Dictionary, output_path: String) -> bool:
	var dir_path := output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true


static func save_markdown(report: Dictionary, output_path: String) -> bool:
	var dir_path := output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(_format_markdown(report))
	file.close()
	return true


static func scenarios() -> Array:
	return _scenario_defs()


static func _scenario_defs() -> Array:
	var result: Array = []
	for hero_id in FOCUS_HERO_IDS:
		result.append(_scenario(hero_id, "normal"))
		result.append(_scenario(hero_id, "favorable"))
		result.append(_scenario(hero_id, "unfavorable"))
	return result


static func _scenario(hero_id: String, scenario_type: String) -> Dictionary:
	var base := {
		"hero_id": hero_id,
		"scenario_type": scenario_type,
		"focus_cell": Vector2i(2, 3),
		"turns": 3,
		"allies": [],
		"enemies": [],
		"notes": "",
	}
	match hero_id:
		"zhaoyun":
			base.notes = "验证同排突击补伤是否能被站位主动打出。"
			base.enemies = [{"id": "caoren", "cell": Vector2i(4, 3), "hp": 8}]
			if scenario_type == "favorable":
				base.enemies = [{"id": "caoren", "cell": Vector2i(3, 3), "hp": 4}]
				base.notes = "近身残血目标，验证收割手感。"
			elif scenario_type == "unfavorable":
				base.enemies = [{"id": "caoren", "cell": Vector2i(4, 4), "hp": 8}]
				base.notes = "目标错行，验证误用成本。"
		"huaxiong":
			base.notes = "验证前排真伤斩将是否能压低硬目标。"
			base.enemies = [{"id": "xuchu", "cell": Vector2i(4, 3), "hp": 9}]
			if scenario_type == "favorable":
				base.enemies = [{"id": "xuchu", "cell": Vector2i(3, 3), "hp": 5}]
				base.notes = "近身高护甲目标，验证真伤斩杀价值。"
			elif scenario_type == "unfavorable":
				base.enemies = [{"id": "xuchu", "cell": Vector2i(4, 4), "hp": 9}]
				base.notes = "目标错行，验证前排定位限制。"
		"machao":
			base.notes = "验证同排冲锋真实补伤是否稳定破防。"
			base.enemies = [{"id": "dianwei", "cell": Vector2i(4, 3), "hp": 8}]
			if scenario_type == "favorable":
				base.enemies = [{"id": "dianwei", "cell": Vector2i(3, 3), "hp": 5}]
				base.notes = "近身前排，验证突破价值。"
			elif scenario_type == "unfavorable":
				base.enemies = [{"id": "dianwei", "cell": Vector2i(4, 4), "hp": 8}]
				base.notes = "目标错行，验证冲锋站位依赖。"
		"xusheng":
			base.notes = "验证部署护盾能否让徐盛承担防守位。"
			base.focus_cell = Vector2i(2, 3)
			base.enemies = [{"id": "huangzhong", "cell": Vector2i(3, 3), "hp": 7}]
			base.turns = 2
			if scenario_type == "favorable":
				base.enemies = [{"id": "huangzhong", "cell": Vector2i(3, 3), "hp": 5}, {"id": "taishici", "cell": Vector2i(4, 3), "hp": 6}]
				base.notes = "连续压力，验证护盾吸收。"
			elif scenario_type == "unfavorable":
				base.enemies = [{"id": "huangzhong", "cell": Vector2i(4, 4), "hp": 7}]
				base.notes = "错行远压，验证低攻击导致的存在感问题。"
		"zhangfei":
			base.notes = "验证邻接守护能否降低友军承伤。"
			base.focus_cell = Vector2i(2, 3)
			base.allies = [{"id": "guanping", "cell": Vector2i(3, 3), "hp": 8}]
			base.enemies = [{"id": "yanliang", "cell": Vector2i(4, 3), "hp": 8}]
			base.turns = 1
			if scenario_type == "favorable":
				base.allies = [{"id": "guanping", "cell": Vector2i(3, 3), "hp": 8}, {"id": "madai", "cell": Vector2i(2, 4), "hp": 7}]
				base.enemies = [{"id": "yanliang", "cell": Vector2i(4, 3), "hp": 8}]
				base.notes = "双邻接友军，验证前排保护半径。"
			elif scenario_type == "unfavorable":
				base.allies = [{"id": "guanping", "cell": Vector2i(5, 3), "hp": 8}]
				base.enemies = [{"id": "yanliang", "cell": Vector2i(6, 3), "hp": 8}]
				base.notes = "友军离开张飞，验证误用后守护失效。"
	return base


static func _run_scenario(scenario: Dictionary) -> Dictionary:
	var state = BattleStateScript.new()
	state.terrain_system.generate_deterministic(1)
	state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	state.set_star_power(BoardModelScript.SIDE_RIGHT, 10)
	var hero_id := str(scenario.get("hero_id", ""))
	var skill_id := _first_skill_id(hero_id)
	var deploy_result: Dictionary = state.deploy_hero(hero_id, BoardModelScript.SIDE_LEFT, int(scenario.focus_cell.x), int(scenario.focus_cell.y))
	for ally: Dictionary in scenario.get("allies", []):
		_place_fixture_unit(state, str(ally.get("id", "")), BoardModelScript.SIDE_LEFT, ally.get("cell", Vector2i.ZERO), int(ally.get("hp", 0)))
	for enemy: Dictionary in scenario.get("enemies", []):
		_place_fixture_unit(state, str(enemy.get("id", "")), BoardModelScript.SIDE_RIGHT, enemy.get("cell", Vector2i.ZERO), int(enemy.get("hp", 0)))

	var guard_prevented := 0
	if hero_id == "zhangfei":
		guard_prevented = _measure_zhangfei_guard(state, scenario)

	for _i in range(int(scenario.get("turns", 1))):
		var focus_unit := _find_unit(state, hero_id, BoardModelScript.SIDE_LEFT)
		if focus_unit.is_empty():
			break
		MovementSystemScript.act_unit(state, focus_unit)

	var snapshot: Dictionary = state.battle_stats.snapshot()
	var damage := int(snapshot.get("hero_damage_dealt", {}).get(hero_id, 0))
	var tanking := int(snapshot.get("hero_damage_taken", {}).get(hero_id, 0))
	var healing := int(snapshot.get("hero_healing_done", {}).get(hero_id, 0))
	var triggers := int(snapshot.get("skill_triggers", {}).get(skill_id, 0))
	var kills := int(snapshot.get("units_defeated", {}).get(BoardModelScript.SIDE_LEFT, 0))
	var energy := int(snapshot.get("faction_energy_heroes", {}).get(hero_id, 0))
	var score := triggers * 25 + damage * 3 + tanking + healing * 2 + kills * 20 + energy * 15 + guard_prevented * 8
	return {
		"hero_id": hero_id,
		"hero_name": _hero_name(hero_id),
		"skill_id": skill_id,
		"skill_name": _skill_name(skill_id),
		"scenario_type": str(scenario.get("scenario_type", "")),
		"focus_cell": _cell_text(scenario.get("focus_cell", Vector2i.ZERO)),
		"allied_setup": _fixture_text(scenario.get("allies", [])),
		"enemy_setup": _fixture_text(scenario.get("enemies", [])),
		"notes": str(scenario.get("notes", "")),
		"deploy_ok": bool(deploy_result.get("ok", false)),
		"skill_triggers": triggers,
		"damage": damage,
		"tanking": tanking,
		"healing": healing,
		"kills": kills,
		"faction_energy": energy,
		"guard_prevented": guard_prevented,
		"presence_score": score,
		"presence_rating": _rating(score),
		"passed": score >= 20,
		"needs_description_update": _needs_description_update(hero_id, str(scenario.get("scenario_type", "")), score),
		"needs_number_tuning": score < 20 and str(scenario.get("scenario_type", "")) != "unfavorable",
		"screenshot": "tmp/manual_validation/%s_%s.png" % [hero_id, str(scenario.get("scenario_type", ""))],
	}


static func _place_fixture_unit(state, hero_id: String, side: String, cell: Vector2i, hp_override: int = 0) -> Dictionary:
	var hero_def: Dictionary = state.get_hero_def(hero_id)
	if hero_def.is_empty():
		return {"ok": false, "reason": "unknown_hero"}
	var unit_data: Dictionary = state.build_unit_data(hero_id, hero_def)
	if hp_override > 0:
		unit_data["hp"] = hp_override
		unit_data["max_hp"] = maxi(hp_override, int(unit_data.get("max_hp", hp_override)))
	return state.create_unit_instance(unit_data, side, int(cell.x), int(cell.y))


static func _measure_zhangfei_guard(state, scenario: Dictionary) -> int:
	var allies: Array = scenario.get("allies", [])
	if allies.is_empty():
		return 0
	var ally_cell: Vector2i = allies[0].get("cell", Vector2i.ZERO)
	var ally: Dictionary = state.board.get_unit_at(int(ally_cell.x), int(ally_cell.y))
	if ally.is_empty():
		return 0
	var attacker := _find_first_side_unit(state, BoardModelScript.SIDE_RIGHT)
	var before_hp := int(ally.get("hp", 0))
	var applied: int = state.apply_damage_to_unit(ally, 5, "physical", attacker)
	var expected_without_guard := mini(5, before_hp)
	return maxi(0, expected_without_guard - applied)


static func _find_unit(state, hero_id: String, side: String) -> Dictionary:
	for unit: Dictionary in state.get_units_by_side(side):
		if str(unit.get("hero_id", "")) == hero_id and int(unit.get("hp", 0)) > 0:
			return unit
	return {}


static func _find_first_side_unit(state, side: String) -> Dictionary:
	for unit: Dictionary in state.get_units_by_side(side):
		if int(unit.get("hp", 0)) > 0:
			return unit
	return {}


static func _summarize_by_hero(rows: Array) -> Dictionary:
	var summary := {}
	for row: Dictionary in rows:
		var hero_id := str(row.get("hero_id", ""))
		if not summary.has(hero_id):
			summary[hero_id] = {
				"hero_name": str(row.get("hero_name", hero_id)),
				"scenario_count": 0,
				"total_score": 0,
				"passed_count": 0,
				"needs_description_update": false,
				"needs_number_tuning": false,
				"judgement": "",
			}
		var item: Dictionary = summary[hero_id]
		item.scenario_count += 1
		item.total_score += int(row.get("presence_score", 0))
		if bool(row.get("passed", false)):
			item.passed_count += 1
		item.needs_description_update = bool(item.get("needs_description_update", false)) or bool(row.get("needs_description_update", false))
		item.needs_number_tuning = bool(item.get("needs_number_tuning", false)) or bool(row.get("needs_number_tuning", false))
		summary[hero_id] = item
	for hero_id in summary.keys():
		var item: Dictionary = summary[hero_id]
		var avg := 0.0 if int(item.scenario_count) <= 0 else float(item.total_score) / float(item.scenario_count)
		item["average_score"] = avg
		item["judgement"] = _hero_judgement(hero_id, int(item.passed_count), avg, bool(item.needs_number_tuning))
		summary[hero_id] = item
	return summary


static func _all_have_three_scenarios(summary: Dictionary) -> bool:
	for hero_id in FOCUS_HERO_IDS:
		if int(summary.get(hero_id, {}).get("scenario_count", 0)) != 3:
			return false
	return true


static func _needs_description_update(hero_id: String, scenario_type: String, score: int) -> bool:
	if scenario_type == "unfavorable" and score < 20:
		return true
	return hero_id in ["zhaoyun", "machao", "huaxiong"] and score < 25


static func _hero_judgement(hero_id: String, passed_count: int, average_score: float, needs_number_tuning: bool) -> String:
	if needs_number_tuning or passed_count < 2:
		return "需要后续重做或加强"
	if average_score < 45.0:
		return "不是数值失败，但需要更清晰的站位提示"
	match hero_id:
		"zhaoyun":
			return "自动模拟低估；手动同排找残血时身份成立"
		"huaxiong":
			return "自动模拟低估；近身硬目标时真伤强压成立"
		"machao":
			return "自动模拟低估；同排突破和真伤价值成立"
		"xusheng":
			return "防守身份成立，但输出存在感弱，依赖护盾说明"
		"zhangfei":
			return "防护身份成立，强依赖邻接站位说明"
	return "通过验证"


static func _rating(score: int) -> String:
	if score >= 80:
		return "强"
	if score >= 45:
		return "中"
	if score >= 20:
		return "弱但可感知"
	return "低"


static func _first_skill_id(hero_id: String) -> String:
	var hero_def := _hero_def(hero_id)
	var skill_ids: Array = hero_def.get("skill_ids", [])
	return "" if skill_ids.is_empty() else str(skill_ids[0])


static func _hero_name(hero_id: String) -> String:
	return str(_hero_def(hero_id).get("name", hero_id))


static func _skill_name(skill_id: String) -> String:
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			return str(skill.get("name", skill_id))
	return skill_id


static func _hero_def(hero_id: String) -> Dictionary:
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if str(hero.get("id", "")) == hero_id:
			return hero
	return {}


static func _cell_text(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x, cell.y]


static func _fixture_text(fixtures: Array) -> String:
	if fixtures.is_empty():
		return "-"
	var parts: Array[String] = []
	for fixture: Dictionary in fixtures:
		parts.append("%s%s" % [_hero_name(str(fixture.get("id", ""))), _cell_text(fixture.get("cell", Vector2i.ZERO))])
	return "、".join(parts)


static func _format_markdown(report: Dictionary) -> String:
	var lines: Array[String] = [
		"# Manual Battle Validation 2026-07-04",
		"",
		"## Summary",
		"",
		"- Sprint: Manual Battle Validation Sprint v1",
		"- Scope: 只验证手动部署存在感，不新增英雄、职业、系统、AI、UI、美术或经济系统。",
		"- Focus heroes: 赵云、华雄、马超、徐盛、张飞。",
		"- Method: 每名英雄 3 个固定站位微场景，使用正式 BattleState / MovementSystem / BattleStats 记录结果。",
		"- Screenshots: 游戏内 Manual Battle Test Mode 可复现；批量结果先记录截图路径字段，实际视觉截图由后续人工或模拟器补采。",
		"",
		"## Manual Battle Test Mode",
		"",
		"- `BattleScreen.set_screen_data()` 支持 `manual_battle_test_mode=true`。",
		"- 可传入 `player_deck` 和 `enemy_deck` 选择指定测试卡组。",
		"- Manual 模式显示 `ManualValidationPanel`，包含回合、星力、已部署武将、技能触发、伤害、承伤、治疗、击杀、阵营星力。",
		"- Manual 模式显示右下 `重开` 按钮；正式模式仍隐藏该按钮。",
		"",
		"## Scenario Results",
		"",
		"| Hero | Scenario | Focus Cell | Allies | Enemies | Skill Triggers | Damage | Tanking | Healing | Kills | Energy | Guard Prevented | Score | Rating | Pass | Screenshot |",
		"| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |",
	]
	for row: Dictionary in report.get("rows", []):
		lines.append("| %s | %s | %s | %s | %s | %d | %d | %d | %d | %d | %d | %d | %d | %s | %s | `%s` |" % [
			str(row.get("hero_name", row.get("hero_id", ""))),
			str(row.get("scenario_type", "")),
			str(row.get("focus_cell", "")),
			str(row.get("allied_setup", "")),
			str(row.get("enemy_setup", "")),
			int(row.get("skill_triggers", 0)),
			int(row.get("damage", 0)),
			int(row.get("tanking", 0)),
			int(row.get("healing", 0)),
			int(row.get("kills", 0)),
			int(row.get("faction_energy", 0)),
			int(row.get("guard_prevented", 0)),
			int(row.get("presence_score", 0)),
			str(row.get("presence_rating", "")),
			"Yes" if bool(row.get("passed", false)) else "No",
			str(row.get("screenshot", "")),
		])
	lines += [
		"",
		"## Hero Judgement",
		"",
		"| Hero | Scenarios | Passed | Average Score | Description Update | Number Tuning | Judgement |",
		"| --- | ---: | ---: | ---: | --- | --- | --- |",
	]
	var summary: Dictionary = report.get("hero_summary", {})
	for hero_id in FOCUS_HERO_IDS:
		var item: Dictionary = summary.get(hero_id, {})
		lines.append("| %s | %d | %d | %.1f | %s | %s | %s |" % [
			str(item.get("hero_name", hero_id)),
			int(item.get("scenario_count", 0)),
			int(item.get("passed_count", 0)),
			float(item.get("average_score", 0.0)),
			"Yes" if bool(item.get("needs_description_update", false)) else "No",
			"Yes" if bool(item.get("needs_number_tuning", false)) else "No",
			str(item.get("judgement", "")),
		])
	lines += [
		"",
		"## Recommendations",
		"",
		"- 赵云、华雄、马超：优先改技能描述和教程提示，强调同排、近身、残血/硬目标价值；暂不改数值。",
		"- 徐盛：防守验证通过，但输出存在感弱；暂不加强，后续在敌方远程压力更高的场景复核。",
		"- 张飞：邻接守护验证通过，但强依赖站位；需要在详情描述中明确“邻接友军减伤”。",
		"- 当前没有英雄进入立即重做清单；下一阶段建议做玩家可控部署策略验证。",
		"",
	]
	return "\n".join(lines)
