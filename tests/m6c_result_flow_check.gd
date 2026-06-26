extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const ResultScreenScene: PackedScene = preload("res://scenes/ui/ResultScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []

	# ── Part 1: Battle end detection ──────────────────────────────────
	var battle_screen: Control = BattleScreenScene.instantiate()
	root.add_child(battle_screen)
	await process_frame

	# Simulate a left-side win: deploy a hero and zero enemy master HP
	battle_screen.selected_hero_id = "guanyu"
	battle_screen._deploy_selected_to_cell(2, 3)
	await process_frame
	battle_screen.battle_state.master_hp["right"] = 0
	var battle_result: Dictionary = battle_screen._check_battle_end()
	_expect(not battle_result.is_empty(), "battle end produces non-empty result when master HP is zero", failures)
	_expect(str(battle_result.get("outcome", "")) == "left_wins", "left win outcome from zero enemy master HP", failures)

	# ── Part 2: ResultScreen rendering ────────────────────────────────
	var result_screen: Control = ResultScreenScene.instantiate()
	root.add_child(result_screen)

	result_screen.set_result(battle_result)
	await process_frame

	var title: Label = result_screen.get_node("Margin/Layout/Title") as Label
	var body: Label = result_screen.get_node("Margin/Layout/Body") as Label
	_expect(title.text.find("我方胜利") >= 0, "result title displays left win outcome", failures)
	_expect(body.text.find("战斗结果：我方胜利") >= 0, "result body displays outcome text", failures)
	_expect(body.text.find("部署 / 击破") >= 0, "result body displays battle stats", failures)
	_expect(body.text.find("0") >= 0, "result body contains numeric stats", failures)

	# ── Cleanup ───────────────────────────────────────────────────────
	battle_screen.queue_free()
	result_screen.queue_free()
	await process_frame

	if failures.is_empty():
		print("M6c result flow checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
