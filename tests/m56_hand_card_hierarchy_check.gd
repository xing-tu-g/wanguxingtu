extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.get_script():
		failures.append("FAIL: battle screen script failed to load")
		_finish(screen, failures)
		return

	var guanyu_button: Button = screen.hero_buttons["guanyu"]
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	var zhangjiao_button: Button = screen.hero_buttons["zhangjiao"]
	_expect(guanyu_button.text.contains("● 已选上阵"), "initial selected card shows selected label", failures)
	_expect(zhouyu_button.text.contains("可部署"), "initial affordable card shows deployable label", failures)
	_expect(zhouyu_button.text.contains("点蓝区部署"), "initial affordable card gives next action", failures)
	_expect(_normal_style(zhouyu_button).get_border_width(SIDE_LEFT) >= 5, "affordable card has stronger border", failures)

	screen._select_hero("guanyu")
	await process_frame
	_expect(guanyu_button.text.contains("● 已选上阵"), "selected card has selected label", failures)
	_expect(guanyu_button.custom_minimum_size.x > zhouyu_button.custom_minimum_size.x, "selected card is visually larger", failures)
	_expect(_normal_style(guanyu_button).get_border_width(SIDE_LEFT) > _normal_style(zhouyu_button).get_border_width(SIDE_LEFT), "selected card has strongest border", failures)

	screen.battle_state.set_star_power(screen.BoardModelScript.SIDE_LEFT, 0)
	screen._update_hero_buttons()
	await process_frame
	_expect(zhouyu_button.text.contains("星力不足"), "unaffordable hand card shows low-star label", failures)
	_expect(zhouyu_button.text.contains("先推进回合"), "unaffordable hand card gives recovery action", failures)
	_expect(_normal_style(zhouyu_button).get_border_width(SIDE_LEFT) < _normal_style(guanyu_button).get_border_width(SIDE_LEFT), "unaffordable card is below selected hierarchy", failures)

	screen.battle_state.set_star_power(screen.BoardModelScript.SIDE_LEFT, 10)
	screen._apply_deployment_result(screen.battle_state.deploy_hero("guanyu", screen.BoardModelScript.SIDE_LEFT, 1, 3), "guanyu", 1, 3)
	await process_frame
	_expect(guanyu_button.disabled, "deployed card is disabled", failures)
	_expect(guanyu_button.text.contains("已出"), "deployed card shows out label", failures)
	_expect(not zhangjiao_button.disabled, "remaining hand card stays usable", failures)

	_finish(screen, failures)


func _normal_style(button: Button) -> StyleBoxFlat:
	return button.get_theme_stylebox("normal") as StyleBoxFlat


func _finish(screen: Node, failures: Array[String]) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("M56 hand card hierarchy checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
