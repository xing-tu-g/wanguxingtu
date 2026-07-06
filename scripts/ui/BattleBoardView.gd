extends RefCounted
class_name BattleBoardView

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const StarPaletteScript: GDScript = preload("res://scripts/ui/theme/ColorPalette.gd")
const BattleUIThemeScript: GDScript = preload("res://scripts/ui/theme/BattleUITheme.gd")
const BattleUIAssetsScript: GDScript = preload("res://scripts/ui/theme/BattleUIAssets.gd")
const HeroBattleSpriteScript: GDScript = preload("res://scripts/ui/HeroBattleSprite.gd")
const GRID_ALPHA_MASK_SHADER: Shader = preload("res://assets/shaders/grid_alpha_mask.gdshader")

const MAT_SWAMP := preload("res://assets/shaders/materials/terrain_swamp.tres")
const MAT_RIVER := preload("res://assets/shaders/materials/terrain_river.tres")
const MAT_HIGHLAND := preload("res://assets/shaders/materials/terrain_high_land.tres")

var grid: Control
var cell_buttons: Dictionary = {}
var cell_sprites: Dictionary = {}
var cell_portraits: Dictionary = {}
var cell_backplates: Dictionary = {}
var cell_containers: Dictionary = {}
var callbacks: Dictionary = {}
var grid_alpha_mask_material: ShaderMaterial

const CELL_W: int = 150
const CELL_H: int = 117
const CELL_OFFSET_X: float = float(CELL_W) / 2.0


func setup(board_grid: Control, board_callbacks: Dictionary) -> void:
	grid = board_grid
	callbacks = board_callbacks
	if grid_alpha_mask_material == null:
		grid_alpha_mask_material = ShaderMaterial.new()
		grid_alpha_mask_material.shader = GRID_ALPHA_MASK_SHADER
		grid_alpha_mask_material.set_shader_parameter("inset", 0.105)
		grid_alpha_mask_material.set_shader_parameter("radius", 0.075)
		grid_alpha_mask_material.set_shader_parameter("feather", 0.030)
	if grid != null and not grid.resized.is_connected(_layout_cells):
		grid.resized.connect(_layout_cells)


func build() -> void:
	if grid == null:
		return
	cell_buttons.clear()
	cell_sprites.clear()
	cell_portraits.clear()
	cell_backplates.clear()
	cell_containers.clear()
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
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
			cell_button.flat = true

			var backplate := TextureRect.new()
			backplate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			backplate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			backplate.anchor_left = 0.0
			backplate.anchor_right = 1.0
			backplate.anchor_top = 0.0
			backplate.anchor_bottom = 1.0
			backplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			backplate.name = "GridBackplate"
			backplate.material = grid_alpha_mask_material
			cell_button.add_child(backplate)

			var battle_sprite: Control = HeroBattleSpriteScript.new() as Control
			battle_sprite.name = "HeroBattleSprite"
			battle_sprite.anchor_left = 0.0
			battle_sprite.anchor_right = 1.0
			battle_sprite.anchor_top = 0.0
			battle_sprite.anchor_bottom = 1.0
			battle_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell_button.add_child(battle_sprite)

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

			grid.add_child(container)
			container.add_child(cell_button)
			cell_buttons[_cell_key(column, row)] = cell_button
			cell_sprites[_cell_key(column, row)] = battle_sprite
			cell_portraits[_cell_key(column, row)] = battle_sprite.get_node_or_null("BattleSpriteTexture")
			cell_backplates[_cell_key(column, row)] = backplate
			cell_containers[_cell_key(column, row)] = container
	_layout_cells.call_deferred()


func _layout_cells() -> void:
	if grid == null:
		return
	var board_w: float = float(BoardModelScript.COLUMNS * CELL_W)
	var board_h: float = float(BoardModelScript.ROWS * CELL_H)
	var origin := Vector2(
		maxf(0.0, (grid.size.x - board_w) * 0.5),
		maxf(0.0, (grid.size.y - board_h) * 0.5)
	)
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		var start_x: float = CELL_OFFSET_X if row % 2 == 1 else 0.0
		for column in range(1, cols_this_row + 1):
			var container: Control = cell_containers.get(_cell_key(column, row)) as Control
			if container == null:
				continue
			container.position = origin + Vector2(start_x + (column - 1) * CELL_W, (row - 1) * CELL_H)


