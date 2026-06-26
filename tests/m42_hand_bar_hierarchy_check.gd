extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_selected_hand_card_visual_hierarchy(screen, failures)
	await _check_selection_switch_updates_visuals(screen, failures)
	_check_unavailable_cards_are_dimmed(screen, failures)
	await process_frame

	screen.queue_free()
	if failures.is_empty():
		print("M42 hand bar hierarchy checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_selected_hand_card_visual_hierarchy(screen: Control, failures: Array[String]) -> void:
	var selected_button: Button = screen.hero_buttons["guanyu"]
	var normal_button: Button = screen.hero_buttons["zhouyu"]
	_expect(selected_button.text.find("● 已选上阵") >= 0, "selected hand card has explicit selected marker", failures)
	_expect(selected_button.text.find("*5") >= 0, "selected hand card shows compact fee badge", failures)
	_expect(selected_button.text.find("蜀") >= 0, "selected hand card shows faction", failures)
	_expect(selected_button.text.find("战士") < 0 and selected_button.text.find("蜀·") < 0, "selected hand card hides class row", failures)
	_expect(selected_button.custom_minimum_size.y > normal_button.custom_minimum_size.y, "selected hand card is visually raised/taller", failures)
	var selected_style := selected_button.get_theme_stylebox("normal") as StyleBoxFlat
	var normal_style := normal_button.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(selected_style.border_width_left > normal_style.border_width_left, "selected hand card has stronger border", failures)
	_expect(selected_button.get_theme_font_size("font_size") > normal_button.get_theme_font_size("font_size"), "selected hand card uses larger font", failures)


func _check_selection_switch_updates_visuals(screen: Control, failures: Array[String]) -> void:
	screen._select_hero("zhouyu")
	await process_frame
	var old_button: Button = screen.hero_buttons["guanyu"]
	var new_button: Button = screen.hero_buttons["zhouyu"]
	_expect(old_button.text.find("可部署") >= 0, "previous selection returns to deployable label", failures)
	_expect(new_button.text.find("● 已选上阵") >= 0, "new selection gets selected marker", failures)
	_expect(new_button.custom_minimum_size.y > old_button.custom_minimum_size.y, "new selection becomes taller", failures)


func _check_unavailable_cards_are_dimmed(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(1, 1)
	await screen.get_tree().process_frame
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	var zhangjiao_button: Button = screen.hero_buttons["zhangjiao"]
	_expect(zhouyu_button.disabled, "deployed card becomes unavailable", failures)
	_expect(zhouyu_button.text.find("已出") >= 0, "deployed card shows spent state", failures)
	var disabled_style := zhouyu_button.get_theme_stylebox("disabled") as StyleBoxFlat
	var normal_style := zhangjiao_button.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(disabled_style.bg_color.v < normal_style.bg_color.v, "unavailable hand card is dimmed", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
