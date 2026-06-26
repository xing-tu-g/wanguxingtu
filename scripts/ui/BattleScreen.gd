extends Control

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const TerrainSystemScript: GDScript = preload("res://scripts/battle/TerrainSystem.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const BattleDeckScript: GDScript = preload("res://scripts/battle/BattleDeck.gd")
const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")
const BattleBoardViewScript: GDScript = preload("res://scripts/ui/BattleBoardView.gd")
const BattleTutorialViewScript: GDScript = preload("res://scripts/ui/BattleTutorialView.gd")
const BattleAnimatorScript: GDScript = preload("res://scripts/ui/BattleAnimator.gd")
const StarPaletteScript: GDScript = preload("res://scripts/ui/theme/ColorPalette.gd")
const FontScaleScript: GDScript = preload("res://scripts/ui/theme/FontScale.gd")

# ── ShaderMaterial preloads (T3-3) — 消除代码中 ShaderMaterial.new()
const MAT_GLOW_PLAYER: ShaderMaterial = preload("res://assets/shaders/materials/glow_pulse_player.tres")
const MAT_GLOW_ENEMY: ShaderMaterial = preload("res://assets/shaders/materials/glow_pulse_enemy.tres")
const MAT_DEPTH_FADE_BATTLE: ShaderMaterial = preload("res://assets/shaders/materials/depth_fade_battle.tres")

# ── Theme preload (T3-2)
const THEME_DEFAULT: Theme = preload("res://assets/theme/default_theme.tres")

const HOME_SCREEN := "res://scenes/ui/HomeScreen.tscn"
const RESULT_SCREEN := "res://scenes/ui/ResultScreen.tscn"
const DEBUG_HERO_IDS := ["guanyu", "zhouyu", "zhangjiao", "zhaoyun", "zhangfei", "sunshangxiang"]
const ENEMY_AUTO_HERO_IDS := ["zhouyu", "guanyu", "zhaoyun", "zhangfei", "sunshangxiang", "zhangjiao"]
const STARTING_PLAYER_DECK := DEBUG_HERO_IDS
const STARTING_ENEMY_DECK := ENEMY_AUTO_HERO_IDS
const STARTING_HAND_SIZE := 3
const DRAW_PER_SIDE_TURN := 1
const RECYCLE_DISCARD_ON_EMPTY := true
const MAX_LOG_LINES := 20
const MAX_LOG_RESULT_CHARS := 44
const DEPLOY_FAILURE_TOAST_DURATION := 2.8
const DEPLOY_FAILURE_TOAST_FADE_DURATION := 0.8
const REASON_TEXT := {
	"cell_out_of_bounds": "格子超出棋盘",
	"not_deployment_zone": "只能部署在己方蓝色区域",
	"not_own_deployment_zone": "只能部署在己方前三列",
	"cell_occupied": "目标格已有单位",
	"unknown_hero": "未知武将",
	"not_enough_star_power": "星力不足",
	"no_affordable_enemy_deploy_cell": "敌方无可部署单位或格子",
}
const STATUS_TEXT := {
	"burn": "燃烧",
}

var battle_state: BattleState = BattleStateScript.new()
var turn_controller: TurnController = TurnControllerScript.new(battle_state, BoardModelScript.SIDE_LEFT)
var battle_deck: BattleDeck = BattleDeckScript.new()
var battle_log_view: BattleLogView
var card_zone_view: CardZoneView
var battle_board_view: BattleBoardView = BattleBoardViewScript.new()
var battle_tutorial_view: BattleTutorialView = BattleTutorialViewScript.new()
var battle_animator: BattleAnimator
var cell_buttons: Dictionary = {}
var selected_hero_id: String = "guanyu"
var player_deck: Array = []
var enemy_deck: Array = []
var configured_player_deck: Array = []
var configured_enemy_deck: Array = []
var player_hand: Array = []
var enemy_hand: Array = []
var player_discard: Array = []
var enemy_discard: Array = []
var battle_log_entries: Array[String] = []
var battle_log_collapsed: bool = true
var card_zone_collapsed: bool = true
var selected_card_hero_id: String = ""
var last_touched_cell: Vector2i = Vector2i.ZERO
var last_action_cells: Array[Vector2i] = []
var selected_detail_unit_id: String = ""
var first_deploy_hint_dismissed: bool = false
var deploy_failure_highlight_active: bool = false
var tutorial_turn_advanced: bool = false
var deploy_failure_toast_time_left: float = 0.0
var _battle_started_emitted: bool = false

@onready var grid: Control = $DuelArea/CenterBoardStack/BattleArea/BoardPanel/BoardGrid
@onready var battle_background_image: TextureRect = $Background/BattleBackgroundImage
@onready var background_readability_wash: ColorRect = $Background/BackgroundReadabilityWash
@onready var board_overlay_preview: TextureRect = $DuelArea/CenterBoardStack/BattleArea/BoardPanel/BoardOverlayPreview
@onready var status_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TopRow/TurnLabel
@onready var tutorial_progress_row: HBoxContainer = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow
@onready var tutorial_progress_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/TutorialTitle
@onready var tutorial_step_select_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/Step1Panel/Step1Inner/Step1Label
@onready var tutorial_step_deploy_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/Step2Panel/Step2Inner/Step2Label
@onready var tutorial_step_turn_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/Step3Panel/Step3Inner/Step3Label
@onready var turn_info_panel: PanelContainer = $TopBar/StatusPanel
# turn_info_label 已移除 — star_label 在第 698 行已显示回合信息，status_label(TurnLabel) 负责战斗中状态提示
@onready var star_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TopRow/StarLabel
@onready var player_hud_label: Label = $DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerHpContainer/PlayerHpLabel
@onready var enemy_hud_label: Label = $DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyHpContainer/EnemyHpLabel
@onready var player_master_panel: PanelContainer = $DuelArea/PlayerMasterPanel
@onready var enemy_master_panel: PanelContainer = $DuelArea/EnemyMasterPanel
@onready var card_zone_label: Label = $BottomHand/CardZonePanel/CardZoneLabel
@onready var card_zone_toggle_button: Button = $BottomHand/CardZonePanel/CardZoneLayout/CardZoneHeader/CardZoneToggleButton
@onready var card_zone_summary_label: Label = $BottomHand/CardZonePanel/CardZoneLayout/CardZoneHeader/CardZoneSummaryLabel
@onready var overlay_dismiss_button: Button = $OverlayDismissButton
@onready var card_zone_drawer_panel: PanelContainer = $CardZoneDrawerPanel
@onready var card_zone_close_button: Button = $CardZoneDrawerPanel/DrawerMargin/DrawerLayout/DrawerHeader/CardZoneCloseButton
@onready var card_zone_detail_label: RichTextLabel = $CardZoneDrawerPanel/DrawerMargin/DrawerLayout/CardZoneDetailLabel
@onready var card_zone_scroll: ScrollContainer = $CardZoneDrawerPanel/DrawerMargin/DrawerLayout/CardZoneScroll
@onready var card_zone_cards: VBoxContainer = $CardZoneDrawerPanel/DrawerMargin/DrawerLayout/CardZoneScroll/CardZoneCards
@onready var card_inspect_label: RichTextLabel = $CardZoneDrawerPanel/DrawerMargin/DrawerLayout/CardInspectLabel
@onready var log_panel: PanelContainer = $LogPanel
@onready var battle_log_text: TextEdit = $LogPanel/LogMargin/LogLayout/LogText
@onready var log_close_button: Button = $LogPanel/LogMargin/LogLayout/LogHeader/LogCloseButton
@onready var toggle_log_button: Button = $TopBar/LogButton
@onready var deploy_failure_toast_panel: PanelContainer = $DeployFailureToastPanel
@onready var deploy_failure_toast_label: Label = $DeployFailureToastPanel/ToastMargin/DeployFailureToastLabel
@onready var unit_detail_panel: PanelContainer = $UnitDetailPanel
@onready var unit_detail_title: Label = $UnitDetailPanel/DetailMargin/DetailLayout/DetailHeader/DetailTitle
@onready var unit_detail_body: RichTextLabel = $UnitDetailPanel/DetailMargin/DetailLayout/DetailScroll/DetailBody
@onready var first_deploy_hint_panel: PanelContainer = $FirstDeployHintPanel
@onready var first_deploy_hint_button: Button = $FirstDeployHintPanel/HintMargin/HintLayout/HintFooter/FirstDeployHintButton
@onready var hero_button_row: HBoxContainer = $BottomHand/Controls/HeroScroll/HeroButtons
@onready var advance_turn_button: Button = $BottomHand/Controls/AdvanceButton
@onready var _app_state: Node = get_node("/root/AppState")
var hero_buttons: Dictionary = {}

# ── StyleBoxFlat 缓存池 — 消除 per-frame GC ──
var _advance_style: StyleBoxFlat
var _hero_button_styles: Dictionary = {}  # hero_id → StyleBoxFlat
var _panel_styles: Dictionary = {}  # node_name → StyleBoxFlat
var _master_panel_player_active: StyleBoxFlat
var _master_panel_player_inactive: StyleBoxFlat
var _master_panel_enemy_active: StyleBoxFlat
var _master_panel_enemy_inactive: StyleBoxFlat
var _overlay_button_style: StyleBoxFlat
# ── Shader 材质 — 预加载 .tres 引用，运行时直接指派 ──
var _shader_glow_active: ShaderMaterial = MAT_GLOW_PLAYER
var _shader_glow_active_enemy: ShaderMaterial = MAT_GLOW_ENEMY


func _ready() -> void:
	theme = THEME_DEFAULT
	$TopBar/BackButton.pressed.connect(_return_home)
	overlay_dismiss_button.pressed.connect(_close_all_drawers)
	$UnitDetailPanel/DetailMargin/DetailLayout/DetailHeader/DetailCloseButton.pressed.connect(_hide_unit_detail)
	$BottomHand/Controls/ResetButton.pressed.connect(_reset_debug_battle)
	$BottomHand/Controls/AdvanceButton.pressed.connect(_advance_turn)
	_build_style_caches()
	_create_view_nodes()
	_initialize_card_piles()
	_build_hero_buttons()
	_initialize_battle_log_view()
	_initialize_card_zone_view()
	_initialize_battle_board_view()
	_initialize_battle_tutorial_view()
	_apply_visual_placeholder_theme()
	_apply_font_scale()
	_apply_depth_fade()

	battle_state.terrain_system.generate_deterministic(1)
	_build_board()
	_refresh_board()
	_initialize_battle_animator()
	_update_status("选择武将后，点击左侧部署区格子。下一步：点击「我方行动」推进回合。")
	_update_log_visibility()
	_update_first_deploy_hint()
	_emit_battle_started()


func set_screen_data(screen_data: Dictionary) -> void:
	configured_player_deck = _validated_deck_from_data(screen_data.get("player_deck", []), STARTING_PLAYER_DECK)
	configured_enemy_deck = _validated_deck_from_data(screen_data.get("enemy_deck", []), STARTING_ENEMY_DECK)


# ── StyleBoxFlat 缓存池初始化 ──
func _build_style_caches() -> void:
	# Advance button style
	_advance_style = StyleBoxFlat.new()
	_advance_style.set_corner_radius_all(14)
	_advance_style.set_border_width_all(5)
	_advance_style.content_margin_left = 14
	_advance_style.content_margin_top = 8
	_advance_style.content_margin_right = 14
	_advance_style.content_margin_bottom = 8

	# Master panel styles — 4 variants
	_master_panel_player_active = _make_cached_panel_style(StarPaletteScript.ACTIVE_PLAYER_BG.lightened(0.10), StarPaletteScript.ACTIVE_PLAYER_BORDER, 6)
	_master_panel_player_inactive = _make_cached_panel_style(StarPaletteScript.INACTIVE_PLAYER_BG, StarPaletteScript.INACTIVE_PLAYER_BORDER, 3)
	_master_panel_enemy_active = _make_cached_panel_style(StarPaletteScript.ACTIVE_ENEMY_BG.lightened(0.10), StarPaletteScript.ACTIVE_ENEMY_BORDER, 6)
	_master_panel_enemy_inactive = _make_cached_panel_style(StarPaletteScript.INACTIVE_ENEMY_BG, StarPaletteScript.INACTIVE_ENEMY_BORDER, 3)

	# Overlay dismiss button
	_overlay_button_style = StyleBoxFlat.new()
	_overlay_button_style.bg_color = StarPaletteScript.PANEL_OVERLAY_DIM
	_overlay_button_style.border_color = Color.TRANSPARENT


func _make_cached_panel_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


# ── View 节点创建 (T3-1) — CardZoneView / BattleLogView 现在 extend Node ──
func _create_view_nodes() -> void:
	battle_log_view = BattleLogView.new()
	battle_log_view.name = "BattleLogView"
	add_child(battle_log_view)

	card_zone_view = CardZoneView.new()
	card_zone_view.name = "CardZoneView"
	add_child(card_zone_view)


func _apply_depth_fade() -> void:
	if battle_background_image == null:
		return
	battle_background_image.material = MAT_DEPTH_FADE_BATTLE


## Apply viewport-responsive font sizes to key labels.
func _apply_font_scale() -> void:
	var vw := get_viewport_rect().size.x
	$TopBar/Title.add_theme_font_size_override(&"font_size", FontScaleScript.title_size(vw) - 4)
	$TopBar/StatusPanel/StatusMargin/StatusRow/TopRow/TurnLabel.add_theme_font_size_override(&"font_size", FontScaleScript.body_size(vw) + 1)
	$TopBar/StatusPanel/StatusMargin/StatusRow/TopRow/StarLabel.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw))