func refresh() -> void:
	for row in range(1, BoardModelScript.ROWS + 1):
		var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
		for column in range(1, cols_this_row + 1):
			var key := _cell_key(column, row)
			if not cell_buttons.has(key):
				continue
			var cell_button := cell_buttons[key] as Button
			var backplate := cell_backplates.get(key) as TextureRect
			var unit_data: Dictionary = _call("unit_at", [column, row])
			var terrain_result = _call("get_terrain", [column, row])
			var terrain: String = "grass"
			if terrain_result is String:
				terrain = terrain_result
			var cell_style: StyleBoxFlat = _make_zone_style(column, row, unit_data, terrain)
			var selected: bool = _call_bool("is_selected_cell", [column, row])
			var hover_ready: bool = _call_bool("is_recommended_deploy_cell", [column, row])
			var zone: String = _zone_for_cell(column, row)
			if backplate != null:
				backplate.texture = BattleUIAssetsScript.grid_texture(zone, terrain, selected, hover_ready)

			_update_battle_sprite(key, unit_data)

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
			cell_button.material = null


func _make_zone_style(column: int, row: int, unit_data: Dictionary, terrain: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5

	return style


func _zone_for_cell(column: int, row: int) -> String:
	var max_cols: int = BoardModelScript.get_cols_for_row(row) if row >= 1 and row <= BoardModelScript.ROWS else 10
	var deploy_width: int = BoardModelScript.get_deployment_width_for_row(row) if row >= 1 and row <= BoardModelScript.ROWS else 3
	var blue_end: int = deploy_width
	var red_start: int = max_cols - deploy_width + 1
	if column >= 1 and column <= blue_end:
		return BoardModelScript.ZONE_LEFT_DEPLOYMENT
	if column > blue_end and column < red_start:
		return BoardModelScript.ZONE_PUBLIC
	if column >= red_start and column <= max_cols:
		return BoardModelScript.ZONE_RIGHT_DEPLOYMENT
	return ""


func _update_battle_sprite(key: String, unit_data: Dictionary) -> void:
	var battle_sprite: Control = cell_sprites.get(key) as Control
	if battle_sprite == null:
		return
	if unit_data.is_empty():
		battle_sprite.clear()
		cell_portraits[key] = battle_sprite.get_node_or_null("BattleSpriteTexture")
		return

	var hero_id: String = str(unit_data.get("hero_id", ""))
	if hero_id.is_empty():
		battle_sprite.clear()
		cell_portraits[key] = battle_sprite.get_node_or_null("BattleSpriteTexture")
		return

	var hero_def: Dictionary = _call("hero_def_for_id", [hero_id])
	battle_sprite.setup_from_unit(unit_data, hero_def)
	cell_portraits[key] = battle_sprite.get_node_or_null("BattleSpriteTexture")


func play_unit_pose(unit_id: String, pose: String) -> void:
	var key := _unit_id_to_cell_key(unit_id)
	if key.is_empty():
		return
	var battle_sprite: Control = cell_sprites.get(key) as Control
	if battle_sprite == null:
		return
	match pose:
		"attack":
			battle_sprite.play_attack()
		"skill":
			battle_sprite.play_skill()
		_:
			battle_sprite.show_idle()


func _unit_id_to_cell_key(unit_id: String) -> String:
	if unit_id.is_empty():
		return ""
	for key in cell_sprites.keys():
		var parts := str(key).split(",")
		if parts.size() != 2:
			continue
		var unit_data: Dictionary = _call("unit_at", [parts[0].to_int(), parts[1].to_int()])
		if str(unit_data.get("instance_id", "")) == unit_id:
			return str(key)
	return ""


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


func _call_bool(callback_name: String, args: Array = []) -> bool:
	var result = _call(callback_name, args)
	if result is bool:
		return result
	return false
