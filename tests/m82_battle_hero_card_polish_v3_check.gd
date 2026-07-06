extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_hero_card_layout(screen, failures)
	_check_hint_bar_clearance(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M82 battle HeroCard polish v3 checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hero_card_layout(screen: Control, failures: Array[String]) -> void:
	var button: Button = screen.hero_buttons[0]
	var name_band := button.get_node_or_null("HandCardContainer/NameBand") as PanelContainer
	_expect(name_band != null, "HeroCard uses top name band", failures)
	var cost_badge_panel := button.get_node_or_null("HandCardContainer/CostBadge") as PanelContainer
	_expect(cost_badge_panel != null and cost_badge_panel.offset_top < 0.0 and cost_badge_panel.offset_left < 0.0, "scheme C cost badge sits on top-left corner", failures)
	var cost_badge := button.get_node_or_null("HandCardContainer/CostBadge/CostBadgeInner/CostItem/Icon") as TextureRect
	_expect(cost_badge != null, "HeroCard uses scheme C cost badge", failures)
	var portrait_stage := button.get_node_or_null("HandCardContainer/PortraitStage") as Control
	_expect(portrait_stage != null and portrait_stage.custom_minimum_size.y >= 110.0, "portrait stage dominates card height", failures)
	var portrait := button.get_node_or_null("HandCardContainer/PortraitStage/Portrait") as TextureRect
	_expect(portrait != null and portrait.anchor_top < 0.0 and portrait.anchor_bottom > 1.0, "portrait can break card frame slightly", failures)
	var stats_row := button.get_node_or_null("HandCardContainer/BottomStatBar") as HBoxContainer
	_expect(stats_row != null, "HeroCard has bottom stat bar", failures)
	if stats_row != null:
		_expect(stats_row.get_node_or_null("CostItem") == null, "bottom stat bar does not duplicate cost", failures)
		_expect(stats_row.get_node_or_null("HpItem/Icon") != null, "stats row includes hp icon", failures)
		_expect(stats_row.get_node_or_null("AttackItem/Icon") != null, "stats row includes attack icon", failures)
		_expect(stats_row.get_node_or_null("MoveItem") == null, "small hand card does not show move", failures)
		_expect(stats_row.get_node_or_null("RangeItem") == null, "small hand card does not show range", failures)
	_expect(button.get_node_or_null("HandCardContainer/HeroCardBody") == null, "visible HeroCard no longer uses data-panel row layout", failures)


func _check_hint_bar_clearance(screen: Control, failures: Array[String]) -> void:
	_expect(screen.first_deploy_hint_panel.custom_minimum_size.y <= 48.0, "tutorial hint is compact", failures)
	_expect(screen.first_deploy_hint_panel.offset_bottom <= -270.0, "tutorial hint clears hand cards", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
