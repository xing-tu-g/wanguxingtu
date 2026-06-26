extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(not screen.unit_detail_panel.visible, "detail panel stays hidden after deploying to an empty cell", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "clicking an occupied cell opens the unit detail panel", failures)
	_expect(screen.selected_detail_unit_id != "", "opened detail tracks the selected unit id", failures)
	_expect(_contains_any(screen.unit_detail_title.text, ["关羽", "Guan Yu"]), "detail title shows the unit name", failures)
	_expect(screen.unit_detail_title.text.length() >= 2, "detail title has readable identity text", failures)
	var detail_text: String = screen.unit_detail_body.text
	_expect(detail_text.find("8/8") >= 0, "detail body shows HP values", failures)
	_expect(detail_text.find("4") >= 0, "detail body shows attack value", failures)
	_expect(detail_text.find("1") >= 0, "detail body shows range value", failures)
	_expect(detail_text.find("3") >= 0, "detail body shows movement value", failures)
	var full_detail_text := "%s\n%s" % [screen.unit_detail_title.text, detail_text]
	_expect(_contains_any(full_detail_text, ["关羽", "Guan Yu"]), "detail keeps identity context", failures)
	_expect(not full_detail_text.contains("warrior"), "detail hides raw class labels", failures)
	_expect(detail_text.length() > 40, "detail body has stat and skill content", failures)
	var selected_style: StyleBoxFlat = screen.cell_buttons["2,3"].get_theme_stylebox("normal")
	_expect(selected_style.border_color == screen.COLOR_HIGHLIGHT_SELECTED, "selected detail cell gets a cyan border", failures)

	screen._hide_unit_detail()
	await process_frame
	_expect(not screen.unit_detail_panel.visible, "close action hides the detail panel", failures)
	_expect(screen.selected_detail_unit_id == "", "close action clears selected detail unit", failures)

	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	screen._reset_debug_battle()
	await process_frame
	_expect(not screen.unit_detail_panel.visible, "reset hides the detail panel", failures)

	screen.queue_free()
	if failures.is_empty():
		print("M11 unit detail overlay checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)


func _contains_any(text: String, fragments: Array) -> bool:
	for fragment in fragments:
		if text.find(str(fragment)) >= 0:
			return true
	return false
