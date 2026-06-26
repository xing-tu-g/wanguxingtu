extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const B01_PATH := "res://assets/art/backgrounds/B01_battle_background.png"


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
	_expect(screen.battle_background_image != null, "B01 background node exists", failures)
	_expect(screen.battle_background_image.texture != null, "B01 background texture is assigned", failures)
	if screen.battle_background_image.texture != null:
		_expect(screen.battle_background_image.texture.resource_path == B01_PATH, "B01 background uses stable art path", failures)
	_expect(screen.battle_background_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "B01 background uses 16:9 cover crop", failures)
	_expect(screen.battle_background_image.mouse_filter == Control.MOUSE_FILTER_IGNORE, "B01 background does not catch input", failures)
	_expect(screen.background_readability_wash != null, "readability wash node exists", failures)
	_expect(screen.background_readability_wash.color.a >= 0.35, "readability wash is strong enough for UI", failures)
	_expect(screen.has_node("Background/StarDots/StarDotA"), "existing star dots remain", failures)
	_expect(screen.has_node("Background/StarOrbitBlue"), "existing blue star orbit remains", failures)
	_expect(screen.has_node("Background/StarOrbitGold"), "existing gold star orbit remains", failures)


func _check_board_shape_and_overlay(screen: Control, failures: Array[String]) -> void:
	_expect(screen.grid.columns == BoardModelScript.COLUMNS, "board grid still has 10 columns", failures)
	_expect(screen.grid.get_child_count() == BoardModelScript.COLUMNS * BoardModelScript.ROWS, "board grid still has 10x5 cells", failures)
	_expect(screen.board_overlay_preview != null, "transparent board preview node exists", failures)
	_expect(screen.board_overlay_preview.texture != null, "transparent board preview texture is assigned", failures)
	_expect(screen.board_overlay_preview.mouse_filter == Control.MOUSE_FILTER_IGNORE, "transparent board preview does not catch input", failures)


func _check_unit_text_stays_numeric(screen: Control, failures: Array[String]) -> void:
	screen._deploy_selected_to_cell(1, 1)
	await process_frame
	var cell_button: Button = screen.cell_buttons["1,1"]
	var cell_text := str(cell_button.text)
	_expect(cell_text.contains("HP "), "unit text keeps HP label", failures)
	_expect(cell_text.contains("/"), "unit text keeps numeric HP fraction", failures)
	_expect(not cell_text.contains("|") and not cell_text.contains("█") and not cell_text.contains("░"), "unit text does not use a text blood bar", failures)
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
