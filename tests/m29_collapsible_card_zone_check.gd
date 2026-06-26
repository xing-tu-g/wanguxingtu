extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_card_zone_starts_collapsed(failures)
	await _check_expand_shows_full_card_detail(failures)
	await _check_deploy_updates_expanded_discard_detail(failures)
	await _check_reset_keeps_collapsed_state_but_refreshes_content(failures)
	await process_frame

	if failures.is_empty():
		print("M29 collapsible card zone checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_card_zone_starts_collapsed(failures: Array[String]) -> void:
	var screen = await _make_screen()
	_expect(screen.card_zone_collapsed, "card zone starts collapsed", failures)
	_expect(screen.card_zone_toggle_button.text == "展开牌区", "card zone toggle starts with expand label", failures)
	_expect(not screen.card_zone_detail_label.visible, "card zone detail starts hidden", failures)
	_expect(screen.card_zone_summary_label.text.find("关羽(5)") >= 0, "summary shows card cost", failures)
	screen.queue_free()


func _check_expand_shows_full_card_detail(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	await process_frame
	_expect(not screen.card_zone_collapsed, "toggle expands card zone", failures)
	_expect(screen.card_zone_toggle_button.text == "收起牌区", "expanded card zone shows collapse label", failures)
	_expect(screen.card_zone_detail_label.visible, "expanded card zone shows details", failures)
	_expect(screen.card_zone_detail_label.text.find("[b]我方[/b]：牌库 3｜手牌 3｜弃牌 0") >= 0, "detail shows player card counts", failures)
	_expect(screen.card_zone_detail_label.text.find("[b]敌方[/b]：牌库 3｜手牌 3｜弃牌 0") >= 0, "detail shows enemy card counts", failures)
	_expect(screen.card_zone_detail_label.text.find("详细牌序属于后台数据") >= 0, "detail explains hidden backend card order", failures)
	_expect(screen.card_zone_detail_label.text.find("关羽(5)") < 0, "detail hides exact card names", failures)
	screen.queue_free()


func _check_deploy_updates_expanded_discard_detail(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	_expect(screen.card_zone_detail_label.visible, "detail remains visible after deployment", failures)
	_expect(screen.card_zone_detail_label.text.find("[b]我方[/b]：牌库 3｜手牌 2｜弃牌 1") >= 0, "detail count reflects deployment discard", failures)
	_expect(screen.card_zone_summary_label.text.find("我方 牌库：3  手牌：周瑜(5)、张角(5)  弃牌：关羽(5)") >= 0, "summary shows deployed card moving to discard", failures)
	screen.queue_free()


func _check_reset_keeps_collapsed_state_but_refreshes_content(failures: Array[String]) -> void:
	var screen = await _make_screen()
	screen._toggle_card_zone()
	screen._toggle_card_zone()
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	screen.selected_hero_id = "guanyu"
	screen._deploy_selected_to_cell(2, 3)
	await process_frame
	screen._reset_debug_battle()
	await process_frame
	_expect(screen.card_zone_collapsed, "reset keeps current collapsed card-zone state", failures)
	_expect(not screen.card_zone_detail_label.visible, "collapsed detail remains hidden after reset", failures)
	_expect(screen.card_zone_summary_label.text.find("我方 牌库：3  手牌：关羽(5)、周瑜(5)、张角(5)  弃牌：无") >= 0, "reset refreshes summary with full hand and empty discard", failures)
	screen.queue_free()


func _make_screen():
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