func _emit_battle_started() -> void:
	if _battle_started_emitted:
		return
	_battle_started_emitted = true
	var config := {
		"player_deck": _player_battle_hero_ids(),
		"enemy_deck": _enemy_battle_hero_ids(),
		"master_level": 1,
		"terrain_seed": 1,
	}
	var bus_battle_start := get_node("/root/EventBus")
	if bus_battle_start: bus_battle_start.battle_started.emit(config)


func _initialize_battle_log_view() -> void:
	battle_log_view.max_lines = MAX_LOG_LINES
	battle_log_view.max_result_chars = MAX_LOG_RESULT_CHARS
	battle_log_view.setup(log_panel, battle_log_text, toggle_log_button, log_close_button)
	battle_log_view.visibility_changed.connect(_on_battle_log_visibility_changed)
	battle_log_entries = battle_log_view.entries


func _on_battle_log_visibility_changed(_collapsed: bool) -> void:
	battle_log_collapsed = battle_log_view.collapsed
	_update_overlay_dismiss_visibility()


func _initialize_card_zone_view() -> void:
	card_zone_view.setup(
		card_zone_label,
		card_zone_toggle_button,
		card_zone_summary_label,
		card_zone_drawer_panel,
		card_zone_close_button,
		card_zone_detail_label,
		card_zone_scroll,
		card_zone_cards,
		card_inspect_label,
		{
			"format_zone_for_side": _format_card_zone_for_side,
			"format_detail": _format_card_zone_detail,
			"format_button_text": _format_card_button_text,
			"format_tooltip": _format_card_tooltip,
			"format_inspect": _format_card_inspect_text,
			"apply_button_style": _apply_card_button_style,
		}
	)
	card_zone_view.changed.connect(_on_card_zone_view_changed)
	card_zone_view.card_selected.connect(_on_card_zone_card_selected)
	card_zone_collapsed = card_zone_view.collapsed
	selected_card_hero_id = card_zone_view.selected_card_hero_id


func _on_card_zone_view_changed() -> void:
	card_zone_collapsed = card_zone_view.collapsed
	selected_card_hero_id = card_zone_view.selected_card_hero_id
	_update_overlay_dismiss_visibility()


func _on_card_zone_card_selected(hero_id: String) -> void:
	selected_card_hero_id = hero_id


func _initialize_battle_board_view() -> void:
	battle_board_view.setup(
		grid,
		{
			"deploy_to_cell": _deploy_selected_to_cell,
			"unit_at": _board_unit_at,
			"hero_def_for_id": _hero_def_for_board,
			"get_terrain": _board_get_terrain,
		}
	)
	cell_buttons = battle_board_view.cell_buttons


func _board_unit_at(column: int, row: int) -> Dictionary:
	return battle_state.board.get_unit_at(column, row)


func _hero_def_for_board(hero_id: String) -> Dictionary:
	return battle_state.get_hero_def(hero_id)


func _board_get_terrain(column: int, row: int) -> String:
	return battle_state.terrain_system.get_terrain(column, row)


func _initialize_battle_tutorial_view() -> void:
	battle_tutorial_view.deploy_failure_toast_duration = DEPLOY_FAILURE_TOAST_DURATION
	battle_tutorial_view.deploy_failure_toast_fade_duration = DEPLOY_FAILURE_TOAST_FADE_DURATION
	battle_tutorial_view.setup(
		tutorial_progress_label,
		tutorial_step_select_label,
		tutorial_step_deploy_label,
		tutorial_step_turn_label,
		first_deploy_hint_panel,
		null,
		first_deploy_hint_button,
		deploy_failure_toast_panel,
		deploy_failure_toast_label,
		{
			"has_no_player_units": _tutorial_has_no_player_units,
			"has_player_unit": _tutorial_has_player_unit,
			"has_selected_card": _tutorial_has_selected_card,
			"selected_hero_name": _tutorial_selected_hero_name,
			"changed": _on_battle_tutorial_view_changed,
		}
	)
	first_deploy_hint_dismissed = battle_tutorial_view.first_deploy_hint_dismissed
	tutorial_turn_advanced = battle_tutorial_view.tutorial_turn_advanced
	deploy_failure_toast_time_left = battle_tutorial_view.deploy_failure_toast_time_left


func _initialize_battle_animator() -> void:
	battle_animator = BattleAnimatorScript.new()
	battle_animator.name = "BattleAnimator"
	add_child(battle_animator)
	battle_animator.setup(
		cell_buttons,
		_anim_cell_key_to_unit_id,
		_anim_unit_id_to_cell_key,
	)


func _anim_cell_key_to_unit_id(cell_key: String) -> String:
	var parts := cell_key.split(",")
	if parts.size() != 2:
		return ""
	var column := parts[0].to_int()
	var row := parts[1].to_int()
	var unit: Dictionary = battle_state.board.get_unit_at(column, row)
	return str(unit.get("instance_id", ""))


func _anim_unit_id_to_cell_key(unit_id: String) -> String:
	if not battle_state.placed_units.has(unit_id):
		return ""
	var unit: Dictionary = battle_state.placed_units[unit_id]
	return "%d,%d" % [int(unit.get("column", 0)), int(unit.get("row", 0))]


func _on_battle_tutorial_view_changed() -> void:
	first_deploy_hint_dismissed = battle_tutorial_view.first_deploy_hint_dismissed
	tutorial_turn_advanced = battle_tutorial_view.tutorial_turn_advanced
	deploy_failure_toast_time_left = battle_tutorial_view.deploy_failure_toast_time_left


func _tutorial_has_no_player_units() -> bool:
	return battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).is_empty()


func _tutorial_has_player_unit() -> bool:
	return not battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).is_empty()


func _tutorial_has_selected_card() -> bool:
	return not selected_hero_id.is_empty() and player_hand.has(selected_hero_id)


func _tutorial_selected_hero_name() -> String:
	if selected_hero_id.is_empty():
		return "手牌"
	return _hero_name(selected_hero_id)


func _process(delta: float) -> void:
	battle_tutorial_view.process(delta)
	deploy_failure_toast_time_left = battle_tutorial_view.deploy_failure_toast_time_left


