extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_background_readability(screen, failures)
	_check_master_panel_backplates(screen, failures)
	_check_hand_card_density(screen, failures)
	_check_board_shape(screen, failures)
	_check_formal_battle_ui(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M67 battle readability hierarchy checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_background_readability(screen: Control, failures: Array[String]) -> void:
	_expect(screen.background_readability_wash.color.a > 0.0 and screen.background_readability_wash.color.a <= 0.24, "main readability wash preserves visible battle art", failures)
	_expect(screen.battle_background_image != null, "battle background image exists", failures)
	_expect(screen.battle_background_image.mouse_filter == Control.MOUSE_FILTER_IGNORE, "background image ignores input", failures)


func _check_master_panel_backplates(screen: Control, failures: Array[String]) -> void:
	var player_style := screen.player_master_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var enemy_style := screen.enemy_master_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var player_portrait := screen.get_node("DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerPortrait") as TextureRect
	var enemy_portrait := screen.get_node("DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyPortrait") as TextureRect
	_expect(player_style != null and enemy_style != null, "master panel styleboxes are applied", failures)
	_expect(player_portrait != null and player_portrait.texture != null, "player master uses portrait art instead of flat placeholder", failures)
	_expect(enemy_portrait != null and enemy_portrait.texture != null, "enemy master uses portrait art", failures)
	if player_portrait != null and player_portrait.texture != null:
		_expect(player_portrait.texture.resource_path.ends_with("C01_player_astrologer.png"), "player master portrait uses C01 asset", failures)
	if enemy_portrait != null and enemy_portrait.texture != null:
		_expect(enemy_portrait.texture.resource_path.ends_with("C02_enemy_astrologer.png"), "enemy master portrait uses C02 asset", failures)
	if player_style == null or enemy_style == null:
		return
	_expect(player_style.bg_color.a >= 0.95, "player master panel has stronger backplate opacity", failures)
	_expect(enemy_style.bg_color.a >= 0.95, "enemy master panel has stronger backplate opacity", failures)
	_expect(player_style.border_color.a >= 0.95, "player master panel border is clearer", failures)
	_expect(enemy_style.border_color.a >= 0.95, "enemy master panel border is clearer", failures)
	_expect(player_style.get_border_width(SIDE_LEFT) >= 6 or enemy_style.get_border_width(SIDE_LEFT) >= 6, "active master panel keeps a strong outline", failures)


func _check_hand_card_density(screen: Control, failures: Array[String]) -> void:
	screen._update_hero_buttons()
	await process_frame
	var tray_backplate := screen.get_node_or_null("BottomHand/Controls/HeroScroll/HandTrayBackplate") as TextureRect
	_expect(tray_backplate != null and tray_backplate.texture != null, "hand tray uses explicit texture backplate", failures)
	if tray_backplate != null and tray_backplate.texture != null:
		_expect(tray_backplate.texture.resource_path.ends_with("hand_card_button_bg.png"), "hand tray backplate uses hand card art asset", failures)
		_expect(tray_backplate.material is ShaderMaterial, "hand tray masks non-transparent source background", failures)
	var zhouyu_button: Button = screen.hero_buttons["zhouyu"]
	var text := str(zhouyu_button.get_node("HandCardContainer/TopRow/NameLabel").text)
	_expect(_contains_any(text, ["周瑜", "Zhou Yu"]), "hand card keeps hero name", failures)
	_expect(str(zhouyu_button.get_node("HandCardContainer/TopRow/CostLabel").text).contains("5"), "hand card keeps cost value", failures)
	_expect(zhouyu_button.get_node_or_null("HandCardContainer/Portrait") != null, "hand card has portrait slot", failures)
	_expect(str(zhouyu_button.get_node("HandCardContainer/MetaLabel").text).length() > 0, "hand card shows faction and class meta", failures)
	_expect(zhouyu_button.custom_minimum_size.y >= 150.0, "hand card uses vertical card proportions", failures)
	var card_style := zhouyu_button.get_theme_stylebox("normal") as StyleBoxTexture
	_expect(card_style != null and card_style.texture != null, "hand card uses texture background style", failures)
	if card_style != null and card_style.texture != null:
		_expect(card_style.texture.resource_path.ends_with("hand_card_button_bg.png"), "hand card uses battle hand art asset", failures)


func _check_board_shape(screen: Control, failures: Array[String]) -> void:
	_expect(not (screen.grid is GridContainer), "board grid is not forced into 10 columns", failures)
	_expect(screen.cell_buttons.size() == BoardModelScript.get_total_cell_count(), "board model keeps 47 playable offset cells", failures)
	_expect(screen.cell_buttons.has("9,1"), "row 1 keeps ninth cell", failures)
	_expect(not screen.cell_buttons.has("10,1"), "row 1 has no phantom tenth cell", failures)
	_expect(screen.cell_buttons.has("10,2"), "row 2 keeps tenth cell", failures)


func _check_formal_battle_ui(screen: Control, failures: Array[String]) -> void:
	_expect(screen.has_node("BottomHand/Controls/HeroScroll/HeroButtons/NextDrawSlot"), "hand row exposes next auto draw slot", failures)
	_expect(not screen.tutorial_progress_row.visible, "debug tutorial progress row is hidden", failures)
	_expect(screen.first_deploy_hint_panel.custom_minimum_size.y <= 80.0, "first deploy hint is a low hint bar", failures)
	_expect(screen.first_deploy_hint_panel.offset_bottom <= -190.0, "first deploy hint stays above hand without covering board center", failures)
	var advance_text := screen.advance_turn_button.get_node_or_null("AdvanceText") as Label
	_expect(advance_text != null and advance_text.text.contains("推进"), "main action button reads as advance turn", failures)
	_expect(screen.advance_turn_button.custom_minimum_size.y >= 160.0, "main action button is visually dominant", failures)
	_expect(screen.get_node("BottomHand/Controls/ResetButton").custom_minimum_size.y <= 80.0, "reset is a secondary small action", failures)
	_expect(screen.battle_background_image.texture.resource_path.ends_with("battle_background.png"), "battle screen uses new battle background asset", failures)
	_expect(not screen.toggle_log_button.visible, "battle report/log entry is not visible during battle", failures)
	for path in ["TopBar/BackButton", "BottomHand/CardZonePanel/CardZoneLayout/CardZoneHeader/CardZoneToggleButton", "BottomHand/Controls/ResetButton", "FirstDeployHintPanel/HintMargin/HintLayout/HintFooter/FirstDeployHintButton"]:
		var button := screen.get_node(path) as Button
		var style := button.get_theme_stylebox("normal") as StyleBoxTexture
		_expect(style != null and style.texture != null, "%s uses battle art texture style" % path, failures)
		if style != null and style.texture != null:
			_expect(style.texture.resource_path.ends_with("hand_card_button_bg.png"), "%s uses shared battle button art" % path, failures)


func _contains_long_card_copy(text: String) -> bool:
	for forbidden in ["class", "skill", "HP ", "||||", "attack", "range", "move"]:
		if text.contains(forbidden):
			return true
	return false


func _contains_any(text: String, fragments: Array) -> bool:
	for fragment in fragments:
		if text.contains(str(fragment)):
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
