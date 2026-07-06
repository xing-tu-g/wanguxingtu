extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_no_initial_false_positive(screen, failures)
	_check_empty_deck_hand_and_board_loses(screen, failures)
	_check_empty_hand_with_deck_survives(screen, failures)
	_check_empty_deck_hand_with_unit_survives(screen, failures)
	_check_both_empty_deck_hand_and_board_both_fail(screen, failures)
	_check_successful_deploy_consumes_hand_card(screen, failures)

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("M20 empty deck hand board defeat checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _reset_screen(screen: Control) -> void:
	screen._reset_debug_battle()


func _check_no_initial_false_positive(screen: Control, failures: Array[String]) -> void:
	_reset_screen(screen)
	var result: Dictionary = screen._check_battle_end()
	_expect(result.is_empty(), "battle does not end while both sides still have hand cards", failures)


func _check_empty_deck_hand_and_board_loses(screen: Control, failures: Array[String]) -> void:
	_reset_screen(screen)
	screen.player_deck.clear()
	screen.player_hand.clear()
	_add_unit(screen, "enemy_anchor", BoardModelScript.SIDE_RIGHT, 8, 3)
	var result: Dictionary = screen._check_battle_end()
	_expect(str(result.get("outcome", "")) == "right_wins", "left loses when deck hand and board are empty", failures)


func _check_empty_hand_with_deck_survives(screen: Control, failures: Array[String]) -> void:
	_reset_screen(screen)
	screen.player_hand.clear()
	screen.player_deck.append("guanyu")
	var result: Dictionary = screen._check_battle_end()
	_expect(result.is_empty(), "empty hand does not lose while deck still has cards", failures)


func _check_empty_deck_hand_with_unit_survives(screen: Control, failures: Array[String]) -> void:
	_reset_screen(screen)
	screen.player_deck.clear()
	screen.player_hand.clear()
	_add_unit(screen, "left_anchor", BoardModelScript.SIDE_LEFT, 2, 3)
	var result: Dictionary = screen._check_battle_end()
	_expect(result.is_empty(), "empty deck and hand do not lose while a unit survives", failures)


func _check_both_empty_deck_hand_and_board_both_fail(screen: Control, failures: Array[String]) -> void:
	_reset_screen(screen)
	screen.player_deck.clear()
	screen.player_hand.clear()
	screen.enemy_deck.clear()
	screen.enemy_hand.clear()
	var result: Dictionary = screen._check_battle_end()
	_expect(str(result.get("outcome", "")) == "both_failed", "both sides fail when both deck hand and board are empty", failures)


func _check_successful_deploy_consumes_hand_card(screen: Control, failures: Array[String]) -> void:
	_reset_screen(screen)
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var hero_id := str(screen.player_hand[0])
	screen.selected_hero_id = hero_id
	var result: Dictionary = screen.battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_LEFT, 2, 3)
	screen._apply_deployment_result(result, hero_id, 2, 3)
	_expect(not screen.player_hand.has(hero_id), "successful player deployment consumes hand card", failures)


func _add_unit(screen: Control, unit_id: String, side: String, column: int, row: int) -> Dictionary:
	var unit_data := {
		"instance_id": unit_id,
		"entry_order": screen.battle_state.next_unit_sequence,
		"hero_id": unit_id,
		"name": unit_id,
		"max_hp": 10,
		"hp": 10,
		"attack": 2,
		"range": 1,
		"move": 1,
		"class": "warrior",
		"physical_block": 0,
		"magic_block": 0,
		"damage_type": "physical",
		"skill_ids": [],
		"statuses": {},
		"stats": {},
	}
	var result: Dictionary = screen.battle_state.create_unit_instance(unit_data, side, column, row)
	return result.get("unit", {})


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
