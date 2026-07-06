extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.battle_log_text != null, "battle screen keeps internal log text buffer", failures)
	_expect(not screen.log_panel.visible, "battle log panel is hidden during battle", failures)
	_expect(not screen.toggle_log_button.visible, "battle log button is hidden during battle", failures)
	_expect(screen.battle_log_text.text.is_empty(), "battle screen does not render log text during battle", failures)

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(5, 3)
	await process_frame
	_expect(screen.battle_log_entries.size() > 0, "failed deployment is logged for report replay", failures)
	_expect(screen.battle_log_text.text.is_empty(), "failed deployment does not render log text during battle", failures)
	_expect(not screen.log_panel.visible, "failed deployment does not reveal battle log UI", failures)

	screen._deploy_selected_to_cell(3, 3)
	await process_frame
	var deploy_log: String = _log_text(screen)
	_expect(_contains_any(deploy_log, ["关羽", "Guan Yu"]), "friendly hero name comes from hero data", failures)
	_expect(deploy_log.find("(3,3)") >= 0, "deployment log includes target cell", failures)
	_expect(deploy_log.find("left/") < 0, "friendly hero name is not side-prefixed", failures)
	_expect(screen.battle_log_text.text.is_empty(), "deployment log remains absent from battle UI", failures)

	screen._advance_turn()
	await process_frame
	screen._advance_turn()
	await process_frame
	var log_text: String = _log_text(screen)
	_expect(_contains_any(log_text, ["周瑜", "关羽", "Zhou Yu", "Guan Yu"]), "enemy hero name comes from hero data", failures)
	_expect(log_text.find("right/") < 0, "enemy hero name is not side-prefixed", failures)
	_expect(_has_action_entry(log_text), "movement or attack action is logged", failures)
	_expect(screen.battle_log_entries.size() <= 20, "battle log keeps only latest lines", failures)
	_expect(screen.battle_log_text.text.is_empty(), "turn logs remain absent from battle UI", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(not screen.log_panel.visible, "battle log cannot be opened inside BattleScene", failures)

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


func _log_text(screen: Control) -> String:
	return "\n".join(screen.battle_log_entries)


func _contains_any(text: String, fragments: Array) -> bool:
	for fragment in fragments:
		if text.find(str(fragment)) >= 0:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
