extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.battle_state.get_star_power("left") == 5, "battle screen starts with left star power 5", failures)
	_expect(screen.cell_buttons.size() == 47, "battle screen builds 47 board cells (9-10-9-10-9 offset grid)", failures)

	screen.selected_hero_id = "zhangjiao"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	var left_units: Array = screen.battle_state.get_units_by_side("left")
	var yellow_turban_count := 0
	for unit: Dictionary in left_units:
		if str(unit.get("hero_id", "")) == "yellow_turban":
			yellow_turban_count += 1
	_expect(left_units.size() >= 2, "battle screen deploys Zhangjiao and summon units", failures)
	_expect(yellow_turban_count > 0, "battle screen shows summon skill through real state", failures)
	_expect(screen.battle_state.get_star_power("left") == 0, "battle screen deployment spends star power", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M6a battle screen smoke checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
