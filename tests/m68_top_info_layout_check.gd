extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_top_bar_split(screen, failures)
	await _check_turn_info_sync(screen, failures)
	await _check_hand_status_labels(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M68 top info layout checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_top_bar_split(screen: Control, failures: Array[String]) -> void:
	var top_status_bar: VBoxContainer = screen.get_node("Margin/Layout/TopStatusBar")
	var status_label: Label = screen.get_node("Margin/Layout/TopStatusBar/HeaderRow/StatusLabel")
	var turn_info_panel: PanelContainer = screen.get_node("Margin/Layout/TopStatusBar/StatusRow/TurnInfoPanel")
	var turn_info_label: Label = screen.get_node("Margin/Layout/TopStatusBar/StatusRow/TurnInfoPanel/TurnInfoLabel")
	var tutorial_progress: HBoxContainer = screen.get_node("Margin/Layout/TopStatusBar/StatusRow/TutorialProgress")
	_expect(top_status_bar is VBoxContainer, "top status bar is split into two rows", failures)
	_expect(top_status_bar.custom_minimum_size.y >= 132.0, "top status bar reserves enough two-row height", failures)
	_expect(status_label.get_parent().name == "HeaderRow", "main instruction lives in header row", failures)
	_expect(status_label.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "main instruction gets flexible width", failures)
	_expect(turn_info_panel.custom_minimum_size.x >= 340.0, "turn info is isolated in its own panel", failures)
	_expect(turn_info_label.text.contains("\n"), "turn info uses two-line compact display", failures)
	_expect(tutorial_progress.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "tutorial chips use the remaining second-row width", failures)
	_expect(screen.tutorial_progress_label.text == "新手流程", "tutorial title is short", failures)


func _check_turn_info_sync(screen: Control, failures: Array[String]) -> void:
	_expect(screen.turn_info_label.text.contains("我方行动 - 向右推进"), "turn info starts with player action cue", failures)
	screen._advance_turn()
	await process_frame
	_expect(screen.turn_info_label.text.contains("敌方行动 - 向左推进"), "turn info syncs after advancing turn", failures)
	_expect(screen.star_label.text.contains("敌方行动"), "compact star label still mirrors active side", failures)


func _check_hand_status_labels(screen: Control, failures: Array[String]) -> void:
	screen._update_hero_buttons()
	await process_frame
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	var text := str(zhouyu_button.text)
	_expect(text.contains("周瑜"), "hand card keeps hero name", failures)
	_expect(text.contains("*"), "hand card keeps cost badge", failures)
	_expect(text.contains("吴"), "hand card keeps faction short tag", failures)
	_expect(text.contains("阵营：") == false, "hand card avoids long faction prefix", failures)
	_expect(text.contains("职业") == false and text.contains("弓") == false and text.contains("相") == false, "hand card avoids class labels", failures)
	_expect(text.contains("部署") or text.contains("回合") or text.contains("已出") or text.contains("候补"), "hand card keeps short state tag", failures)
	_expect(zhouyu_button.custom_minimum_size.y <= 116.0, "hand card remains compact", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