func _build_hero_buttons() -> void:
	for child in hero_button_row.get_children():
		child.queue_free()
	hero_buttons.clear()
	_hero_button_styles.clear()
	for hero_id in _player_battle_hero_ids():
		var hero_button := Button.new()
		hero_button.custom_minimum_size = Vector2(236, 82)
		hero_button.focus_mode = Control.FOCUS_NONE
		hero_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		hero_button_row.add_child(hero_button)
		hero_buttons[hero_id] = hero_button
		# 预创建该英雄的 StyleBoxFlat，运行时只改属性
		var style := StyleBoxFlat.new()
		style.set_border_width_all(3)
		style.set_corner_radius_all(10)
		style.content_margin_left = 12
		style.content_margin_top = 6
		style.content_margin_right = 12
		style.content_margin_bottom = 6
		_hero_button_styles[hero_id] = style
		hero_button.pressed.connect(_select_hero.bind(hero_id))


func _build_board() -> void:
	battle_board_view.build()
	cell_buttons = battle_board_view.cell_buttons


func _apply_visual_placeholder_theme() -> void:
	_apply_panel_style_from_cache($TopBar, StarPaletteScript.PANEL_TOP_BAR, StarPaletteScript.PANEL_TOP_BAR_BORDER, 3)
	_apply_panel_style_from_cache(turn_info_panel, StarPaletteScript.PANEL_STATUS, StarPaletteScript.PANEL_STATUS_BORDER, 2)
	_apply_master_panel_style(BoardModelScript.SIDE_LEFT)
	_apply_master_panel_style(BoardModelScript.SIDE_RIGHT)
	_apply_panel_style_from_cache($DuelArea/CenterBoardStack/BattleArea/BoardPanel, StarPaletteScript.PANEL_BOARD, StarPaletteScript.PANEL_BOARD_BORDER, 4)
	_apply_panel_style_from_cache($BottomHand/CardZonePanel, StarPaletteScript.PANEL_CARD_ZONE, StarPaletteScript.PANEL_CARD_ZONE_BORDER, 2)
	_apply_button_overlay_style()
	_apply_panel_style_from_cache($CardZoneDrawerPanel, StarPaletteScript.PANEL_DRAWER, StarPaletteScript.PANEL_DRAWER_BORDER, 3)
	_apply_panel_style_from_cache($LogPanel, StarPaletteScript.PANEL_LOG, StarPaletteScript.PANEL_LOG_BORDER, 3)
	_apply_panel_style_from_cache($DeployFailureToastPanel, StarPaletteScript.PANEL_TOAST, StarPaletteScript.PANEL_TOAST_BORDER, 4)
	_apply_panel_style_from_cache($UnitDetailPanel, StarPaletteScript.PANEL_DETAIL, StarPaletteScript.PANEL_DETAIL_BORDER, 3)
	_apply_panel_style_from_cache($FirstDeployHintPanel, StarPaletteScript.PANEL_HINT, StarPaletteScript.PANEL_HINT_BORDER, 4)
	_apply_tutorial_progress_row_style()


func _apply_panel_style_from_cache(panel: Control, bg_color: Color, border_color: Color, border_width: int) -> void:
	var node_key := str(panel.get_path())
	if not _panel_styles.has(node_key):
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.content_margin_left = 14
		style.content_margin_top = 10
		style.content_margin_right = 14
		style.content_margin_bottom = 10
		_panel_styles[node_key] = style
	var style: StyleBoxFlat = _panel_styles[node_key]
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	panel.add_theme_stylebox_override("panel", style)


func _apply_master_panel_style(side: String) -> void:
	var active: bool = turn_controller.current_side == side
	var panel: PanelContainer = player_master_panel if side == BoardModelScript.SIDE_LEFT else enemy_master_panel
	if side == BoardModelScript.SIDE_LEFT:
		panel.add_theme_stylebox_override("panel", _master_panel_player_active if active else _master_panel_player_inactive)
	else:
		panel.add_theme_stylebox_override("panel", _master_panel_enemy_active if active else _master_panel_enemy_inactive)


func _refresh_master_panel_styles() -> void:
	_apply_master_panel_style(BoardModelScript.SIDE_LEFT)
	_apply_master_panel_style(BoardModelScript.SIDE_RIGHT)
	# 呼吸发光 Shader — 活跃方挂载
	if turn_controller.current_side == BoardModelScript.SIDE_LEFT:
		player_master_panel.material = _shader_glow_active
		enemy_master_panel.material = null
	else:
		player_master_panel.material = null
		enemy_master_panel.material = _shader_glow_active_enemy


func _active_side_feedback_color(side: String) -> Color:
	return StarPaletteScript.active_border(side)


func _side_feedback_bg_color(side: String) -> Color:
	return StarPaletteScript.active_bg(side)


func _side_feedback_border_color(side: String) -> Color:
	return StarPaletteScript.inactive_border(side)


func _current_side_feedback_label() -> String:
	return "%s行动 - %s" % [_side_label(turn_controller.current_side), _side_direction_text(turn_controller.current_side)]


func _apply_button_overlay_style() -> void:
	overlay_dismiss_button.add_theme_stylebox_override("normal", _overlay_button_style)
	overlay_dismiss_button.add_theme_stylebox_override("hover", _overlay_button_style)
	overlay_dismiss_button.add_theme_stylebox_override("pressed", _overlay_button_style)


func _select_hero(hero_id: String) -> void:
	if not player_hand.has(hero_id):
		_update_status("%s 已不在手牌中。" % _hero_name(hero_id))
		return
	selected_hero_id = hero_id
	selected_card_hero_id = hero_id
	_update_hero_buttons()
	_update_first_deploy_hint()
	_show_card_detail(hero_id)
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	_update_status("已选择%s，请点击左侧部署区格子。" % str(hero_def.get("name", hero_id)))


func _deploy_selected_to_cell(column: int, row: int) -> void:
	last_touched_cell = Vector2i(column, row)
	var unit_data: Dictionary = battle_state.board.get_unit_at(column, row)
	if not unit_data.is_empty():
		_show_unit_detail(unit_data)
		_refresh_board()
		_update_status("正在查看%s，点击空格继续部署。" % _unit_display_name(unit_data))
		return
	_hide_unit_detail()
	var hero_id := selected_hero_id
	_apply_deployment_result(battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_LEFT, column, row), hero_id, column, row)


func _apply_deployment_result(result: Dictionary, hero_id: String = "", column: int = 0, row: int = 0) -> void:
	if result.ok:
		first_deploy_hint_dismissed = true
		deploy_failure_highlight_active = false
		_hide_deploy_failure_toast()
		_consume_hero_from_hand(BoardModelScript.SIDE_LEFT, hero_id)
		_select_next_available_hero()
		var unit_data: Dictionary = result.unit
		var placed_column := int(unit_data.column)
		var placed_row := int(unit_data.row)
		var skill_summary := _format_skill_results(result.get("skill_results", []))
		_add_battle_log(_unit_display_name(unit_data), "部署", "消耗 %d 星力，进入 (%d,%d)" % [
			int(result.cost),
			placed_column,
			placed_row,
		])
		_log_skill_results(_unit_display_name(unit_data), result.get("skill_results", []))
		_refresh_board()
		_update_status("%s 已部署到 (%d,%d)，消耗 %d 星力。%s" % [
			unit_data.name,
			placed_column,
			placed_row,
			int(result.cost),
			skill_summary,
		])
		return

	var hero_name := hero_id
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	if not hero_def.is_empty():
		hero_name = str(hero_def.get("name", hero_id))
	deploy_failure_highlight_active = _should_activate_deploy_failure_highlight(str(result.reason))
	_add_battle_log(hero_name, "部署失败", "%s（%d,%d）" % [_deployment_failure_message(str(result.reason), hero_id, column, row), column, row])
	_refresh_board()
	_update_status("部署失败：%s" % _deployment_failure_message(str(result.reason), hero_id, column, row))
	_show_deploy_failure_toast(str(result.reason))


func _advance_turn() -> Dictionary:
	deploy_failure_highlight_active = false
	_hide_deploy_failure_toast()
	tutorial_turn_advanced = true
	var acting_side: String = turn_controller.current_side
	var auto_deploy_result := {}
	var start_result: Dictionary = turn_controller.start_side_turn()
	var drawn_cards: Array = _draw_cards(acting_side, DRAW_PER_SIDE_TURN)
	_add_battle_log(_side_label(acting_side), "回合开始", "星力 +%d，%d → %d" % [
		int(start_result.star_restore),
		int(start_result.star_power_before),
		int(start_result.star_power_after),
	])
	_log_drawn_cards(acting_side, drawn_cards)
	_log_skill_results(_side_label(acting_side), start_result.get("skill_results", []))
	if acting_side == BoardModelScript.SIDE_RIGHT:
		auto_deploy_result = _auto_deploy_enemy()
		_log_auto_deploy(auto_deploy_result)
	var acting_units: Array = MovementSystemScript.get_units_in_action_order(battle_state, acting_side)
	acting_units = acting_units.filter(func(unit_data: Dictionary) -> bool:
		return int(unit_data.get("hp", 0)) > 0
	)
	var action_results: Array = turn_controller.act_current_side()
	_capture_action_cells(action_results)
	_log_action_results(acting_units, action_results)
	var end_result: Dictionary = turn_controller.end_side_turn()
	_log_status_results(end_result.get("status_results", []))
	_refresh_board()
	_update_status(_format_turn_summary(acting_side, start_result, auto_deploy_result, action_results, end_result))
	var battle_result: Dictionary = _check_battle_end()
	if not battle_result.is_empty():
		_add_battle_log("战斗", "结算", _outcome_text(str(battle_result.get("outcome", ""))))
		var bus_battle_end := get_node("/root/EventBus")
		if bus_battle_end: bus_battle_end.battle_ended.emit(str(battle_result.get("outcome", "")), battle_result.get("stats", {}))
		_save_current_state()
		_route_to_result(battle_result)
	return {
		"side": acting_side,
		"start": start_result,
		"drawn_cards": drawn_cards,
		"auto_deploy": auto_deploy_result,
		"actions": action_results,
		"end": end_result,
		"battle_result": battle_result,
	}


