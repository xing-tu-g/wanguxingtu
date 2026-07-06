extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.card_zone_summary_label.text.contains("牌库剩余"), "summary shows remaining deck count", failures)
	_expect(not screen.card_zone_summary_label.text.contains("★"), "summary avoids star rarity", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(not screen.card_zone_collapsed, "toggle expands card zone", failures)
	_expect(screen.card_zone_detail_label.visible, "expanded card zone shows details", failures)
	screen._toggle_card_zone()
	await process_frame
	_expect(screen.card_zone_collapsed, "toggle collapses card zone", failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M29 collapsible card zone checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
