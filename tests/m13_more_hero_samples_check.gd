extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	_check_sample_hero_data(failures)
	await _check_battle_screen_builds_sample_buttons(failures)

	if failures.is_empty():
		print("M13 more hero sample checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_sample_hero_data(failures: Array[String]) -> void:
	var state: BattleState = BattleStateScript.new()
	for hero_id in ["zhaoyun", "zhangfei", "sunshangxiang"]:
		var hero_def: Dictionary = state.get_hero_def(hero_id)
		_expect(not hero_def.is_empty(), "%s hero data exists" % hero_id, failures)
		_expect(str(hero_def.get("name", "")).length() > 0, "%s hero has display name" % hero_id, failures)
		_expect(int(hero_def.get("cost", 0)) > 0, "%s hero has cost" % hero_id, failures)


func _check_battle_screen_builds_sample_buttons(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	for hero_id in ["zhaoyun", "zhangfei", "sunshangxiang"]:
		_expect(screen.hero_buttons.has(hero_id), "battle screen builds %s hand button" % hero_id, failures)
	screen.queue_free()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
