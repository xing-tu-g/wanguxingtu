extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.player_master_panel != null, "player HUD lives inside left master panel", failures)
	_expect(screen.enemy_master_panel != null, "enemy HUD lives inside right master panel", failures)
	_expect(screen.player_hud_label.text.length() > 0, "player HUD shows resources", failures)
	_expect(screen.enemy_hud_label.text.length() > 0, "enemy HUD shows resources", failures)
	_expect(screen.star_label.text.length() > 0, "top turn label remains compact", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M26 battle HUD card checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
