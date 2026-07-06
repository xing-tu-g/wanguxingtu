extends SceneTree

const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")
const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")

var _original_save: Dictionary = {}
var _had_original_save := false


func _init() -> void:
	var failures: Array[String] = []
	_backup_save()
	_reset_star_track_save()
	_check_divisions(failures)
	_check_match_ranges(failures)
	_check_wait_and_streak_expansion(failures)
	_check_result_deltas_and_protection(failures)
	_check_anti_smurf_adjustment(failures)
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


func _check_divisions(failures: Array[String]) -> void:
	_expect(str(StarTrackSystemScript.division_for_value(0).get("id", "")) == "awakening", "0 maps to awakening", failures)
	_expect(str(StarTrackSystemScript.division_for_value(500).get("id", "")) == "formation", "500 maps to formation", failures)
	_expect(str(StarTrackSystemScript.division_for_value(1500).get("id", "")) == "flow", "1500 maps to flow", failures)
	_expect(str(StarTrackSystemScript.division_for_value(3000).get("id", "")) == "domain", "3000 maps to domain", failures)
	_expect(str(StarTrackSystemScript.division_for_value(5000).get("id", "")) == "astral", "5000 maps to astral", failures)
	_expect(str(StarTrackSystemScript.division_for_value(7500).get("id", "")) == "core", "7500 maps to core", failures)


func _check_match_ranges(failures: Array[String]) -> void:
	var awakening: Dictionary = StarTrackSystemScript.match_range_for_value(250)
	_expect(int(awakening.get("base_range", 0)) == 200, "awakening base range is 200", failures)
	_expect(int(awakening.get("min", -1)) == 0, "awakening match minimum is protected at 0", failures)
	_expect(int(awakening.get("max", -1)) == 800, "awakening can only match up to 800", failures)
	_expect(StarTrackSystemScript.can_match(250, 799), "awakening can match within protected ceiling", failures)
	_expect(not StarTrackSystemScript.can_match(250, 801), "awakening cannot match above protected ceiling", failures)

	var formation: Dictionary = StarTrackSystemScript.match_range_for_value(1000)
	_expect(int(formation.get("base_range", 0)) == 300, "formation base range is 300", failures)
	_expect(int(formation.get("min", -1)) == 700, "formation minimum uses +/-300", failures)
	_expect(int(formation.get("max", -1)) == 1300, "formation maximum uses +/-300", failures)
	_expect(StarTrackSystemScript.can_match(1000, 1200), "same division candidate can match", failures)
	_expect(not StarTrackSystemScript.can_match(1400, 1600), "adjacent division waits for cross-division expansion", failures)


func _check_wait_and_streak_expansion(failures: Array[String]) -> void:
	var expanded: Dictionary = StarTrackSystemScript.match_range_for_value(1000, 11.0)
	_expect(int(expanded.get("effective_range", 0)) == 360, "wait >10s expands range by 20 percent", failures)

	var crossed: Dictionary = StarTrackSystemScript.match_range_for_value(1400, 21.0)
	_expect(bool(crossed.get("can_cross_division", false)), "wait >20s allows cross-division matching", failures)
	_expect(StarTrackSystemScript.can_match(1400, 1600, 21.0), "wait >20s can match adjacent division", failures)
	_expect(str(StarTrackSystemScript.candidate_priority(1400, 1600, 21.0)) == "adjacent_division", "adjacent priority is explicit after wait", failures)

	var streaked: Dictionary = StarTrackSystemScript.match_range_for_value(3200, 0.0, 5)
	_expect(bool(streaked.get("win_streak_expanded", false)), "win streak >=5 expands range", failures)
	_expect(int(streaked.get("effective_range", 0)) > 700, "win streak range exceeds domain base", failures)


func _check_result_deltas_and_protection(failures: Array[String]) -> void:
	StarTrackSystemScript.save_state(0)
	var win_result: Dictionary = StarTrackSystemScript.apply_match_result("left_wins")
	_expect(int(win_result.get("delta", 0)) == 30, "win grants +30", failures)

	StarTrackSystemScript.save_state(200)
	var protected_loss: Dictionary = StarTrackSystemScript.apply_match_result("right_wins")
	_expect(int(protected_loss.get("delta", 0)) == 0, "awakening loss does not drop value", failures)

	StarTrackSystemScript.save_state(2000)
	var normal_loss: Dictionary = StarTrackSystemScript.apply_match_result("right_wins")
	_expect(int(normal_loss.get("delta", 0)) == -10, "flow loss drops -10", failures)

	StarTrackSystemScript.save_state(9990)
	var capped_win: Dictionary = StarTrackSystemScript.apply_match_result("left_wins")
	_expect(int(capped_win.get("after", {}).get("current_star_track_value", 0)) == 10000, "star track clamps at 10000", failures)


func _check_anti_smurf_adjustment(failures: Array[String]) -> void:
	var high_win: Dictionary = StarTrackSystemScript.delta_for_match_result("left_wins", 3000, 1000)
	_expect(int(high_win.get("delta", 0)) == 15, "high player reward is reduced against much lower opponent", failures)
	_expect(bool(high_win.get("anti_smurf", {}).get("triggered", false)), "high-vs-low anti-smurf triggers", failures)

	var low_loss: Dictionary = StarTrackSystemScript.delta_for_match_result("right_wins", 2000, 4000)
	_expect(int(low_loss.get("delta", 0)) == 0, "low player loss is reduced against much higher opponent", failures)
	_expect(bool(low_loss.get("anti_smurf", {}).get("triggered", false)), "low-vs-high anti-smurf triggers", failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("M99 star track matchmaking checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
