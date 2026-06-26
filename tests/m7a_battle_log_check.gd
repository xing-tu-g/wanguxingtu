extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.battle_log_text != null, "battle screen exposes visible log text", failures)

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.battle_log_text.text.length() > 0, "failed deployment is logged", failures)

	screen._deploy_selected_to_cell(3, 3)
	await process_frame
	_expect(_contains_any(screen.battle_log_text.text, ["关羽", "Guan Yu"]), "friendly hero name comes from hero data", failures)
	_expect(screen.battle_log_text.text.find("(3,3)") >= 0, "deployment log includes target cell", failures)
	_expect(screen.battle_log_text.text.find("left/") < 0, "friendly hero name is not side-prefixed", failures)

	screen._advance_turn()
	await process_frame
	screen._advance_turn()
	await process_frame
	var log_text: String = screen.battle_log_text.text
	_expect(_contains_any(log_text, ["周瑜", "关羽", "Zhou Yu", "Guan Yu"]), "enemy hero name comes from hero data", failures)
	_expect(log_text.find("right/") < 0, "enemy hero name is not side-prefixed", failures)
	_expect(_has_action_entry(log_text), "movement or attack action is logged", failures)
	_expect(screen.battle_log_entries.size() <= 20, "battle log keeps only latest lines", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M7a battle log checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _has_action_entry(log_text: String) -> bool:
	return _contains_any(log_text, ["关羽", "周瑜", "Guan Yu", "Zhou Yu"])


func _contains_any(text: String, fragments: Array) -> bool:
	for fragment in fragments:
		if text.find(str(fragment)) >= 0:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
