extends SceneTree

const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	_check_hero_data(failures)
	_check_battle_screen_buttons_and_deploy(failures)
	await process_frame

	if failures.is_empty():
		print("M13 more hero sample checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hero_data(failures: Array[String]) -> void:
	var state = BattleStateScript.new()
	var zhaoyun: Dictionary = state.get_hero_def("zhaoyun")
	var zhangfei: Dictionary = state.get_hero_def("zhangfei")
	var sunshangxiang: Dictionary = state.get_hero_def("sunshangxiang")
	_expect(not zhaoyun.is_empty(), "Zhaoyun sample exists in hero data", failures)
	_expect(not zhangfei.is_empty(), "Zhangfei sample exists in hero data", failures)
	_expect(not sunshangxiang.is_empty(), "Sunshangxiang sample exists in hero data", failures)
	_expect(str(zhaoyun.get("class", "")) == "warrior", "Zhaoyun is a warrior sample", failures)
	_expect(bool(zhaoyun.get("can_pass_blockers", false)), "Zhaoyun carries blocker-pass prototype flag", failures)
	_expect(zhaoyun.get("skill_ids", []).has("zhaoyun_dash"), "Zhaoyun exposes blocker-pass skill text", failures)
	_expect(str(zhangfei.get("class", "")) == "tank", "Zhangfei is a tank sample", failures)
	_expect(int(zhangfei.get("physical_block", 0)) >= 2, "Zhangfei has physical block", failures)
	_expect(zhangfei.get("skill_ids", []).has("zhangfei_guard"), "Zhangfei exposes adjacent guard skill text", failures)
	_expect(str(sunshangxiang.get("class", "")) == "archer", "Sunshangxiang is an archer sample", failures)
	_expect(int(sunshangxiang.get("range", 0)) >= 4, "Sunshangxiang has long range", failures)
	_expect(sunshangxiang.get("skill_ids", []).has("sunshangxiang_combo"), "Sunshangxiang exposes combo skill text", failures)


func _check_battle_screen_buttons_and_deploy(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.hero_buttons.size() == 6, "battle screen builds six selectable hero buttons", failures)
	_expect(screen.hero_buttons.has("zhaoyun"), "battle screen includes Zhaoyun button", failures)
	_expect(screen.hero_buttons.has("zhangfei"), "battle screen includes Zhangfei button", failures)
	_expect(screen.hero_buttons.has("sunshangxiang"), "battle screen includes Sunshangxiang button", failures)
	_expect(_contains_any(str(screen.hero_buttons["sunshangxiang"].text), ["孙尚香", "Sun Shangxiang"]), "dynamic button shows Sunshangxiang name", failures)

	screen.selected_hero_id = "sunshangxiang"
	screen._deploy_selected_to_cell(2, 4)
	await process_frame
	var placed: Dictionary = screen.battle_state.board.get_unit_at(2, 4)
	_expect(str(placed.get("hero_id", "")) == "sunshangxiang", "new archer sample deploys from battle screen", failures)
	_expect(screen.battle_state.get_star_power("left") == 1, "new sample cost spends four star power", failures)
	screen._deploy_selected_to_cell(2, 4)
	await process_frame
	_expect(screen.unit_detail_panel.visible, "new sample can open unit detail overlay", failures)
	_expect(screen.unit_detail_body.text.find("射手") >= 0, "new sample detail localizes archer class", failures)
	_expect(screen.unit_detail_body.text.find("射程") >= 0, "new sample detail shows range", failures)
	_expect(screen.unit_detail_body.text.find("枭姬连弩") >= 0, "new sample detail shows combo skill", failures)
	screen.queue_free()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)


func _contains_any(text: String, fragments: Array) -> bool:
	for fragment in fragments:
		if text.find(str(fragment)) >= 0:
			return true
	return false
