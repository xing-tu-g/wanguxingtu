extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const BATTLE_BG_PATH := "res://assets/ui/battle/background/battle_background.png"


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_background_layers(screen, failures)
	_check_board_shape_and_overlay(screen, failures)
	await _check_unit_text_stays_numeric(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M66 battle background preview checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_background_layers(screen: Control, failures: Array[String]) -> void:
	_expect(screen.battle_background_image != null, "battle art background node exists", failures)
	_expect(screen.battle_background_image.texture != null, "battle art background texture is assigned", failures)
	if screen.battle_background_image.texture != null:
		_expect(screen.battle_background_image.texture.resource_path == BATTLE_BG_PATH, "battle background uses new UI art path", failures)
	_expect(screen.battle_background_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "battle background uses 16:9 cover crop", failures)
	_expect(screen.battle_background_image.mouse_filter == Control.MOUSE_FILTER_IGNORE, "B01 background does not catch input", failures)
	_expect(screen.battle_background_image.material == null, "battle background is not darkened by depth-fade shader", failures)
	_expect(screen.background_readability_wash != null, "readability wash node exists", failures)
	_expect(screen.background_readability_wash.color.a <= 0.24, "readability wash keeps new background visible", failures)


func _check_board_shape_and_overlay(screen: Control, failures: Array[String]) -> void:
	_expect(not (screen.grid is GridContainer), "board grid uses free layout for offset rows", failures)
	_expect(screen.cell_buttons.size() == BoardModelScript.get_total_cell_count(), "cell button map matches 9-10-9-10-9 board", failures)
	var odd_row_cell: Control = screen.grid.get_node_or_null("Cell_1_1")
	var even_row_cell: Control = screen.grid.get_node_or_null("Cell_1_2")
	_expect(odd_row_cell != null and even_row_cell != null, "sample offset row cells exist", failures)
	if odd_row_cell != null and even_row_cell != null:
		_expect(odd_row_cell.position.x > even_row_cell.position.x, "odd rows are horizontally offset", failures)
	var blue_backplate := screen.cell_buttons["1,1"].get_node_or_null("GridBackplate") as TextureRect
	var mid_backplate := screen.cell_buttons["5,1"].get_node_or_null("GridBackplate") as TextureRect
	var red_backplate := screen.cell_buttons["8,1"].get_node_or_null("GridBackplate") as TextureRect
	var block_backplate := screen.cell_buttons["9,1"].get_node_or_null("GridBackplate") as TextureRect
	_expect(blue_backplate != null and blue_backplate.texture != null, "blue cell uses texture backplate", failures)
	_expect(mid_backplate != null and mid_backplate.texture != null, "mid cell uses texture backplate", failures)
	_expect(red_backplate != null and red_backplate.texture != null, "red cell uses texture backplate", failures)
	_expect(blue_backplate != null and blue_backplate.material is ShaderMaterial, "grid backplate uses alpha mask shader to remove opaque art corners", failures)
	if blue_backplate != null and blue_backplate.texture != null:
		_expect(blue_backplate.texture.resource_path.ends_with("grid_blue_idle.png") or blue_backplate.texture.resource_path.ends_with("grid_blue_hover.png"), "blue zone uses blue grid art", failures)
	if mid_backplate != null and mid_backplate.texture != null:
		_expect(mid_backplate.texture.resource_path.ends_with("grid_mid_idle.png"), "mid zone uses mid grid art", failures)
	if red_backplate != null and red_backplate.texture != null:
		_expect(red_backplate.texture.resource_path.ends_with("grid_red_idle.png"), "red zone uses red grid art", failures)
	if block_backplate != null and block_backplate.texture != null:
		_expect(block_backplate.texture.resource_path.ends_with("grid_block.png"), "terrain block uses block grid art", failures)
	_expect(screen.board_overlay_preview != null, "transparent board preview node exists", failures)
	_expect(not screen.board_overlay_preview.visible, "legacy 10x5 board preview is hidden", failures)
	_expect(screen.board_overlay_preview.mouse_filter == Control.MOUSE_FILTER_IGNORE, "transparent board preview does not catch input", failures)


func _check_unit_text_stays_numeric(screen: Control, failures: Array[String]) -> void:
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	for hand_index in range(screen.player_hand.size()):
		var hero_id := str(screen.player_hand[hand_index])
		if screen.battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
			screen._select_hand_slot(hand_index)
			break
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	var cell_button: Button = screen.cell_buttons["1,1"]
	var cell_text := str(cell_button.text)
	var hp_label := cell_button.get_node_or_null("HpLabel") as Label
	_expect(hp_label != null, "unit cell keeps HpLabel child", failures)
	if hp_label != null:
		_expect(hp_label.text.contains("/"), "unit HpLabel keeps numeric HP fraction", failures)
	_expect(not cell_text.contains("|"), "unit text does not use a text blood bar", failures)
	_expect(_count_progress_nodes(screen) == 0, "battle screen does not add progress-bar blood bars", failures)

func _count_progress_nodes(node: Node) -> int:
	var count := 0
	if node is ProgressBar or node is TextureProgressBar:
		count += 1
	for child in node.get_children():
		count += _count_progress_nodes(child)
	return count


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
