extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.has_node("TopBar"), "battle screen has top bar", failures)
	_expect(screen.has_node("DuelArea"), "battle screen has duel area", failures)
	_expect(screen.has_node("BottomHand"), "battle screen has bottom hand bar", failures)
	_expect(screen.player_master_panel.custom_minimum_size.x > 0, "player master panel reserves side space", failures)
	_expect(screen.enemy_master_panel.custom_minimum_size.x > 0, "enemy master panel reserves side space", failures)
	_expect(screen.grid != null, "board grid exists", failures)
	_expect(screen.hero_button_row.get_child_count() >= 1, "hand row builds card controls", failures)
	_expect(not screen.get_node("BottomHand/Controls/ResetButton").visible, "reset button is hidden in normal UI", failures)

	_expect(not screen.log_panel.visible, "battle log drawer starts hidden", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(not screen.log_panel.visible, "battle log drawer cannot open during battle", failures)
	_expect(not screen.toggle_log_button.visible, "battle report button stays hidden", failures)
	screen._toggle_battle_log()
	await process_frame
	_expect(not screen.log_panel.visible, "battle log drawer remains hidden", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M7b landscape UI checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
