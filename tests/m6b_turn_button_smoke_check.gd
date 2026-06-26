extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(3, 3)
	await process_frame

	var left_units_before: Array = screen.battle_state.get_units_by_side("left")
	_expect(left_units_before.size() == 1, "left debug deploy creates one unit", failures)
	var left_unit_id := str(left_units_before[0].get("instance_id", ""))
	var left_start_column := int(left_units_before[0].get("column", 0))
	_expect(screen.turn_controller.current_side == "left", "battle screen starts on left side", failures)

	screen._advance_turn()
	await process_frame
	_expect(screen.turn_controller.current_side == "right", "advance turn switches to right side", failures)

	screen._advance_turn()
	await process_frame
	var right_units: Array = screen.battle_state.get_units_by_side("right")
	_expect(right_units.size() == 1, "right side auto deploys one affordable unit", failures)
	_expect(_any_right_unit_out_of_deployment(right_units), "right auto unit moves during its side flow", failures)
	_expect(screen.turn_controller.current_side == "left", "right advance returns to left side", failures)
	_expect(screen.turn_controller.turn_number == 2, "round advances after both sides act", failures)

	screen._advance_turn()
	await process_frame
	var moved_left_unit: Dictionary = screen.battle_state.get_unit_by_id(left_unit_id)
	_expect(not moved_left_unit.is_empty(), "left unit remains trackable after turns", failures)
	_expect(int(moved_left_unit.get("column", 0)) > left_start_column, "left unit moved forward through advance turn", failures)
	_expect(screen.status_label.text.find("我方行动") >= 0, "status shows latest acting side", failures)
	_expect(screen.star_label.text.find("第 2 回合") >= 0, "status bar shows current round", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M6b turn button smoke checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _any_right_unit_out_of_deployment(right_units: Array) -> bool:
	const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
	for right_unit: Dictionary in right_units:
		var col := int(right_unit.get("column", 0))
		var row := int(right_unit.get("row", 0))
		if BoardModelScript.get_zone_for_column(col, row) != BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
