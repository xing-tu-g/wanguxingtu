extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const ManualBattleValidationV1Script: GDScript = preload("res://scripts/tools/ManualBattleValidationV1.gd")

const OUTPUT_DIR := "res://tmp/manual_validation"


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var ok := true
	for scenario: Dictionary in ManualBattleValidationV1Script.scenarios():
		ok = await _capture_scenario(scenario) and ok
	if ok:
		print("MANUAL_BATTLE_VALIDATION_SCREENSHOTS_CLEAN")
		quit(0)
		return
	printerr("MANUAL_BATTLE_VALIDATION_SCREENSHOTS_FAILED")
	quit(1)


func _capture_scenario(scenario: Dictionary) -> bool:
	var hero_id := str(scenario.get("hero_id", ""))
	var scenario_type := str(scenario.get("scenario_type", ""))
	var player_deck := [hero_id, "guanyu", "machao", "zhangfei", "xusheng"]
	var enemy_deck := _fixture_ids(scenario.get("enemies", []))
	if enemy_deck.is_empty():
		enemy_deck = ["caoren", "xuchu", "dianwei", "huangzhong", "yanliang"]
	var screen: Control = BattleScreenScene.instantiate()
	screen.set_screen_data({
		"manual_battle_test_mode": true,
		"manual_battle_test_name": "%s / %s" % [hero_id, scenario_type],
		"player_deck": player_deck,
		"enemy_deck": enemy_deck,
	})
	root.add_child(screen)
	await _settle_frames(8)
	screen.battle_state.reset()
	screen.turn_controller.setup(screen.battle_state, BoardModelScript.SIDE_LEFT)
	screen.battle_state.terrain_system.generate_deterministic(1)
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.battle_state.set_star_power(BoardModelScript.SIDE_RIGHT, 10)
	var focus_cell: Vector2i = scenario.get("focus_cell", Vector2i(2, 3))
	screen.battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_LEFT, focus_cell.x, focus_cell.y)
	for ally: Dictionary in scenario.get("allies", []):
		_place_fixture_unit(screen, str(ally.get("id", "")), BoardModelScript.SIDE_LEFT, ally.get("cell", Vector2i.ZERO), int(ally.get("hp", 0)))
	for enemy: Dictionary in scenario.get("enemies", []):
		_place_fixture_unit(screen, str(enemy.get("id", "")), BoardModelScript.SIDE_RIGHT, enemy.get("cell", Vector2i.ZERO), int(enemy.get("hp", 0)))
	screen._refresh_board()
	screen._update_status("Manual Validation: %s / %s" % [screen._hero_name(hero_id), scenario_type])
	await _settle_frames(8)
	var ok := await _save_viewport("%s_%s.png" % [hero_id, scenario_type])
	screen.queue_free()
	await process_frame
	return ok


func _fixture_ids(fixtures: Array) -> Array:
	var ids: Array = []
	for fixture: Dictionary in fixtures:
		var hero_id := str(fixture.get("id", ""))
		if not hero_id.is_empty() and not ids.has(hero_id):
			ids.append(hero_id)
	return ids


func _place_fixture_unit(screen: Control, hero_id: String, side: String, cell: Vector2i, hp_override: int = 0) -> void:
	var hero_def: Dictionary = screen.battle_state.get_hero_def(hero_id)
	if hero_def.is_empty():
		return
	var unit_data: Dictionary = screen.battle_state.build_unit_data(hero_id, hero_def)
	if hp_override > 0:
		unit_data["hp"] = hp_override
		unit_data["max_hp"] = maxi(hp_override, int(unit_data.get("max_hp", hp_override)))
	screen.battle_state.create_unit_instance(unit_data, side, cell.x, cell.y)


func _save_viewport(file_name: String) -> bool:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("SCREENSHOT_FAILED: %s" % file_name)
		return false
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	image.save_png(path)
	return true


func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
