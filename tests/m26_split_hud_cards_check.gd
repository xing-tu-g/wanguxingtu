extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var initial_turn_text: String = screen.star_label.text
	screen._advance_turn()
	await process_frame
	_expect(screen.star_label.text != initial_turn_text, "turn label updates next acting side", failures)
	_expect(screen.player_hud_label.text.length() > 0, "player HUD remains readable after turn advance", failures)
	_expect(screen.enemy_hud_label.text.length() > 0, "enemy HUD remains readable after turn advance", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M26 split HUD card checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