func _auto_deploy_enemy() -> Dictionary:
	for hero_id in enemy_hand.duplicate():
		if not battle_state.can_afford(BoardModelScript.SIDE_RIGHT, hero_id):
			continue
		for row in range(1, BoardModelScript.ROWS + 1):
			var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
			for column in range(1, cols_this_row + 1):
				if not battle_state.board.can_deploy(BoardModelScript.SIDE_RIGHT, column, row):
					continue
				var deploy_result: Dictionary = battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_RIGHT, column, row)
				if deploy_result.ok:
					_consume_hero_from_hand(BoardModelScript.SIDE_RIGHT, hero_id)
					return deploy_result
	return {"ok": false, "reason": "no_affordable_enemy_deploy_cell"}


func _format_turn_summary(
	acting_side: String,
	start_result: Dictionary,
	auto_deploy_result: Dictionary,
	action_results: Array,
	end_result: Dictionary
) -> String:
	var parts: Array[String] = [
		"第 %d 回合，%s行动。" % [int(start_result.turn_number), _side_label(acting_side)],
		"星力 +%d，当前 %d。" % [int(start_result.star_restore), int(start_result.star_power_after)],
	]
	if not auto_deploy_result.is_empty() and bool(auto_deploy_result.get("ok", false)):
		var unit_data: Dictionary = auto_deploy_result.unit
		parts.append("敌方自动部署%s到 (%d,%d)。" % [
			str(unit_data.get("name", unit_data.get("hero_id", ""))),
			int(unit_data.get("column", 0)),
			int(unit_data.get("row", 0)),
		])
	parts.append("共 %d 个单位行动。" % action_results.size())
	parts.append("下一步：点击%s行动，执行第 %d 回合%s。" % [
		_side_label(str(end_result.next_side)),
		int(end_result.turn_number),
		_side_label(str(end_result.next_side)),
	])
	return " ".join(parts)

func _initialize_card_piles() -> void:
	battle_deck.setup(_player_battle_hero_ids(), _enemy_battle_hero_ids(), STARTING_HAND_SIZE, RECYCLE_DISCARD_ON_EMPTY)
	_sync_card_pile_references()
	_select_next_available_hero()


func _sync_card_pile_references() -> void:
	player_deck = battle_deck.deck_for_side(BoardModelScript.SIDE_LEFT)
	enemy_deck = battle_deck.deck_for_side(BoardModelScript.SIDE_RIGHT)
	player_hand = battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT)
	enemy_hand = battle_deck.hand_for_side(BoardModelScript.SIDE_RIGHT)
	player_discard = battle_deck.discard_for_side(BoardModelScript.SIDE_LEFT)
	enemy_discard = battle_deck.discard_for_side(BoardModelScript.SIDE_RIGHT)


func _draw_cards(side: String, count: int) -> Array:
	var recycled: bool = battle_deck.can_recycle_discard(side)
	var drawn_cards: Array = battle_deck.draw(side, count)
	_sync_card_pile_references()
	if side == BoardModelScript.SIDE_LEFT:
		_select_next_available_hero()
	if recycled and not drawn_cards.is_empty():
		_add_battle_log(_side_label(side), "洗牌", "弃牌回收到牌库后抽牌")
	return drawn_cards


func _log_drawn_cards(side: String, drawn_cards: Array) -> void:
	if drawn_cards.is_empty():
		_add_battle_log(_side_label(side), "抽牌", "牌库与弃牌均为空")
		return
	var names: Array[String] = []
	for hero_id_value in drawn_cards:
		names.append(_hero_name(str(hero_id_value)))
	_add_battle_log(_side_label(side), "抽牌", "抽到 %s" % "、".join(names))


func _update_status(message: String) -> void:
	status_label.text = message
	player_hud_label.text = _format_side_hud(BoardModelScript.SIDE_LEFT)
	enemy_hud_label.text = _format_side_hud(BoardModelScript.SIDE_RIGHT)
	star_label.text = "第 %d 回合｜%s行动" % [
		turn_controller.turn_number,
		_side_label(turn_controller.current_side),
	]
	_update_advance_turn_button()
	_update_tutorial_progress()
	_update_card_zone_summary()
	_update_hero_buttons()
	_refresh_master_panel_styles()
	_update_first_deploy_hint()


func _update_advance_turn_button() -> void:
	if advance_turn_button == null:
		return
	var side_text := _side_label(turn_controller.current_side)
	advance_turn_button.text = "%s\n点击推进" % _current_side_feedback_label()
	advance_turn_button.tooltip_text = "当前是%s行动，%s；点击后结算本方抽牌、部署、移动/攻击，并切换行动侧。" % [side_text, _side_direction_text(turn_controller.current_side)]
	advance_turn_button.custom_minimum_size = Vector2(248, 118)
	advance_turn_button.add_theme_font_size_override("font_size", 30)
	# 复用缓存 StyleBoxFlat，每帧只改颜色属性
	_advance_style.bg_color = StarPaletteScript.active_bg(turn_controller.current_side).lightened(0.16)
	_advance_style.border_color = StarPaletteScript.active_border(turn_controller.current_side)
	advance_turn_button.add_theme_stylebox_override("normal", _advance_style)
	advance_turn_button.add_theme_stylebox_override("hover", _advance_style)
	advance_turn_button.add_theme_stylebox_override("pressed", _advance_style)
	advance_turn_button.add_theme_color_override("font_color", StarPaletteScript.TEXT_GOLD)


func _format_side_hud(side: String) -> String:
	var deck_count := _deck_for_side(side).size()
	var hand_count := _hand_for_side(side).size()
	var hp: int = battle_state.get_master_hp(side)
	var max_hp: int = battle_state.get_master_max_hp(side)
	var star_power: int = battle_state.get_star_power(side)
	var active_marker := "● 当前行动" if turn_controller.current_side == side else "待命观星"
	return "%s - %s\nHP %s %d/%d\n星力 %s %d\n牌库 %d%s  手牌 %d" % [
		_side_label(side),
		active_marker,
		_meter_text(hp, max_hp, 10, "■", "□"),
		hp,
		max_hp,
		_star_power_text(star_power),
		star_power,
		deck_count,
		"（抽空）" if deck_count == 0 else "",
		hand_count,
	]


func _meter_text(value: int, max_value: int, steps: int, filled_char: String, empty_char: String) -> String:
	var safe_max: int = max(1, max_value)
	var clamped_value: int = clampi(value, 0, safe_max)
	var filled := int(round(float(clamped_value) / float(safe_max) * float(steps)))
	filled = clampi(filled, 0, steps)
	return "%s%s" % [filled_char.repeat(filled), empty_char.repeat(steps - filled)]


func _star_power_text(star_power: int) -> String:
	return _meter_text(star_power, 10, 10, "*", ".")


func _update_card_zone_summary() -> void:
	card_zone_view.collapsed = card_zone_collapsed
	card_zone_view.selected_card_hero_id = selected_card_hero_id
	card_zone_view.set_piles(player_hand, player_discard, enemy_hand, enemy_discard)
	card_zone_view.refresh()
	card_zone_collapsed = card_zone_view.collapsed
	selected_card_hero_id = card_zone_view.selected_card_hero_id
	_update_overlay_dismiss_visibility()


func _format_card_zone_for_side(side: String) -> String:
	return "%s 牌库：%s  手牌：%s  弃牌：%s" % [
		_side_label(side),
		_format_deck_status(side),
		_format_card_names(_hand_for_side(side)),
		_format_card_names(_discard_for_side(side)),
	]


func _format_card_names(hero_ids: Array) -> String:
	if hero_ids.is_empty():
		return "无"
	var names: Array[String] = []
	for hero_id_value in hero_ids:
		names.append(_format_card_name_with_cost(str(hero_id_value)))
	return "、".join(names)


func _format_card_zone_detail() -> String:
	var player_hand := _hand_for_side(BoardModelScript.SIDE_LEFT)
	var enemy_hand := _hand_for_side(BoardModelScript.SIDE_RIGHT)
	var player_discard := _discard_for_side(BoardModelScript.SIDE_LEFT)
	var enemy_discard := _discard_for_side(BoardModelScript.SIDE_RIGHT)
	return "\n".join([
		"[b]我方[/b]：牌库 %s｜手牌 %d｜弃牌 %d" % [_format_deck_status(BoardModelScript.SIDE_LEFT), player_hand.size(), player_discard.size()],
		"[b]敌方[/b]：牌库 %s｜手牌 %d｜弃牌 %d" % [_format_deck_status(BoardModelScript.SIDE_RIGHT), enemy_hand.size(), enemy_discard.size()],
		"[i]详细牌序属于后台数据，前端只显示数量。[/i]",
	])


func _format_deck_status(side: String) -> String:
	var deck_count := _deck_for_side(side).size()
	if deck_count == 0:
		if _discard_for_side(side).is_empty():
			return "0（无可回收）"
		return "0（待洗回 %d）" % _discard_for_side(side).size()
	return "%d" % deck_count


