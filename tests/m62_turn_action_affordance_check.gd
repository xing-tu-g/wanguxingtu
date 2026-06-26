extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.get_script():
		failures.append("FAIL: battle screen script failed to load")
		_finish(screen, failures)
		return

	_check_initial_turn_button(screen, failures)
	screen._advance_turn()
	await process_frame
	_check_enemy_turn_button(screen, failures)
	screen._advance_turn()
	await process_frame
	_check_returned_player_turn_button(screen, failures)
	_finish(screen, failures)


func _check_initial_turn_button(screen: Control, failures: Array[String]) -> void:
	_expect(screen.advance_turn_button != null, "battle screen exposes advance turn button", failures)
	_expect(screen.advance_turn_button.text.contains("我方行动"), "initial advance button names current side", failures)
	_expect(screen.advance_turn_button.text.contains("点击推进"), "advance button tells player to click", failures)
	_expect(screen.advance_turn_button.tooltip_text.contains("我方"), "advance tooltip names current side", failures)
	_expect(screen.advance_turn_button.custom_minimum_size.x >= 220, "advance button has larger touch target", failures)
	_expect(screen.status_label.text.contains("下一步：点击「我方行动」推进回合"), "status label points to advance button", failures)


func _check_enemy_turn_button(screen: Control, failures: Array[String]) -> void:
	_expect(screen.advance_turn_button.text.contains("敌方行动"), "after player advance button names enemy side", failures)
	_expect(screen.advance_turn_button.tooltip_text.contains("敌方"), "advance tooltip updates to enemy side", failures)
	_expect(screen.star_label.text.contains("敌方行动"), "star label still mirrors current side", failures)


func _check_returned_player_turn_button(screen: Control, failures: Array[String]) -> void:
	_expect(screen.advance_turn_button.text.contains("我方行动"), "after enemy advance button returns to player side", failures)
	_expect(screen.status_label.text.contains("下一步：点击我方行动"), "status label updates next-step hint after turn cycle", failures)
	_expect(screen.tutorial_step_turn_label.text.contains("✓ 推进回合"), "tutorial progress still marks turn advance", failures)


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M62 turn action affordance checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
