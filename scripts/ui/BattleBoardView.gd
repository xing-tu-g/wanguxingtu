extends RefCounted
class_name BattleBoardView

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const StarPaletteScript: GDScript = preload("res://scripts/ui/theme/ColorPalette.gd")

const MAT_SWAMP := preload("res://assets/shaders/materials/terrain_swamp.tres")
const MAT_RIVER := preload("res://assets/shaders/materials/terrain_river.tres")
const MAT_HIGHLAND := preload("res://assets/shaders/materials/terrain_high_land.tres")

var grid: Control
var cell_buttons: Dictionary = {}
var cell_portraits: Dictionary = {}
var callbacks: Dictionary = {}

const CELL_W: int = 128
const CELL_H: int = 104
const CELL_OFFSET_X: float = float(CELL_W) / 2.0


func setup(board_grid: Control, board_callbacks: Dictionary) -> void:
	grid = board_grid
	callbacks = board_callbacks


func build() -> void:
	if grid == null:
		return
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		var start_x: float = CELL_OFFSET_X if row % 2 == 1 else 0.0
		for column in range(1, cols_this_row + 1):
			var container := MarginContainer.new()
			container.custom_minimum_size = Vector2(CELL_W, CELL_H)
			container.name = "Cell_%d_%d" % [column, row]

			var cell_button := Button.new()
			cell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell_button.text = ""
			cell_button.disabled = false
			cell_button.focus_mode = Control.FOCUS_NONE
			cell_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell_button.name = "Btn_%d_%d" % [column, row]

			var portrait := TextureRect.new()
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.anchor_left = 0.0
			portrait.anchor_right = 1.0
			portrait.anchor_top = 0.0
			portrait.anchor_bottom = 1.0
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			portrait.name = "Portrait"
			cell_button.add_child(portrait)

			var hp_label := Label.new()
			hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hp_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			hp_label.anchor_left = 0.0
			hp_label.anchor_right = 1.0
			hp_label.anchor_bottom = 1.0
			hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hp_label.add_theme_font_size_override("font_size", 11)
			hp_label.add_theme_color_override("font_color", Color.WHITE)
			hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
			hp_label.add_theme_constant_override("outline_size", 2)
			hp_label.name = "HpLabel"
			cell_button.add_child(hp_label)

			var deploy_callback: Callable = callbacks.get("deploy_to_cell", Callable())
			if deploy_callback.is_valid():
				cell_button.pressed.connect(deploy_callback.bind(column, row))

			container.position = Vector2(start_x + (column - 1) * CELL_W, (row - 1) * CELL_H)

			grid.add_child(container)
			container.add_child(cell_button)
			cell_buttons[_cell_key(column, row)] = cell_button
			cell_portraits[_cell_key(column, row)] = portrait


func refresh() -> void:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			var key := _cell_key(column, row)
			if not cell_buttons.has(key):
				continue
			var cell_button := cell_buttons[key] as Button
			var unit_data: Dictionary = _call("unit_at", [column, row])
			var cell_style: StyleBoxFlat = _make_zone_style(column, row, unit_data)

			_update_portrait(key, unit_data)

			var label_text: String = _format_simple_text(unit_data)
			cell_button.text = label_text

			var hp_label := cell_button.get_node_or_null("HpLabel") as Label
			if hp_label:
				hp_label.text = _hp_text(unit_data)

			cell_button.add_theme_stylebox_override("normal", cell_style)
			cell_button.add_theme_stylebox_override("hover", cell_style)
			cell_button.add_theme_stylebox_override("pressed", cell_style)
			cell_button.add_theme_stylebox_override("disabled", cell_style)

			# Terrain material — swapped in each refresh
			var terrain_result = _call("get_terrain", [column, row])
			var terrain: String = "grass"
			if terrain_result is String:
				terrain = terrain_result
			var mat: ShaderMaterial = null
			if terrain == "swamp":
				mat = MAT_SWAMP
			elif terrain == "river":
				mat = MAT_RIVER
			elif terrain == "high_land":
				mat = MAT_HIGHLAND
			cell_button.material = mat


func _make_zone_style(column: int, row: int, unit_data: Dictionary) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = StarPaletteScript.CELL_BORDER
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	if not unit_data.is_empty():
		style.bg_color = StarPaletteScript.CELL_OCCUPIED_BG
	else:
		var zone: String = BoardModelScript.get_zone_for_column(column, row)
		match zone:
			BoardModelScript.ZONE_LEFT_DEPLOYMENT:
				style.bg_color = StarPaletteScript.DEPLOY_ZONE_PLAYER_OVERLAY
			BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
				style.bg_color = StarPaletteScript.DEPLOY_ZONE_ENEMY_OVERLAY
			_:
				style.bg_color = StarPaletteScript.PUBLIC_ZONE_OVERLAY
	return style


func _update_portrait(key: String, unit_data: Dictionary) -> void:
	var portrait: TextureRect = cell_portraits.get(key) as TextureRect
	if portrait == null:
		return
	if unit_data.is_empty():
		portrait.texture = null
		return

	var hero_id: String = str(unit_data.get("hero_id", ""))
	if hero_id.is_empty():
		portrait.texture = null
		return

	var hero_def: Dictionary = _call("hero_def_for_id", [hero_id])
	var path: String = str(hero_def.get("portrait", ""))
	if path.is_empty():
		portrait.texture = null
		return

	var tex: Texture2D = load(path) as Texture2D
	portrait.texture = tex


func _format_simple_text(unit_data: Dictionary) -> String:
	if unit_data.is_empty():
		return ""
	var name_str: String = str(unit_data.get("hero_id", ""))
	return name_str


func _hp_text(unit_data: Dictionary) -> String:
	if unit_data.is_empty():
		return ""
	var hp: int = int(unit_data.get("hp", 0))
	var max_hp: int = max(1, int(unit_data.get("max_hp", 1)))
	return "%d/%d" % [hp, max_hp]


func _cell_key(column: int, row: int) -> String:
	return "%d,%d" % [column, row]


func _call_string(callback_name: String, args: Array = []) -> String:
	return str(_call(callback_name, args))


func _call(callback_name: String, args: Array = []) -> Variant:
	var callback: Callable = callbacks.get(callback_name, Callable())
	if callback.is_valid():
		return callback.callv(args)
	return {}