func _format_card_name_with_cost(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	return "%s(%d)" % [str(hero_def.get("name", hero_id)), int(hero_def.get("cost", 0))]


func _refresh_card_zone_cards() -> void:
	card_zone_view.set_piles(player_hand, player_discard, enemy_hand, enemy_discard)
	card_zone_view.selected_card_hero_id = selected_card_hero_id
	card_zone_view.refresh_cards()
	selected_card_hero_id = card_zone_view.selected_card_hero_id


func _add_card_zone_row(title: String, hero_ids: Array) -> void:
	card_zone_view.set_piles([], [], [], [])
	card_zone_view._add_card_zone_row(title, hero_ids)


func _format_card_button_text(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	return "%s - 费%d\n阵营：%s" % [
		str(hero_def.get("name", hero_id)),
		int(hero_def.get("cost", 0)),
		_faction_text(str(hero_def.get("faction", ""))),
	]


func _format_card_tooltip(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	return "%s - 费用 %d - 阵营 %s" % [
		str(hero_def.get("name", hero_id)),
		int(hero_def.get("cost", 0)),
		_faction_text(str(hero_def.get("faction", ""))),
	]


func _apply_card_button_style(card_button: Button, hero_id: String, selected: bool) -> void:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	var faction_id := str(hero_def.get("faction", ""))
	var class_id := str(hero_def.get("class", ""))
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = _faction_card_color(faction_id)
	card_style.border_color = _class_border_color(class_id)
	card_style.set_border_width_all(4 if selected else 3)
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 12
	card_style.content_margin_top = 8
	card_style.content_margin_right = 12
	card_style.content_margin_bottom = 8
	card_button.add_theme_stylebox_override("normal", card_style)
	card_button.add_theme_stylebox_override("hover", card_style)
	card_button.add_theme_stylebox_override("pressed", card_style)
	card_button.add_theme_color_override("font_color", StarPaletteScript.TEXT_CREAM)
	card_button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.88, 1.0))
	card_button.add_theme_font_size_override("font_size", 24)


func _select_card_for_inspect(hero_id: String) -> void:
	card_zone_view.select_card_for_inspect(hero_id)
	selected_card_hero_id = card_zone_view.selected_card_hero_id


func _refresh_card_inspect_label() -> void:
	card_zone_view.selected_card_hero_id = selected_card_hero_id
	card_zone_view.refresh_inspect_label()


func _format_card_inspect_text(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	if hero_def.is_empty():
		return "[b]牌面说明[/b]：未知卡牌 %s" % hero_id
	return "\n".join([
		"[b]%s[/b]｜费用 %d｜阵营 %s" % [
			str(hero_def.get("name", hero_id)),
			int(hero_def.get("cost", 0)),
			_faction_text(str(hero_def.get("faction", ""))),
		],
		"生命 %d｜攻击 %d｜射程 %d｜移动 %d｜格挡 物理 %d / 法术 %d" % [
			int(hero_def.get("max_hp", 0)),
			int(hero_def.get("attack", 0)),
			int(hero_def.get("range", 0)),
			int(hero_def.get("move", 0)),
			int(hero_def.get("physical_block", 0)),
			int(hero_def.get("magic_block", 0)),
		],
		"技能：%s" % _format_hero_skill_descriptions(hero_def),
	])


func _format_hero_skill_descriptions(hero_def: Dictionary) -> String:
	var skill_ids: Array = hero_def.get("skill_ids", [])
	if skill_ids.is_empty():
		return "无"
	var parts: Array[String] = []
	for skill_id_value in skill_ids:
		var skill_def := _skill_def(str(skill_id_value))
		if skill_def.is_empty():
			parts.append(str(skill_id_value))
		else:
			parts.append("%s：%s" % [str(skill_def.get("name", skill_id_value)), str(skill_def.get("description", ""))])
	return "；".join(parts)


func _skill_def(skill_id: String) -> Dictionary:
	for skill_def: Dictionary in battle_state.get_skill_defs():
		if str(skill_def.get("id", "")) == skill_id:
			return skill_def
	return {}


func _hero_id_not_in_visible_card_zones(hero_id: String) -> bool:
	card_zone_view.set_piles(player_hand, player_discard, enemy_hand, enemy_discard)
	return card_zone_view._hero_id_not_in_visible_card_zones(hero_id)


func _first_visible_card_id() -> String:
	card_zone_view.set_piles(player_hand, player_discard, enemy_hand, enemy_discard)
	return card_zone_view._first_visible_card_id()


func _toggle_card_zone() -> void:
	card_zone_view.collapsed = card_zone_collapsed
	card_zone_view.selected_card_hero_id = selected_card_hero_id
	card_zone_view.set_piles(player_hand, player_discard, enemy_hand, enemy_discard)
	card_zone_view.toggle()
	card_zone_collapsed = card_zone_view.collapsed
	selected_card_hero_id = card_zone_view.selected_card_hero_id


func _close_card_zone() -> void:
	card_zone_view.close()
	card_zone_collapsed = card_zone_view.collapsed
	selected_card_hero_id = card_zone_view.selected_card_hero_id


func _close_all_drawers() -> void:
	card_zone_view.close()
	card_zone_collapsed = card_zone_view.collapsed
	selected_card_hero_id = card_zone_view.selected_card_hero_id
	battle_log_view.close()
	battle_log_collapsed = battle_log_view.collapsed
	_update_log_visibility()


func _dismiss_first_deploy_hint() -> void:
	battle_tutorial_view.dismiss_first_deploy_hint()
	first_deploy_hint_dismissed = battle_tutorial_view.first_deploy_hint_dismissed


func _update_first_deploy_hint() -> void:
	battle_tutorial_view.first_deploy_hint_dismissed = first_deploy_hint_dismissed
	battle_tutorial_view.update_first_deploy_hint()
	first_deploy_hint_dismissed = battle_tutorial_view.first_deploy_hint_dismissed


func _add_battle_log(actor: String, action: String, result: String) -> void:
	battle_log_view.add(turn_controller.turn_number, actor, action, result)
	battle_log_entries = battle_log_view.entries


func _compact_log_result(result: String) -> String:
	return battle_log_view.compact_result(result)


func _refresh_battle_log() -> void:
	battle_log_view.refresh()
	battle_log_entries = battle_log_view.entries


func _toggle_battle_log() -> void:
	battle_log_view.toggle()
	battle_log_collapsed = battle_log_view.collapsed
	_update_log_visibility()


func _close_battle_log() -> void:
	battle_log_view.close()
	battle_log_collapsed = battle_log_view.collapsed
	_update_log_visibility()


func _update_log_visibility() -> void:
	battle_log_view.update_visibility()
	battle_log_collapsed = battle_log_view.collapsed
	_update_overlay_dismiss_visibility()


func _update_overlay_dismiss_visibility() -> void:
	overlay_dismiss_button.visible = not card_zone_collapsed or not battle_log_view.collapsed

func _log_auto_deploy(auto_deploy_result: Dictionary) -> void:
	if auto_deploy_result.is_empty():
		return
	if bool(auto_deploy_result.get("ok", false)):
		var unit_data: Dictionary = auto_deploy_result.unit
		_add_battle_log(_unit_display_name(unit_data), "自动部署", "消耗 %d 星力，进入 (%d,%d)" % [
			int(auto_deploy_result.get("cost", 0)),
			int(unit_data.get("column", 0)),
			int(unit_data.get("row", 0)),
		])
		_log_skill_results(_unit_display_name(unit_data), auto_deploy_result.get("skill_results", []))
		return
	_add_battle_log("敌方", "自动部署", "跳过：%s" % _reason_text(str(auto_deploy_result.get("reason", ""))))


func _log_action_results(acting_units: Array, action_results: Array) -> void:
	for index in range(action_results.size()):
		var action_result: Dictionary = action_results[index]
		var actor := "单位"
		if index < acting_units.size():
			actor = _unit_display_name(acting_units[index])
		_add_battle_log(actor, _action_label(action_result), _action_result_summary(action_result))
		_log_skill_results(actor, action_result.get("skill_results", []))


func _log_skill_results(actor: String, skill_results: Array) -> void:
	for skill_result: Dictionary in skill_results:
		_add_battle_log(actor, "技能", _skill_result_summary(skill_result))


func _log_status_results(status_results: Array) -> void:
	for status_result: Dictionary in status_results:
		_add_battle_log(str(status_result.get("target_id", "单位")), "状态", "%s造成 %d 点伤害" % [
			_status_text(str(status_result.get("status", ""))),
			int(status_result.get("damage", 0)),
		])


func _action_label(action_result: Dictionary) -> String:
	if action_result.has("move") and str(action_result.get("action", "")) == "attack":
		return "移动后攻击"
	match str(action_result.get("action", "")):
		"attack":
			return "攻击"
		"move":
			return "移动"
		_:
			return "行动"


func _action_result_summary(action_result: Dictionary) -> String:
	var parts: Array[String] = []
	if action_result.has("move"):
		parts.append(_move_summary(action_result.move))
	if str(action_result.get("action", "")) == "attack":
		if str(action_result.get("target_type", "")) == "master":
			parts.append("攻击弈星师，造成 %d 点伤害" % int(action_result.get("damage", 0)))
		else:
			parts.append("攻击 %s，造成 %d 点伤害" % [
				str(action_result.get("target_id", "")),
				int(action_result.get("damage", 0)),
			])
	if parts.is_empty():
		parts.append(_move_summary(action_result.get("move", {})))
	return "; ".join(parts)


func _move_summary(move_result: Dictionary) -> String:
	var from_cell: Vector2i = move_result.get("from", Vector2i.ZERO)
	var to_cell: Vector2i = move_result.get("to", Vector2i.ZERO)
	return "从 (%d,%d) 移动到 (%d,%d)，步数 %d" % [
		from_cell.x,
		from_cell.y,
		to_cell.x,
		to_cell.y,
		int(move_result.get("steps", 0)),
	]


func _skill_result_summary(skill_result: Dictionary) -> String:
	var skill_id := str(skill_result.get("skill_id", "skill"))
	if skill_result.has("summoned_count"):
		return "%s 召唤 %d 个单位" % [_skill_text(skill_id), int(skill_result.get("summoned_count", 0))]
	if skill_result.has("status_id"):
		return "%s 对 %s 施加 %s" % [
			_skill_text(skill_id),
			str(skill_result.get("target_id", "")),
			_status_text(str(skill_result.get("status_id", ""))),
		]
	if skill_result.has("bonus_damage"):
		return "%s 对 %s 追加 %d 点伤害" % [
			_skill_text(skill_id),
			str(skill_result.get("target_id", "")),
			int(skill_result.get("bonus_damage", 0)),
		]
	if bool(skill_result.get("ok", false)):
		return "%s 已触发" % _skill_text(skill_id)
	return "%s 触发失败：%s" % [_skill_text(skill_id), _reason_text(str(skill_result.get("reason", "")))]


func _side_label(side: String) -> String:
	if side == BoardModelScript.SIDE_LEFT:
		return "我方"
	return "敌方"


func _reason_text(reason: String) -> String:
	return str(REASON_TEXT.get(reason, reason))


func _deployment_failure_message(reason: String, hero_id: String, column: int, row: int) -> String:
	var hero_name: String = _hero_name(hero_id) if not hero_id.is_empty() else "当前手牌"
	match reason:
		"not_deployment_zone", "not_own_deployment_zone":
			return "当前点到 (%d,%d)，这里不是我方蓝色部署区。请把 %s 放到左侧蓝色区域空格。" % [column, row, hero_name]
		"not_enough_star_power":
			var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
			var cost: int = int(hero_def.get("cost", 0))
			var star_power: int = battle_state.get_star_power(BoardModelScript.SIDE_LEFT)
			return "星力不足：%s 需要 %d 星力，当前只有 %d。可先点「推进回合」恢复星力，或改选低费手牌。" % [hero_name, cost, star_power]
		"cell_occupied":
			return "目标格 (%d,%d) 已有单位。请点蓝色部署区内的其他空格；再次点该单位可查看详情。" % [column, row]
		"unknown_hero":
			return "未选择可部署手牌。请先点击底部手牌，再点蓝色部署区空格。"
		"cell_out_of_bounds":
			return "格子 (%d,%d) 超出棋盘。请点击棋盘内蓝色部署区空格。" % [column, row]
		_:
			return "%s。请先选底部手牌，再点左侧蓝色部署区空格。" % _reason_text(reason)


func _format_deployment_failure_status(reason: String, hero_id: String, column: int, row: int) -> String:
	var message := _deployment_failure_message(reason, hero_id, column, row)
	if _should_activate_deploy_failure_highlight(reason):
		message += " 金边格就是当前可部署位置。"
	return message


func _show_deploy_failure_toast(reason: String) -> void:
	battle_tutorial_view.show_deploy_failure_toast(reason)
	deploy_failure_toast_time_left = battle_tutorial_view.deploy_failure_toast_time_left


func _hide_deploy_failure_toast() -> void:
	battle_tutorial_view.hide_deploy_failure_toast()
	deploy_failure_toast_time_left = battle_tutorial_view.deploy_failure_toast_time_left


func _status_text(status_id: String) -> String:
	return str(STATUS_TEXT.get(status_id, status_id))


func _skill_text(skill_id: String) -> String:
	var skill_defs: Array = battle_state.get_skill_defs()
	for skill_def: Dictionary in skill_defs:
		if str(skill_def.get("id", "")) == skill_id:
			return str(skill_def.get("name", skill_id))
	return skill_id


func _outcome_text(outcome: String) -> String:
	match outcome:
		"left_wins":
			return "我方胜利"
		"right_wins":
			return "敌方胜利"
		"both_failed":
			return "双方失败"
		_:
			return "战斗结束"


func _refresh_board() -> void:
	battle_board_view.refresh()
	cell_buttons = battle_board_view.cell_buttons


func _format_cell_text(column: int, row: int, unit_data: Dictionary) -> String:
	var terrain_id: String = battle_state.terrain_system.get_terrain(column, row)
	var terrain_text := ""
	if terrain_id != TerrainSystemScript.TERRAIN_GRASS:
		terrain_text = "\n%s" % _terrain_text(terrain_id)
	if unit_data.is_empty():
		var hint_text: String = "\n● 可上阵" if _should_show_recommended_deploy_cell(column, row) else ""
		return "%s\n%d,%d%s%s" % [_zone_code(column, row), column, row, terrain_text, hint_text]
	var hero_def: Dictionary = battle_state.get_hero_def(str(unit_data.get("hero_id", "")))
	var faction_id := str(unit_data.get("faction", hero_def.get("faction", "")))
	var side := str(unit_data.get("side", ""))
	var action_hint := "\n● %s" % _side_direction_text(side) if side == turn_controller.current_side else ""
	return "%s%s - %s\n%s%s\nHP %d/%d%s" % [
		_side_arrow(side),
		_side_label(side),
		_faction_text(faction_id),
		_unit_display_name(unit_data),
		action_hint,
		int(unit_data.get("hp", 0)),
		int(unit_data.get("max_hp", 0)),
		terrain_text,
	]


func _format_skill_results(skill_results: Array) -> String:
	if skill_results.is_empty():
		return ""
	var summaries: Array[String] = []
	for skill_result: Dictionary in skill_results:
		var skill_id := str(skill_result.get("skill_id", ""))
		if skill_result.has("summoned_count"):
			summaries.append(" %s 召唤 %d 个单位。" % [_skill_text(skill_id), int(skill_result.summoned_count)])
		elif bool(skill_result.get("ok", false)):
			summaries.append(" %s 已触发。" % _skill_text(skill_id))
		else:
			summaries.append(" %s 失败：%s。" % [_skill_text(skill_id), _reason_text(str(skill_result.get("reason", "")))])
	return "".join(summaries)


func _hp_bar_text(unit_data: Dictionary) -> String:
	var max_hp: int = max(1, int(unit_data.get("max_hp", 1)))
	var hp: int = clampi(int(unit_data.get("hp", 0)), 0, max_hp)
	var filled := int(round(float(hp) / float(max_hp) * 5.0))
	filled = clampi(filled, 0, 5)
	return "%s%s" % ["|".repeat(filled), ".".repeat(5 - filled)]


func _unit_hp_percent(unit_data: Dictionary) -> int:
	var max_hp: int = max(1, int(unit_data.get("max_hp", 1)))
	var hp: int = clampi(int(unit_data.get("hp", 0)), 0, max_hp)
	return int(round(float(hp) / float(max_hp) * 100.0))


func _reset_debug_battle() -> void:
	battle_state.reset()
	turn_controller.setup(battle_state, BoardModelScript.SIDE_LEFT)
	battle_state.terrain_system.generate_deterministic(1)
	_initialize_card_piles()
	last_touched_cell = Vector2i.ZERO
	last_action_cells.clear()
	first_deploy_hint_dismissed = false
	deploy_failure_highlight_active = false
	tutorial_turn_advanced = false
	_battle_started_emitted = false
	battle_tutorial_view.first_deploy_hint_dismissed = false
	battle_tutorial_view.tutorial_turn_advanced = false
	_hide_deploy_failure_toast()
	_hide_unit_detail()
	_refresh_board()
	_update_status("调试战斗已重置。")


func _update_hero_buttons() -> void:
	for hero_id in _player_battle_hero_ids():
		var hero_button: Button = hero_buttons[hero_id]
		var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
		var in_hand: bool = player_hand.has(hero_id)
		var in_deck: bool = player_deck.has(hero_id)
		var selected: bool = hero_id == selected_hero_id and in_hand
		var affordable: bool = in_hand and battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id)
		var selection_text := _hand_piece_state_text(selected, in_hand, in_deck, affordable)
		hero_button.disabled = not in_hand
		var hero_button_lines := "%s - %s" + String.chr(10) + "*%d - %s - %s"
		hero_button.text = hero_button_lines % [
			selection_text,
			str(hero_def.get("name", hero_id)),
			int(hero_def.get("cost", 0)),
			_faction_text(str(hero_def.get("faction", ""))),
			_hand_piece_suffix(in_hand, in_deck, affordable),
		]
		_apply_hand_piece_button_style(hero_button, hero_id, selected, in_hand, affordable)


func _hand_piece_state_text(selected: bool, in_hand: bool, in_deck: bool, affordable: bool) -> String:
	if selected:
		return "● 已选上阵"
	if not in_hand:
		return "牌库候补" if in_deck else "已出战"
	return "可部署" if affordable else "星力不足"


func _hand_piece_suffix(in_hand: bool, in_deck: bool, affordable: bool) -> String:
	if not in_hand:
		return "牌库候补" if in_deck else "已出"
	return "点蓝区部署" if affordable else "先推进回合"


func _apply_hand_piece_button_style(hero_button: Button, hero_id: String, selected: bool, enabled: bool, affordable: bool) -> void:
	var style: StyleBoxFlat = _hero_button_styles.get(hero_id)
	if style == null:
		return
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	var base_color: Color = StarPaletteScript.faction_color(str(hero_def.get("faction", "")))
	# 根据状态微调颜色和边框
	if selected:
		style.bg_color = base_color.lightened(0.24)
		style.border_color = StarPaletteScript.HIGHLIGHT_SELECTED
		style.set_border_width_all(7)
		style.content_margin_left = 14
		style.content_margin_top = 8
		style.content_margin_right = 14
		style.content_margin_bottom = 8
	elif enabled and affordable:
		style.bg_color = base_color.lightened(0.08)
		style.border_color = Color(0.42, 1.0, 0.76, 0.88)
		style.set_border_width_all(5)
		style.content_margin_left = 12
		style.content_margin_top = 6
		style.content_margin_right = 12
		style.content_margin_bottom = 6
	elif enabled and not affordable:
		style.bg_color = base_color.darkened(0.18)
		style.border_color = Color(0.80, 0.74, 0.60, 0.70)
		style.set_border_width_all(3)
		style.content_margin_left = 12
		style.content_margin_top = 6
		style.content_margin_right = 12
		style.content_margin_bottom = 6
	else:
		style.bg_color = base_color.darkened(0.42)
		style.border_color = Color(0.80, 0.74, 0.60, 0.70)
		style.set_border_width_all(3)
		style.content_margin_left = 12
		style.content_margin_top = 6
		style.content_margin_right = 12
		style.content_margin_bottom = 6
	hero_button.custom_minimum_size = Vector2(290, 116) if selected else (Vector2(274, 104) if enabled and affordable else Vector2(258, 98))
	hero_button.add_theme_stylebox_override("normal", style)
	hero_button.add_theme_stylebox_override("hover", style)
	hero_button.add_theme_stylebox_override("pressed", style)
	hero_button.add_theme_stylebox_override("disabled", style)
	hero_button.add_theme_color_override("font_color", StarPaletteScript.TEXT_CREAM if selected else (StarPaletteScript.TEXT_GREEN_READY if enabled and affordable else StarPaletteScript.TEXT_CREAM))
	hero_button.add_theme_color_override("font_disabled_color", StarPaletteScript.TEXT_SECONDARY)
	hero_button.add_theme_font_size_override("font_size", 26 if selected else 24)


func _return_home() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.screen_changed.emit(HOME_SCREEN)


func _check_battle_end() -> Dictionary:
	var left_hp: int = battle_state.get_master_hp(BoardModelScript.SIDE_LEFT)
	var right_hp: int = battle_state.get_master_hp(BoardModelScript.SIDE_RIGHT)
	var left_survivors := _count_survivors(BoardModelScript.SIDE_LEFT)
	var right_survivors := _count_survivors(BoardModelScript.SIDE_RIGHT)
	var left_defeated := left_hp <= 0 or _side_has_no_deck_hand_or_units(BoardModelScript.SIDE_LEFT, left_survivors)
	var right_defeated := right_hp <= 0 or _side_has_no_deck_hand_or_units(BoardModelScript.SIDE_RIGHT, right_survivors)
	if not left_defeated and not right_defeated:
		return {}

	var outcome := ""
	if left_defeated and right_defeated:
		outcome = "both_failed"
	elif right_defeated:
		outcome = "left_wins"
	else:
		outcome = "right_wins"

	return {
		"outcome": outcome,
		"round_number": turn_controller.turn_number,
		"left_hp": left_hp,
		"right_hp": right_hp,
		"left_survivors": left_survivors,
		"right_survivors": right_survivors,
		"stats": battle_state.battle_stats.snapshot(),
	}

func _count_survivors(side: String) -> int:
	var survivor_count := 0
	for unit_data: Dictionary in battle_state.get_units_by_side(side):
		if int(unit_data.get("hp", 0)) > 0:
			survivor_count += 1
	return survivor_count

func _side_has_no_deck_hand_or_units(side: String, survivor_count: int) -> bool:
	return survivor_count <= 0 and battle_deck.has_no_deck_hand(side)


func _should_show_recommended_deploy_cell(column: int, row: int) -> bool:
	if first_deploy_hint_dismissed and not deploy_failure_highlight_active:
		return false
	if not deploy_failure_highlight_active and not battle_state.get_units_by_side(BoardModelScript.SIDE_LEFT).is_empty():
		return false
	if not battle_state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, column, row):
		return false
	if battle_state.board.is_occupied(column, row):
		return false
	return true


