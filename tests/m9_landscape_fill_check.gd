extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.player_master_panel.custom_minimum_size.x > 0, "player panel reserves landscape side space", failures)
	_expect(screen.enemy_master_panel.custom_minimum_size.x > 0, "enemy panel reserves landscape side space", failures)
	_expect(screen.grid != null and screen.cell_buttons.size() > 0, "board fills center landscape area", failures)
	_expect(screen.hero_button_row.get_child_count() >= 5, "bottom hand reserves card area", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M9 landscape fill checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
