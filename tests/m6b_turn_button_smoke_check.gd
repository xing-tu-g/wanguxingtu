extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.turn_controller.current_side == BoardModelScript.SIDE_LEFT, "battle screen starts on left side", failures)
	screen._advance_turn()
	await process_frame
	_expect(screen.turn_controller.current_side == BoardModelScript.SIDE_RIGHT, "advance turn switches to right side", failures)
	screen._advance_turn()
	await process_frame
	_expect(screen.turn_controller.current_side == BoardModelScript.SIDE_LEFT, "right advance returns to left side", failures)
	_expect(screen.turn_controller.turn_number >= 2, "round advances after both sides act", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M6b turn button smoke checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
