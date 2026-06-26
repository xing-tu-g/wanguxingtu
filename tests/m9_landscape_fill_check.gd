extends SceneTree

const HomeScreenScene: PackedScene = preload("res://scenes/ui/HomeScreen.tscn")
const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")


func _init() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	var failures: Array[String] = []
	_check_home_landscape_layout(failures)
	await process_frame
	_check_battle_landscape_layout(failures)
	await process_frame

	if failures.is_empty():
		print("M9 landscape fill checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_home_landscape_layout(failures: Array[String]) -> void:
	var screen = HomeScreenScene.instantiate()
	root.add_child(screen)
	var layout: VBoxContainer = screen.get_node("Margin/Layout")
	var hero_row: HBoxContainer = screen.get_node("Margin/Layout/HeroRow")
	var feature_panel: PanelContainer = screen.get_node("Margin/Layout/HeroRow/FeaturePanel")
	var actions: VBoxContainer = screen.get_node("Margin/Layout/HeroRow/Actions")
	_expect(layout.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "home layout expands across landscape width", failures)
	_expect(hero_row.size_flags_vertical == Control.SIZE_EXPAND_FILL, "home hero row fills vertical landscape space", failures)
	_expect(feature_panel.custom_minimum_size.x >= 640.0, "home feature panel uses the left landscape area", failures)
	_expect(actions.custom_minimum_size.x >= 520.0, "home action column has a wide mobile touch area", failures)
	screen.queue_free()


func _check_battle_landscape_layout(failures: Array[String]) -> void:
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var board_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/CenterBoardStack/BattleArea/BoardPanel")
	var player_master_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/PlayerMasterPanel")
	var enemy_master_panel: PanelContainer = screen.get_node("Margin/Layout/DuelArea/EnemyMasterPanel")
	var bottom_hand_bar: HBoxContainer = screen.get_node("Margin/Layout/BottomHandBar")
	var first_cell: Button = screen.cell_buttons["1,1"]
	_expect(board_panel.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "battle board expands between both masters", failures)
	_expect(player_master_panel.custom_minimum_size.x >= 220.0, "left master panel is visible in landscape battle", failures)
	_expect(enemy_master_panel.custom_minimum_size.x >= 220.0, "right master panel is visible in landscape battle", failures)
	_expect(bottom_hand_bar.custom_minimum_size.y >= 140.0, "bottom hand bar reserves card area", failures)
	_expect(first_cell.custom_minimum_size.x >= 112.0, "board cells are larger for landscape phone tapping", failures)
	_expect(first_cell.custom_minimum_size.y >= 88.0, "board cells are taller for landscape phone tapping", failures)
	screen.queue_free()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