func _should_activate_deploy_failure_highlight(reason: String) -> bool:
	return battle_tutorial_view._should_activate_deploy_failure_highlight(reason)


func _update_tutorial_progress() -> void:
	battle_tutorial_view.tutorial_turn_advanced = tutorial_turn_advanced
	battle_tutorial_view.update_tutorial_progress()
	tutorial_turn_advanced = battle_tutorial_view.tutorial_turn_advanced


func _update_tutorial_step_label(label: Label, text: String, done: bool) -> void:
	battle_tutorial_view._update_tutorial_step_label(label, text, done)


func _apply_tutorial_progress_row_style() -> void:
	battle_tutorial_view.apply_progress_row_style()


func _apply_tutorial_step_style(label: Label, done: bool, title: bool = false) -> void:
	battle_tutorial_view._apply_tutorial_step_style(label, done, title)


func _step_marker(done: bool) -> String:
	return battle_tutorial_view._step_marker(done)


func _hand_for_side(side: String) -> Array:
	return battle_deck.hand_for_side(side)

func _deck_for_side(side: String) -> Array:
	return battle_deck.deck_for_side(side)

func _consume_hero_from_hand(side: String, hero_id: String) -> void:
	battle_deck.consume_from_hand(side, hero_id)
	_sync_card_pile_references()

