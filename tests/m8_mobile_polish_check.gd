extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.has_node("TopBar"), "mobile battle keeps top bar", failures)
	_expect(screen.has_node("DuelArea"), "mobile battle keeps duel area", failures)
	_expect(screen.has_node("BottomHand"), "mobile battle keeps bottom hand", failures)
	_expect(screen.hero_button_row.get_child_count() >= 1, "mobile hand row has cards", failures)
	_expect(screen.advance_turn_button.custom_minimum_size.y >= 100.0, "primary turn button remains touch friendly", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M8 mobile polish checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
