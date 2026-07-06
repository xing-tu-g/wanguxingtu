extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")

const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"
const BATTLE_ANIMATOR_PATH := "res://scripts/ui/BattleAnimator.gd"
const FEEL_DOC := "res://docs/COMBAT_FEEL_POLISH_2026-07-04.md"


func _init() -> void:
	var failures: Array[String] = []
	await _check_runtime_feel_labels(failures)
	_check_feedback_source(failures)
	_check_scope_guardrails(failures)
	if failures.is_empty():
		print("M93 combat feel polish checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_runtime_feel_labels(failures: Array[String]) -> void:
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	_expect(screen.star_label.text.contains("(+"), "top resource label shows next star restore compactly", failures)
	_expect(screen.star_label.text.contains("星潮"), "top star label shows star tide timing", failures)
	_expect(screen.star_label.text.contains("前期") or screen.star_label.text.contains("中期") or screen.star_label.text.contains("后期"), "top star label shows battle phase hint", failures)
	var hint: String = screen._combat_feel_timing_hint()
	_expect(hint.contains("下次星力") and hint.contains("星潮"), "combat feel timing helper contains star and tide info", failures)
	screen.queue_free()


func _check_feedback_source(failures: Array[String]) -> void:
	var screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	var animator_source := FileAccess.get_file_as_string(BATTLE_ANIMATOR_PATH)
	var doc := FileAccess.get_file_as_string(FEEL_DOC)
	_expect(not screen_source.is_empty(), "BattleScreen source is readable", failures)
	_expect(not animator_source.is_empty(), "BattleAnimator source is readable", failures)
	_expect(doc.contains("Combat Feel & Polish Sprint v1"), "combat feel report exists", failures)

	_expect(screen_source.contains("_emit_star_power_feedback"), "BattleScreen emits star power feedback", failures)
	_expect(screen_source.contains("_emit_faction_energy_feedback"), "BattleScreen emits faction energy feedback", failures)
	_expect(screen_source.contains("_emit_side_turn_started_feedback"), "BattleScreen emits side-turn start feedback", failures)
	_expect(screen_source.contains("master_damaged.emit"), "BattleScreen emits master damage feedback", failures)
	_expect(screen_source.contains("_combat_feel_timing_hint"), "BattleScreen formats rhythm hints", failures)

	_expect(animator_source.contains("_on_star_power_changed"), "BattleAnimator listens for star power changes", failures)
	_expect(animator_source.contains("_on_master_damaged"), "BattleAnimator listens for master damage", failures)
	_expect(animator_source.contains("_on_side_turn_started"), "BattleAnimator listens for side-turn start", failures)
	_expect(animator_source.contains("_spawn_screen_notice"), "BattleAnimator can show global feel notices", failures)
	_expect(animator_source.contains("_spawn_death_feedback"), "BattleAnimator shows unit death feedback", failures)
	_expect(animator_source.contains("_spawn_skill_banner(source_unit, skill_result)"), "all successful skills show a skill banner", failures)


func _check_scope_guardrails(failures: Array[String]) -> void:
	var doc := FileAccess.get_file_as_string(FEEL_DOC)
	_expect(doc.contains("不修改战斗规则"), "feel doc states no battle rule changes", failures)
	_expect(doc.contains("不修改") and doc.contains("AttackShapeSystem.gd"), "feel doc records AttackShape guardrail", failures)
	_expect(doc.contains("data/heroes.json") and doc.contains("data/skills.json"), "feel doc records data guardrail", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
