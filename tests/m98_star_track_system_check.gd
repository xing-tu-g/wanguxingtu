extends SceneTree

const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")
const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")
const BattleReportManagerScript: GDScript = preload("res://scripts/data/BattleReportManager.gd")
const MainMenuScene: PackedScene = preload("res://scenes/ui/MainMenuScene.tscn")
const DeckBuilderScene: PackedScene = preload("res://scenes/ui/DeckBuilderScene.tscn")

var _original_save: Dictionary = {}
var _had_original_save := false


func _init() -> void:
	var failures: Array[String] = []
	_backup_save()
	_reset_star_track_save()
	_check_curve_and_progress(failures)
	_check_battle_result_application(failures)
	await _check_main_menu_star_track_ui(failures)
	await _check_deck_builder_unlock_control(failures)
	_restore_save()
	_finish(failures)


func _backup_save() -> void:
	_original_save = SaveServiceScript.load_game()
	_had_original_save = not _original_save.is_empty()


func _restore_save() -> void:
	if _had_original_save:
		SaveServiceScript.save_game(_original_save)
	else:
		SaveServiceScript.delete_save()


func _reset_star_track_save() -> void:
	var save_data: Dictionary = SaveServiceScript.create_default_save()
	SaveServiceScript.save_game(save_data)


func _check_curve_and_progress(failures: Array[String]) -> void:
	var table: Array = StarTrackSystemScript.build_level_threshold_table()
	_expect(table.size() == 100, "star track keeps a compatibility 1-100 threshold table", failures)
	_expect(int(table[0]) == 0, "level 1 threshold is zero", failures)
	_expect(int(table[99]) == 10000, "star track caps at 10000", failures)
	_expect(str(StarTrackSystemScript.division_for_value(0).get("id", "")) == "awakening", "0 enters awakening division", failures)
	_expect(str(StarTrackSystemScript.division_for_value(500).get("id", "")) == "formation", "500 enters formation division", failures)
	_expect(str(StarTrackSystemScript.division_for_value(7500).get("id", "")) == "core", "7500 enters core division", failures)
	var progress: Dictionary = StarTrackSystemScript.progress_for_value(0)
	_expect(int(progress.get("to_next", 0)) == 500, "progress reports distance to next division", failures)


func _check_battle_result_application(failures: Array[String]) -> void:
	var win_result: Dictionary = StarTrackSystemScript.apply_battle_result("left_wins")
	_expect(int(win_result.get("delta", 0)) == 30, "win grants +30 star track", failures)
	_expect(int(win_result.get("after", {}).get("current_star_track_value", 0)) == 30, "win increases stored star track value", failures)

	StarTrackSystemScript.save_state(490)
	var division_result: Dictionary = StarTrackSystemScript.apply_battle_result("left_wins")
	_expect(bool(division_result.get("division_up", false)), "win crossing threshold enters next division", failures)
	_expect(str(division_result.get("after", {}).get("division", {}).get("id", "")) == "formation", "division after threshold is formation", failures)

	StarTrackSystemScript.save_state(0)
	var loss_result: Dictionary = StarTrackSystemScript.apply_battle_result("right_wins")
	_expect(int(loss_result.get("delta", 0)) == 0, "awakening loss is protected", failures)
	_expect(int(loss_result.get("after", {}).get("current_star_track_value", 0)) == 0, "loss remains protected at zero", failures)

	StarTrackSystemScript.save_state(1500)
	var ranked_loss: Dictionary = StarTrackSystemScript.apply_battle_result("right_wins")
	_expect(int(ranked_loss.get("delta", 0)) == -10, "higher division loss applies -10 star track", failures)

	var report: Dictionary = BattleReportManagerScript.record_report({
		"outcome": "left_wins",
		"round_number": 1,
		"stats": {},
		"battle_log": [],
	})
	_expect(report.has("star_track_result"), "battle report records star track progression result", failures)


func _check_main_menu_star_track_ui(failures: Array[String]) -> void:
	StarTrackSystemScript.save_state(75)
	var screen: Control = MainMenuScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.has_node("StarTrackPanel"), "main menu shows star track panel", failures)
	_expect(screen.has_node("StarTrackPanel/StarTrackMargin/StarTrackLayout/StarTrackProgress"), "main menu shows star track progress bar", failures)
	var label: Label = screen.get_node("StarTrackPanel/StarTrackMargin/StarTrackLayout/StarTrackHeader/StarTrackLevel")
	_expect(label.text.contains("星轨 75"), "main menu star track value label is readable", failures)
	_expect(label.text.contains("初星"), "main menu star track division label is readable", failures)
	screen.queue_free()


func _check_deck_builder_unlock_control(failures: Array[String]) -> void:
	StarTrackSystemScript.save_state(0)
	var screen: Control = DeckBuilderScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen._all_heroes.size() == 55, "deck builder still displays full hero roster", failures)
	_expect(StarTrackSystemScript.unlocked_hero_ids(1).size() == 20, "level 1 unlocks basic 20-card pool", failures)
	var locked_count := 0
	for child in screen._grid.get_children():
		if child is Button and child.disabled:
			locked_count += 1
	_expect(locked_count > 0, "deck builder disables locked heroes", failures)
	_expect(screen.player_deck.size() == 20, "default player deck remains 20 cards from unlocked pool", failures)
	screen.queue_free()


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("M98 star track system checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
