extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_initial_turn_button(screen, failures)
	screen._advance_turn()
	await process_frame
	_check_enemy_turn_button(screen, failures)
	screen._advance_turn()
	await process_frame
	_check_returned_player_turn_button(screen, failures)
	_finish(screen, failures)


func _check_initial_turn_button(screen: Control, failures: Array[String]) -> void:
	var label: Label = screen.advance_turn_button.get_node("AdvanceText")
	_expect(screen.advance_turn_button != null, "battle screen exposes advance turn button", failures)
	_expect(label.text.contains("推进"), "advance button uses compact main-action label", failures)
	_expect(screen.advance_turn_button.tooltip_text.contains("推进"), "advance tooltip describes turn advance", failures)
	_expect(screen.advance_turn_button.custom_minimum_size.x >= 160, "advance button has large touch target", failures)
	_expect(screen.status_label.text.contains("我方行动"), "top core status names current side", failures)
	_expect(screen.star_label.text.contains("星潮"), "resource label carries star tide state", failures)


func _check_enemy_turn_button(screen: Control, failures: Array[String]) -> void:
	_expect(screen.status_label.text.contains("敌方行动"), "top core status updates to enemy side", failures)
	_expect(screen.advance_turn_button.tooltip_text.contains("推进"), "advance tooltip remains stable on enemy side", failures)


func _check_returned_player_turn_button(screen: Control, failures: Array[String]) -> void:
	_expect(screen.status_label.text.contains("我方行动"), "top core status returns to player side", failures)
	_expect(screen.tutorial_step_turn_label.text.length() > 0, "tutorial turn state remains tracked even when hidden", failures)


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