func _discard_for_side(side: String) -> Array:
	return battle_deck.discard_for_side(side)

func _select_next_available_hero() -> void:
	if player_hand.has(selected_hero_id):
		return
	if player_hand.is_empty():
		selected_hero_id = ""
		return
	selected_hero_id = str(player_hand[0])

func _hero_name(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	return str(hero_def.get("name", hero_id))


func _player_battle_hero_ids() -> Array:
	if configured_player_deck.is_empty():
		return STARTING_PLAYER_DECK.duplicate()
	return configured_player_deck.duplicate()


func _enemy_battle_hero_ids() -> Array:
	if configured_enemy_deck.is_empty():
		return STARTING_ENEMY_DECK.duplicate()
	return configured_enemy_deck.duplicate()


func _validated_deck_from_data(value, fallback: Array) -> Array:
	var result: Array = []
	if value is Array:
		for hero_id_value in value:
			var hero_id := str(hero_id_value)
			if battle_state.get_hero_def(hero_id).is_empty():
				continue
			result.append(hero_id)
	if result.is_empty():
		return fallback.duplicate()
	return result


func _route_to_result(battle_result: Dictionary) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.screen_changed.emit(RESULT_SCREEN, battle_result)


func _save_current_state() -> void:
	var deck: Array = _player_battle_hero_ids()
	var save_data: Dictionary = SaveServiceScript.build_save_from_appState(_app_state, deck)
	SaveServiceScript.save_game(save_data)


func _make_cell_style(column: int, row: int, unit_data: Dictionary) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var cell := Vector2i(column, row)
	var terrain_id: String = battle_state.terrain_system.get_terrain(column, row)
	match terrain_id:
		TerrainSystemScript.TERRAIN_SWAMP:
			style.bg_color = StarPaletteScript.TERRAIN_SWAMP_BG
		TerrainSystemScript.TERRAIN_RIVER:
			style.bg_color = StarPaletteScript.TERRAIN_RIVER_BG
		TerrainSystemScript.TERRAIN_HIGHLAND:
			style.bg_color = StarPaletteScript.TERRAIN_HIGHLAND_BG
		_:
			style.bg_color = _zone_color(column, row)
	if not unit_data.is_empty():
		style.bg_color = _unit_side_color(str(unit_data.get("side", "")))
	style.border_color = _zone_border_color(column, row)
	var unit_side := str(unit_data.get("side", ""))
	if unit_side == BoardModelScript.SIDE_LEFT:
		style.border_color = Color(0.64, 0.92, 1.0, 1.0)
	elif unit_side == BoardModelScript.SIDE_RIGHT:
		style.border_color = Color(1.0, 0.48, 0.76, 1.0)
	if not unit_data.is_empty() and unit_side == turn_controller.current_side:
		style.border_color = _active_side_feedback_color(unit_side)
		style.bg_color = style.bg_color.lightened(0.18)
	if unit_data.is_empty() and battle_state.board.is_deployment_cell(BoardModelScript.SIDE_LEFT, column, row):
		style.border_color = StarPaletteScript.HIGHLIGHT_EDGE_ROW
	if _should_show_recommended_deploy_cell(column, row):
		style.border_color = StarPaletteScript.HIGHLIGHT_DEPLOY
		style.bg_color = style.bg_color.lightened(0.18)
	if unit_data.is_empty() and row in [1, 5]:
		style.border_color = style.border_color.lightened(0.18)
	if cell == last_touched_cell:
		style.border_color = StarPaletteScript.HIGHLIGHT_SELECTED
		style.bg_color = style.bg_color.lightened(0.26)
	if last_action_cells.has(cell):
		style.border_color = StarPaletteScript.HIGHLIGHT_ACTION
		style.bg_color = style.bg_color.lightened(0.22)
	if selected_detail_unit_id == str(unit_data.get("instance_id", "")) and not selected_detail_unit_id.is_empty():
		style.border_color = StarPaletteScript.HIGHLIGHT_SELECTED
		style.bg_color = style.bg_color.lightened(0.30)
	style.set_border_width_all(3)
	if not unit_data.is_empty():
		style.set_border_width_all(5)
	if not unit_data.is_empty() and unit_side == turn_controller.current_side:
		style.set_border_width_all(6)
	if _should_show_recommended_deploy_cell(column, row):
		style.set_border_width_all(5)
	if cell == last_touched_cell or last_action_cells.has(cell) or selected_detail_unit_id == str(unit_data.get("instance_id", "")):
		style.set_border_width_all(6)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8 if unit_data.is_empty() else 10
	style.content_margin_top = 5 if unit_data.is_empty() else 8
	style.content_margin_right = 8 if unit_data.is_empty() else 10
	style.content_margin_bottom = 5 if unit_data.is_empty() else 8
	return style


func _show_unit_detail(unit_data: Dictionary) -> void:
	selected_detail_unit_id = str(unit_data.get("instance_id", ""))
	unit_detail_title.text = "%s %s - %s - %d%%" % [
		_side_arrow(str(unit_data.get("side", ""))),
		_unit_display_name(unit_data),
		_side_label(str(unit_data.get("side", ""))),
		_unit_hp_percent(unit_data),
	]
	unit_detail_body.text = _format_unit_detail(unit_data)
	unit_detail_panel.visible = true


func _show_card_detail(hero_id: String) -> void:
	selected_detail_unit_id = ""
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	unit_detail_title.text = "卡牌 - %s - 费用 *%d - 阵营 %s" % [
		str(hero_def.get("name", hero_id)),
		int(hero_def.get("cost", 0)),
		_faction_text(str(hero_def.get("faction", ""))),
	]
	unit_detail_body.text = _format_card_detail(hero_id)
	unit_detail_panel.visible = true


func _hide_unit_detail() -> void:
	selected_detail_unit_id = ""
	unit_detail_panel.visible = false


func _format_unit_detail(unit_data: Dictionary) -> String:
	var terrain_id: String = battle_state.terrain_system.get_terrain(int(unit_data.get("column", 0)), int(unit_data.get("row", 0)))
	var skill_text := _format_unit_skills(unit_data)
	var status_text := _format_unit_statuses(unit_data)
	var side := str(unit_data.get("side", ""))
	return "\n".join([
		"[b]点击反馈[/b]：已选中场上单位；再点空格可继续部署，点其他单位可切换查看。",
		"[b]位置[/b]：(%d,%d)｜%s" % [int(unit_data.get("column", 0)), int(unit_data.get("row", 0)), _terrain_text(terrain_id)],
		"[b]方向[/b]：%s｜[b]阵营[/b]：%s" % [_side_direction_text(side), _faction_text(str(unit_data.get("faction", "")))],
		"[b]生命[/b]：%d/%d（%d%%）｜[b]攻击[/b]：%d｜[b]射程[/b]：%d｜[b]移动[/b]：%d" % [
			int(unit_data.get("hp", 0)),
			int(unit_data.get("max_hp", 0)),
			_unit_hp_percent(unit_data),
			battle_state.get_unit_attack(unit_data),
			int(unit_data.get("range", 0)),
			int(unit_data.get("move", 0)),
		],
		"[b]格挡[/b]：物理 %d｜法术 %d" % [int(unit_data.get("physical_block", 0)), int(unit_data.get("magic_block", 0))],
		"[b]技能[/b]：%s" % skill_text,
		"[b]状态[/b]：%s" % status_text,
	])


func _format_card_detail(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	if hero_def.is_empty():
		return "[b]卡牌说明[/b]：未知卡牌 %s" % hero_id
	return "\n".join([
		"[b]点击反馈[/b]：已选中此手牌；点左侧蓝色部署区空格即可上阵。",
		"[b]部署提示[/b]：费用足够时直接部署；星力不足时可先点「推进回合」回星。",
		"[b]费用[/b]：%d 星力｜[b]阵营[/b]：%s" % [
			int(hero_def.get("cost", 0)),
			_faction_text(str(hero_def.get("faction", ""))),
		],
		"[b]基础[/b]：生命 %d｜攻击 %d｜射程 %d｜移动 %d" % [
			int(hero_def.get("max_hp", 0)),
			int(hero_def.get("attack", 0)),
			int(hero_def.get("range", 0)),
			int(hero_def.get("move", 0)),
		],
		"[b]格挡[/b]：物理 %d｜法术 %d" % [int(hero_def.get("physical_block", 0)), int(hero_def.get("magic_block", 0))],
		"[b]技能[/b]：%s" % _format_hero_skill_descriptions(hero_def),
	])


func _format_unit_skills(unit_data: Dictionary) -> String:
	var skill_ids: Array = unit_data.get("skill_ids", [])
	if skill_ids.is_empty():
		return "无"
	var names: Array[String] = []
	for skill_id_value in skill_ids:
		names.append(_skill_text(str(skill_id_value)))
	return "、".join(names)


func _format_unit_statuses(unit_data: Dictionary) -> String:
	var statuses_value = unit_data.get("statuses", {})
	if statuses_value is Dictionary:
		if statuses_value.is_empty():
			return "无"
		var names: Array[String] = []
		for status_id in statuses_value.keys():
			names.append(_status_text(str(status_id)))
		return "、".join(names)
	if statuses_value is Array:
		if statuses_value.is_empty():
			return "无"
		var names: Array[String] = []
		for status: Dictionary in statuses_value:
			names.append(_status_text(str(status.get("id", ""))))
		return "、".join(names)
	return "无"


func _class_text(class_id: String) -> String:
	match class_id:
		"warrior":
			return "战士"
		"mage":
			return "法师"
		"tank":
			return "坦克"
		"archer":
			return "射手"
		"guard":
			return "武卫"
		"assassin":
			return "刺客"
		_:
			return class_id if not class_id.is_empty() else "未知"


func _damage_type_text(damage_type: String) -> String:
	match damage_type:
		"physical":
			return "物理"
		"magic":
			return "法术"
		"true":
			return "真实"
		_:
			return damage_type if not damage_type.is_empty() else "未知"


func _faction_text(faction_id: String) -> String:
	match faction_id:
		"shu":
			return "蜀"
		"wei":
			return "魏"
		"wu":
			return "吴"
		"qun":
			return "群"
		_:
			return faction_id if not faction_id.is_empty() else "未知"


func _faction_card_color(faction_id: String) -> Color:
	return StarPaletteScript.faction_color(faction_id)


func _class_border_color(class_id: String) -> Color:
	return StarPaletteScript.class_border(class_id)


func _terrain_text(terrain_id: String) -> String:
	match terrain_id:
		TerrainSystemScript.TERRAIN_GRASS:
			return "草地"
		TerrainSystemScript.TERRAIN_SWAMP:
			return "泥沼"
		TerrainSystemScript.TERRAIN_RIVER:
			return "河流"
		TerrainSystemScript.TERRAIN_HIGHLAND:
			return "高地"
		_:
			return terrain_id if not terrain_id.is_empty() else "未知地形"


func _capture_action_cells(action_results: Array) -> void:
	last_action_cells.clear()
	for action_result: Dictionary in action_results:
		if action_result.has("move"):
			_add_unique_action_cell(action_result.move.get("from", Vector2i.ZERO))
			_add_unique_action_cell(action_result.move.get("to", Vector2i.ZERO))
		if action_result.has("target_position"):
			_add_unique_action_cell(action_result.get("target_position", Vector2i.ZERO))


func _add_unique_action_cell(cell: Vector2i) -> void:
	if cell == Vector2i.ZERO:
		return
	if not last_action_cells.has(cell):
		last_action_cells.append(cell)


func _zone_color(column: int, row: int = -1) -> Color:
	match battle_state.board.get_zone_for_column(column, row):
		BoardModelScript.ZONE_LEFT_DEPLOYMENT:
			return StarPaletteScript.ZONE_PLAYER_BG
		BoardModelScript.ZONE_PUBLIC:
			return StarPaletteScript.ZONE_PUBLIC_BG
		BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
			return StarPaletteScript.ZONE_ENEMY_BG
	return StarPaletteScript.CELL_DEFAULT_BG


func _zone_border_color(column: int, row: int = -1) -> Color:
	match battle_state.board.get_zone_for_column(column, row):
		BoardModelScript.ZONE_LEFT_DEPLOYMENT:
			return StarPaletteScript.ZONE_PLAYER_BORDER
		BoardModelScript.ZONE_PUBLIC:
			return StarPaletteScript.ZONE_PUBLIC_BORDER
		BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
			return StarPaletteScript.ZONE_ENEMY_BORDER
	return Color(0.72, 0.72, 0.72, 1.0)


func _zone_short_label(column: int, row: int = -1) -> String:
	match battle_state.board.get_zone_for_column(column, row):
		BoardModelScript.ZONE_LEFT_DEPLOYMENT:
			return "我方部署"
		BoardModelScript.ZONE_PUBLIC:
			return "公共星域"
		BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
			return "敌方部署"
	return "星格"


func _zone_code(column: int, row: int = -1) -> String:
	match battle_state.board.get_zone_for_column(column, row):
		BoardModelScript.ZONE_LEFT_DEPLOYMENT:
			return "蓝区 L%d" % column
		BoardModelScript.ZONE_PUBLIC:
			return "中域 C%d" % column
		BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
			return "红区 R%d" % column
	return "星格 %d" % column


func _zone_star_label(column: int, row: int = -1) -> String:
	match battle_state.board.get_zone_for_column(column, row):
		BoardModelScript.ZONE_LEFT_DEPLOYMENT:
			return "蓝轨-我方部署"
		BoardModelScript.ZONE_PUBLIC:
			return "玉衡-公共星域"
		BoardModelScript.ZONE_RIGHT_DEPLOYMENT:
			return "赤轨-敌方部署"
	return "星格"


func _faction_icon(faction_id: String) -> String:
	match faction_id:
		"shu":
			return "蜀"
		"wei":
			return "魏"
		"wu":
			return "吴"
		"qun":
			return "群"
		_:
			return "阵"


func _class_icon(class_id: String) -> String:
	match class_id:
		"warrior":
			return "战"
		"mage":
			return "法"
		"tank":
			return "盾"
		"archer":
			return "弓"
		"guard":
			return "卫"
		"assassin":
			return "刺"
		_:
			return "将"


func _side_arrow(side: String) -> String:
	if side == BoardModelScript.SIDE_LEFT:
		return ">"
	if side == BoardModelScript.SIDE_RIGHT:
		return "<"
	return "-"


func _side_direction_text(side: String) -> String:
	if side == BoardModelScript.SIDE_LEFT:
		return "向右推进"
	if side == BoardModelScript.SIDE_RIGHT:
		return "向左推进"
	return "未知方向"


func _cell_key(column: int, row: int) -> String:
	return "%d,%d" % [column, row]


func _unit_display_name(unit_data: Dictionary) -> String:
	return str(unit_data.get("name", unit_data.get("hero_id", "鍗曚綅")))


func _unit_side_color(side: String) -> Color:
	if side == BoardModelScript.SIDE_LEFT:
		return StarPaletteScript.PIECE_PLAYER
	if side == BoardModelScript.SIDE_RIGHT:
		return StarPaletteScript.PIECE_ENEMY
	return StarPaletteScript.PIECE_NEUTRAL
