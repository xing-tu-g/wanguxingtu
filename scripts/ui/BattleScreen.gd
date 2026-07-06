extends Control

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const BattleStateScript: GDScript = preload("res://scripts/battle/BattleState.gd")
const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")
const TerrainSystemScript: GDScript = preload("res://scripts/battle/TerrainSystem.gd")
const TurnControllerScript: GDScript = preload("res://scripts/battle/TurnController.gd")
const BattleDeckScript: GDScript = preload("res://scripts/battle/BattleDeck.gd")
const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")
const BattleBoardViewScript: GDScript = preload("res://scripts/ui/BattleBoardView.gd")
const BattleTutorialViewScript: GDScript = preload("res://scripts/ui/BattleTutorialView.gd")
const BattleAnimatorScript: GDScript = preload("res://scripts/ui/BattleAnimator.gd")
const StarPaletteScript: GDScript = preload("res://scripts/ui/theme/ColorPalette.gd")
const BattleUIThemeScript: GDScript = preload("res://scripts/ui/theme/BattleUITheme.gd")
const BattleUIAssetsScript: GDScript = preload("res://scripts/ui/theme/BattleUIAssets.gd")
const FontScaleScript: GDScript = preload("res://scripts/ui/theme/FontScale.gd")
const WHITE_KEY_ALPHA_SHADER: Shader = preload("res://assets/shaders/white_key_alpha.gdshader")

# 鈹€鈹€ ShaderMaterial preloads (T3-3) 鈥?娑堥櫎浠ｇ爜涓?ShaderMaterial.new()
const MAT_GLOW_PLAYER: ShaderMaterial = preload("res://assets/shaders/materials/glow_pulse_player.tres")
const MAT_GLOW_ENEMY: ShaderMaterial = preload("res://assets/shaders/materials/glow_pulse_enemy.tres")
const MAT_DEPTH_FADE_BATTLE: ShaderMaterial = preload("res://assets/shaders/materials/depth_fade_battle.tres")

# 鈹€鈹€ Theme preload (T3-2)
const THEME_DEFAULT: Theme = preload("res://assets/theme/default_theme.tres")

const HOME_SCREEN := "res://scenes/ui/MainMenuScene.tscn"
const RESULT_SCREEN := "res://scenes/ui/BattleReportScene.tscn"
const STARTING_HAND_SIZE := 5
const DRAW_PER_SIDE_TURN := 1
const RECYCLE_DISCARD_ON_EMPTY := false
const DEBUG_BATTLE_UI := false
const SHOW_BATTLE_LOG_IN_BATTLE := false
const MAX_LOG_LINES := 20
const MAX_LOG_RESULT_CHARS := 44
const DEPLOY_FAILURE_TOAST_DURATION := 2.8
const DEPLOY_FAILURE_TOAST_FADE_DURATION := 0.8
const REASON_TEXT := {
	"cell_out_of_bounds": "格子超出棋盘",
	"not_deployment_zone": "只能部署在己方蓝色区域",
	"not_own_deployment_zone": "只能部署在己方蓝色近端星格",
	"cell_occupied": "目标格已有单位",
	"unknown_hero": "未知武将",
	"not_enough_star_power": "星力不足",
	"no_affordable_enemy_deploy_cell": "敌方无可部署单位或格子",
}
const STATUS_TEXT := {
	"burn": "燃烧",
	"shield": "护盾",
	"stun": "眩晕",
	"attack_buff": "增攻",
	"slow": "减速",
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
var selected_hand_index: int = -1
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
var manual_battle_test_mode: bool = false
var manual_battle_test_name: String = ""
var manual_validation_panel: PanelContainer
var manual_validation_label: RichTextLabel

@onready var grid: Control = $DuelArea/CenterBoardStack/BattleArea/BoardPanel/BoardGrid
@onready var battle_background_image: TextureRect = $Background/BattleBackgroundImage
@onready var background_readability_wash: ColorRect = $Background/BackgroundReadabilityWash
@onready var board_overlay_preview: TextureRect = $DuelArea/CenterBoardStack/BattleArea/BoardPanel/BoardOverlayPreview
@onready var status_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TopRow/TurnLabel
@onready var star_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TopRow/StarLabel
@onready var tutorial_progress_row: HBoxContainer = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow
@onready var tutorial_progress_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/TutorialTitle
@onready var tutorial_step_select_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/Step1Panel/Step1Inner/Step1Label
@onready var tutorial_step_deploy_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/Step2Panel/Step2Inner/Step2Label
@onready var tutorial_step_turn_label: Label = $TopBar/StatusPanel/StatusMargin/StatusRow/TutorialRow/Step3Panel/Step3Inner/Step3Label
@onready var turn_info_panel: PanelContainer = $TopBar/StatusPanel
@onready var player_hud_label: Label = $DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerHpContainer/PlayerHpLabel
@onready var enemy_hud_label: Label = $DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyHpContainer/EnemyHpLabel
@onready var player_master_panel: PanelContainer = $DuelArea/PlayerMasterPanel
@onready var enemy_master_panel: PanelContainer = $DuelArea/EnemyMasterPanel
@onready var player_star_label: Label = $DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerStarRow/PlayerStarLabel
@onready var enemy_star_label: Label = $DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyStarRow/EnemyStarLabel
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

# 鈹€鈹€ StyleBoxFlat 缂撳瓨姹?鈥?娑堥櫎 per-frame GC 鈹€鈹€
var _advance_style: StyleBoxFlat
var _hero_button_styles: Dictionary = {}  # hero_id -> StyleBoxTexture
var _panel_styles: Dictionary = {}  # node_name 鈫?StyleBoxFlat
var _master_panel_player_active: StyleBoxFlat
var _master_panel_player_inactive: StyleBoxFlat
var _master_panel_enemy_active: StyleBoxFlat
var _master_panel_enemy_inactive: StyleBoxFlat
var _overlay_button_style: StyleBoxFlat
var _top_button_style: StyleBoxTexture
var _top_button_hover_style: StyleBoxTexture
var _secondary_button_style: StyleBoxTexture
var _secondary_button_hover_style: StyleBoxTexture
var _hint_button_style: StyleBoxTexture
var _white_key_material: ShaderMaterial
# 鈹€鈹€ Shader 鏉愯川 鈥?棰勫姞杞?.tres 寮曠敤锛岃繍琛屾椂鐩存帴鎸囨淳 鈹€鈹€
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
	_apply_battle_ui_layout()
	_create_view_nodes()
	_initialize_card_piles()
	_build_hero_buttons()
	_initialize_battle_log_view()
	_initialize_card_zone_view()
	_initialize_battle_board_view()
	_initialize_battle_tutorial_view()
	_create_manual_validation_panel()
	_apply_visual_placeholder_theme()
	_apply_font_scale()
	_apply_depth_fade()

	battle_state.terrain_system.generate_deterministic(1)
	_build_board()
	_refresh_board()
	_initialize_battle_animator()
	_update_status("选择武将，点击蓝色近端星格部署。上阵后将自动补充下一张卡牌。")
	_update_log_visibility()
	_update_first_deploy_hint()
	_emit_battle_started()


func _apply_battle_ui_layout() -> void:
	battle_background_image.texture = BattleUIAssetsScript.background_texture()
	background_readability_wash.color = BattleUIThemeScript.BG_WASH
	player_master_panel.custom_minimum_size = Vector2(212, 0)
	enemy_master_panel.custom_minimum_size = Vector2(212, 0)
	$DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerPortrait.custom_minimum_size = Vector2(0, 198)
	$DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyPortrait.custom_minimum_size = Vector2(0, 198)
	$TopBar/BackButton/BackText.text = "返回"
	$TopBar/Title.text = "星图对弈"
	$TopBar/LogButton/LogText.text = "战报"
	$TopBar/LogButton.visible = SHOW_BATTLE_LOG_IN_BATTLE
	$TopBar/LogButton.disabled = not SHOW_BATTLE_LOG_IN_BATTLE
	status_label.custom_minimum_size = Vector2(260, 0)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	star_label.custom_minimum_size = Vector2(520, 0)
	star_label.clip_text = true
	tutorial_progress_row.visible = false
	$DuelArea/CenterBoardStack/ZoneBar.visible = false
	$DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerDeployBadge.visible = false
	$DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyDeployBadge.visible = false
	$DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerNameRow/PlayerTitleLabel.text = "青曜弈星师"
	$DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyNameRow/EnemyTitleLabel.text = "玄曜弈星师"
	var player_portrait := $DuelArea/PlayerMasterPanel/PlayerMasterLayout/PlayerPortrait
	if player_portrait is TextureRect:
		var portrait_rect := player_portrait as TextureRect
		portrait_rect.texture = BattleUIAssetsScript.master_texture(BoardModelScript.SIDE_LEFT)
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var player_portrait_label := player_portrait.get_node_or_null("PlayerPortraitLabel") as Label
	if player_portrait_label != null:
		player_portrait_label.text = ""
		player_portrait_label.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MAIN)
	var enemy_portrait := $DuelArea/EnemyMasterPanel/EnemyMasterLayout/EnemyPortrait as TextureRect
	if enemy_portrait != null:
		enemy_portrait.texture = BattleUIAssetsScript.master_texture(BoardModelScript.SIDE_RIGHT)
		enemy_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		enemy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var enemy_portrait_label := enemy_portrait.get_node_or_null("EnemyPortraitLabel") as Label if enemy_portrait != null else null
	if enemy_portrait_label != null:
		enemy_portrait_label.text = ""
	$BottomHand/CardZonePanel/CardZoneLayout/CardZoneHeader/CardZoneToggleButton/CardZoneToggleText.text = "牌区"
	_configure_hint_bar()
	_configure_action_buttons()


func _configure_hint_bar() -> void:
	first_deploy_hint_panel.custom_minimum_size = Vector2(760, 46)
	first_deploy_hint_panel.anchor_left = 0.5
	first_deploy_hint_panel.anchor_right = 0.5
	first_deploy_hint_panel.anchor_top = 1.0
	first_deploy_hint_panel.anchor_bottom = 1.0
	first_deploy_hint_panel.offset_left = -380.0
	first_deploy_hint_panel.offset_right = 380.0
	first_deploy_hint_panel.offset_top = -390.0
	first_deploy_hint_panel.offset_bottom = -344.0
	var hint_title := $FirstDeployHintPanel/HintMargin/HintLayout/HintTitle as Label
	hint_title.text = "点击手牌选择武将 → 点击蓝色近端星格部署 → 自动补牌 → 推进回合"
	hint_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_title.add_theme_font_size_override("font_size", 18)
	var hint_icons := $FirstDeployHintPanel/HintMargin/HintLayout/HintIconRow as Control
	hint_icons.visible = false
	first_deploy_hint_button.text = "知道了"
	first_deploy_hint_button.custom_minimum_size = Vector2(80, 32)
	first_deploy_hint_button.add_theme_stylebox_override("normal", _hint_button_style)
	first_deploy_hint_button.add_theme_stylebox_override("hover", _secondary_button_hover_style)
	first_deploy_hint_button.add_theme_stylebox_override("pressed", _secondary_button_style)


func _configure_action_buttons() -> void:
	advance_turn_button.custom_minimum_size = Vector2(172, 166)
	advance_turn_button.text = ""
	var reset_button := $BottomHand/Controls/ResetButton as Button
	reset_button.visible = DEBUG_BATTLE_UI or manual_battle_test_mode
	reset_button.mouse_filter = Control.MOUSE_FILTER_STOP if reset_button.visible else Control.MOUSE_FILTER_IGNORE
	reset_button.custom_minimum_size = Vector2(72, 58)
	reset_button.text = ""
	reset_button.add_theme_stylebox_override("normal", _secondary_button_style)
	reset_button.add_theme_stylebox_override("hover", _secondary_button_hover_style)
	reset_button.add_theme_stylebox_override("pressed", _secondary_button_style)
	var reset_text := reset_button.get_node_or_null("ResetText") as Label
	if reset_text != null:
		reset_text.text = "重开" if manual_battle_test_mode else "重置"
		reset_text.add_theme_font_size_override("font_size", 16)


func set_screen_data(screen_data: Dictionary) -> void:
	configured_player_deck = _validated_deck_from_data(screen_data.get("player_deck", []), _default_player_deck_ids())
	configured_enemy_deck = _validated_deck_from_data(screen_data.get("enemy_deck", []), _default_enemy_deck_ids())
	manual_battle_test_mode = bool(screen_data.get("manual_battle_test_mode", false))
	manual_battle_test_name = str(screen_data.get("manual_battle_test_name", "Manual Battle Validation"))


# 鈹€鈹€ StyleBoxFlat 缂撳瓨姹犲垵濮嬪寲 鈹€鈹€
func _build_style_caches() -> void:
	# Advance button style
	_advance_style = StyleBoxFlat.new()
	_advance_style.set_corner_radius_all(84)
	_advance_style.set_border_width_all(5)
	_advance_style.content_margin_left = 14
	_advance_style.content_margin_top = 8
	_advance_style.content_margin_right = 14
	_advance_style.content_margin_bottom = 8

	# Master panel styles 鈥?4 variants
	_master_panel_player_active = _make_cached_panel_style(BattleUIThemeScript.PLAYER_BG, BattleUIThemeScript.PLAYER_BORDER, 6)
	_master_panel_player_inactive = _make_cached_panel_style(BattleUIThemeScript.PLAYER_BG.darkened(0.08), BattleUIThemeScript.PLAYER_BORDER, 3)
	_master_panel_enemy_active = _make_cached_panel_style(BattleUIThemeScript.ENEMY_BG, BattleUIThemeScript.ENEMY_BORDER, 6)
	_master_panel_enemy_inactive = _make_cached_panel_style(BattleUIThemeScript.ENEMY_BG.darkened(0.08), BattleUIThemeScript.ENEMY_BORDER, 3)

	# Overlay dismiss button
	_overlay_button_style = StyleBoxFlat.new()
	_overlay_button_style.bg_color = StarPaletteScript.PANEL_OVERLAY_DIM
	_overlay_button_style.border_color = Color.TRANSPARENT
	_top_button_style = BattleUIAssetsScript.framed_button_style(Color(0.42, 0.55, 0.68, 0.95), 24)
	_top_button_hover_style = BattleUIAssetsScript.framed_button_style(Color(0.60, 0.75, 0.88, 1.0), 24)
	_secondary_button_style = BattleUIAssetsScript.framed_button_style(Color(0.40, 0.48, 0.56, 0.92), 24)
	_secondary_button_hover_style = BattleUIAssetsScript.framed_button_style(Color(0.54, 0.64, 0.72, 1.0), 24)
	_hint_button_style = BattleUIAssetsScript.framed_button_style(Color(0.58, 0.72, 0.78, 0.95), 24)
	_white_key_material = ShaderMaterial.new()
	_white_key_material.shader = WHITE_KEY_ALPHA_SHADER
	_white_key_material.set_shader_parameter("threshold", 0.82)
	_white_key_material.set_shader_parameter("softness", 0.10)


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


# 鈹€鈹€ View 鑺傜偣鍒涘缓 (T3-1) 鈥?CardZoneView / BattleLogView 鐜板湪 extend Node 鈹€鈹€
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
	battle_background_image.material = null


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
	battle_log_view.display_enabled = SHOW_BATTLE_LOG_IN_BATTLE
	battle_log_view.setup(log_panel, battle_log_text, toggle_log_button, log_close_button)
	battle_log_view.visibility_changed.connect(_on_battle_log_visibility_changed)
	if not SHOW_BATTLE_LOG_IN_BATTLE:
		battle_log_view.collapsed = true
		log_panel.visible = false
		battle_log_text.text = ""
		toggle_log_button.visible = false
		toggle_log_button.disabled = true
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
			"is_selected_cell": _board_is_selected_cell,
			"is_recommended_deploy_cell": _board_is_recommended_deploy_cell,
		}
	)
	cell_buttons = battle_board_view.cell_buttons


func _board_unit_at(column: int, row: int) -> Dictionary:
	return battle_state.board.get_unit_at(column, row)


func _hero_def_for_board(hero_id: String) -> Dictionary:
	return battle_state.get_hero_def(hero_id)


func _board_get_terrain(column: int, row: int) -> String:
	var terrain_id = battle_state.terrain_system.get_terrain(column, row)
	if terrain_id == null or str(terrain_id).is_empty():
		return TerrainSystemScript.TERRAIN_GRASS
	return str(terrain_id)


func _board_is_selected_cell(column: int, row: int) -> bool:
	var cell := Vector2i(column, row)
	return cell == last_touched_cell or last_action_cells.has(cell)


func _board_is_recommended_deploy_cell(column: int, row: int) -> bool:
	return _should_show_recommended_deploy_cell(column, row)


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


func _create_manual_validation_panel() -> void:
	if not manual_battle_test_mode:
		return
	manual_validation_panel = PanelContainer.new()
	manual_validation_panel.name = "ManualValidationPanel"
	manual_validation_panel.custom_minimum_size = Vector2(336, 210)
	manual_validation_panel.anchor_left = 1.0
	manual_validation_panel.anchor_right = 1.0
	manual_validation_panel.anchor_top = 0.0
	manual_validation_panel.anchor_bottom = 0.0
	manual_validation_panel.offset_left = -360.0
	manual_validation_panel.offset_right = -18.0
	manual_validation_panel.offset_top = 92.0
	manual_validation_panel.offset_bottom = 320.0
	manual_validation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.035, 0.070, 0.84)
	panel_style.border_color = BattleUIThemeScript.GOLD_SOFT
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 10
	manual_validation_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(manual_validation_panel)

	manual_validation_label = RichTextLabel.new()
	manual_validation_label.name = "ManualValidationLabel"
	manual_validation_label.bbcode_enabled = true
	manual_validation_label.fit_content = true
	manual_validation_label.scroll_active = false
	manual_validation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manual_validation_label.add_theme_font_size_override("normal_font_size", 15)
	manual_validation_panel.add_child(manual_validation_label)


func _initialize_battle_animator() -> void:
	battle_animator = BattleAnimatorScript.new()
	battle_animator.name = "BattleAnimator"
	add_child(battle_animator)
	battle_animator.setup(
		cell_buttons,
		_anim_cell_key_to_unit_id,
		_anim_unit_id_to_cell_key,
		_play_unit_pose,
		grid,
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


func _play_unit_pose(unit_id: String, pose: String) -> void:
	battle_board_view.play_unit_pose(unit_id, pose)


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
		return "鎵嬬墝"
	return _hero_name(selected_hero_id)


func _process(delta: float) -> void:
	battle_tutorial_view.process(delta)
	deploy_failure_toast_time_left = battle_tutorial_view.deploy_failure_toast_time_left


func _build_hero_buttons() -> void:
	for child in hero_button_row.get_children():
		child.queue_free()
	hero_buttons.clear()
	_hero_button_styles.clear()
	for hand_index in range(STARTING_HAND_SIZE):
		var hero_button := Button.new()
		hero_button.custom_minimum_size = Vector2(172, 190)
		hero_button.focus_mode = Control.FOCUS_NONE
		hero_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_button.text = ""
		hero_button.name = "HandSlot%d" % (hand_index + 1)
		hero_button_row.add_child(hero_button)
		_build_hand_card_children(hero_button)
		hero_buttons[hand_index] = hero_button
		var style: StyleBoxFlat = BattleUIAssetsScript.hand_card_style()
		_hero_button_styles[hand_index] = style
		hero_button.pressed.connect(_select_hand_slot.bind(hand_index))
		hero_button.gui_input.connect(_on_hand_slot_gui_input.bind(hand_index))

	for hero_id in _player_battle_hero_ids():
		if not hero_buttons.has(hero_id):
			hero_buttons[hero_id] = hero_buttons.get(0)

	var next_slot := PanelContainer.new()
	next_slot.name = "NextDrawSlot"
	next_slot.custom_minimum_size = Vector2(104, 190)
	var next_label := Label.new()
	next_label.name = "NextDrawLabel"
	next_label.text = "下一张\n自动补牌"
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_label.add_theme_font_size_override("font_size", 17)
	next_label.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MUTED)
	next_slot.add_child(next_label)
	var slot_style: StyleBoxFlat = BattleUIAssetsScript.hand_card_style(Color(0.040, 0.060, 0.105, 0.54), BattleUIThemeScript.CARD_DISABLED_BORDER)
	next_slot.add_theme_stylebox_override("panel", slot_style)
	hero_button_row.add_child(next_slot)


func _build_hand_card_children(hero_button: Button) -> void:
	var root := Control.new()
	root.name = "HandCardContainer"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_button.add_child(root)

	var name_band := PanelContainer.new()
	name_band.name = "NameBand"
	name_band.anchor_right = 1.0
	name_band.offset_top = 0.0
	name_band.offset_bottom = 34.0
	name_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_band)

	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color(0.016, 0.025, 0.050, 0.45)
	name_style.border_color = Color(1.0, 0.79, 0.36, 0.28)
	name_style.set_border_width(SIDE_BOTTOM, 1)
	name_style.set_corner_radius_all(5)
	name_style.content_margin_left = 7
	name_style.content_margin_top = 3
	name_style.content_margin_right = 7
	name_style.content_margin_bottom = 2
	name_band.add_theme_stylebox_override("panel", name_style)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.clip_text = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 23)
	name_label.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MAIN)
	name_band.add_child(name_label)

	var cost_badge := PanelContainer.new()
	cost_badge.name = "CostBadge"
	cost_badge.offset_left = -3.0
	cost_badge.offset_top = -3.0
	cost_badge.offset_right = 50.0
	cost_badge.offset_bottom = 42.0
	cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_badge.z_index = 4
	root.add_child(cost_badge)

	var cost_badge_style := StyleBoxFlat.new()
	cost_badge_style.bg_color = Color(0.030, 0.038, 0.064, 0.72)
	cost_badge_style.border_color = Color(1.0, 0.78, 0.34, 0.72)
	cost_badge_style.set_border_width_all(1)
	cost_badge_style.set_corner_radius_all(6)
	cost_badge_style.content_margin_left = 3
	cost_badge_style.content_margin_top = 2
	cost_badge_style.content_margin_right = 4
	cost_badge_style.content_margin_bottom = 2
	cost_badge.add_theme_stylebox_override("panel", cost_badge_style)

	var cost_badge_inner := HBoxContainer.new()
	cost_badge_inner.name = "CostBadgeInner"
	cost_badge_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_badge_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_badge_inner.add_theme_constant_override("separation", 2)
	cost_badge.add_child(cost_badge_inner)
	cost_badge_inner.add_child(_make_hand_icon_value("cost", false, Vector2(18, 18), 19, Vector2(18, 22)))

	var portrait_stage := Control.new()
	portrait_stage.name = "PortraitStage"
	portrait_stage.anchor_right = 1.0
	portrait_stage.anchor_bottom = 1.0
	portrait_stage.offset_top = 35.0
	portrait_stage.offset_bottom = -35.0
	portrait_stage.custom_minimum_size = Vector2(0, 112)
	portrait_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(portrait_stage)

	var portrait_glow := ColorRect.new()
	portrait_glow.name = "PortraitGlow"
	portrait_glow.anchor_left = 0.12
	portrait_glow.anchor_top = 0.06
	portrait_glow.anchor_right = 0.88
	portrait_glow.anchor_bottom = 0.98
	portrait_glow.color = Color(0.17, 0.44, 0.72, 0.16)
	portrait_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stage.add_child(portrait_glow)

	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.anchor_left = -0.04
	portrait.anchor_top = -0.12
	portrait.anchor_right = 1.04
	portrait.anchor_bottom = 1.08
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stage.add_child(portrait)

	var state_label := Label.new()
	state_label.name = "StateLabel"
	state_label.anchor_left = 0.06
	state_label.anchor_top = 0.76
	state_label.anchor_right = 0.94
	state_label.anchor_bottom = 0.98
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 13)
	state_label.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MAIN)
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stage.add_child(state_label)

	var stats_row := HBoxContainer.new()
	stats_row.name = "BottomStatBar"
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.anchor_top = 1.0
	stats_row.anchor_right = 1.0
	stats_row.anchor_bottom = 1.0
	stats_row.offset_top = -34.0
	stats_row.custom_minimum_size = Vector2(0, 34)
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_theme_constant_override("separation", 12)
	root.add_child(stats_row)
	for stat_id in ["hp", "attack"]:
		stats_row.add_child(_make_hand_icon_value(stat_id, false))

	var meta_label := Label.new()
	meta_label.name = "MetaLabel"
	meta_label.visible = false
	meta_label.clip_text = true
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MUTED)
	root.add_child(meta_label)

	var legacy_state := Label.new()
	legacy_state.name = "StateLabel"
	legacy_state.visible = false
	root.add_child(legacy_state)

	_build_hand_card_legacy_aliases(root)


func _build_hand_card_legacy_aliases(root: Control) -> void:
	var legacy_top := HBoxContainer.new()
	legacy_top.name = "TopRow"
	legacy_top.visible = false
	root.add_child(legacy_top)
	var legacy_name := Label.new()
	legacy_name.name = "NameLabel"
	legacy_top.add_child(legacy_name)
	var legacy_cost := Label.new()
	legacy_cost.name = "CostLabel"
	legacy_top.add_child(legacy_cost)
	var legacy_portrait := TextureRect.new()
	legacy_portrait.name = "Portrait"
	legacy_portrait.visible = false
	root.add_child(legacy_portrait)
	var legacy_meta := Label.new()
	legacy_meta.name = "MetaLabel"
	legacy_meta.visible = false
	root.add_child(legacy_meta)
	var legacy_stats := HBoxContainer.new()
	legacy_stats.name = "StatsRow"
	legacy_stats.visible = false
	root.add_child(legacy_stats)
	for stat_id in ["hp", "attack", "cost", "class", "faction"]:
		legacy_stats.add_child(_make_hand_icon_value(stat_id, stat_id == "class" or stat_id == "faction"))


func _make_hand_icon_value(stat_id: String, badge: bool = false, icon_size: Vector2 = Vector2.ZERO, font_size: int = 0, value_size: Vector2 = Vector2.ZERO) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.name = "%sItem" % stat_id.capitalize()
	item.custom_minimum_size = Vector2(44, 24) if not badge else Vector2(24, 24)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_constant_override("separation", 3)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = icon_size if icon_size != Vector2.ZERO else (Vector2(24, 24) if badge else Vector2(18, 18))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(icon)
	var value := Label.new()
	value.name = "Value"
	value.custom_minimum_size = value_size if value_size != Vector2.ZERO else (Vector2(21, 22) if not badge else Vector2(0, 18))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", font_size if font_size > 0 else (16 if not badge else 13))
	value.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MAIN)
	value.visible = not badge
	item.add_child(value)
	return item


func _build_board() -> void:
	battle_board_view.build()
	cell_buttons = battle_board_view.cell_buttons


func _apply_visual_placeholder_theme() -> void:
	_apply_panel_style_from_cache($TopBar, Color(0.012, 0.020, 0.052, 0.52), BattleUIThemeScript.GOLD_SOFT, 1)
	_apply_panel_style_from_cache(turn_info_panel, Color(0.018, 0.035, 0.086, 0.72), BattleUIThemeScript.GOLD_SOFT, 1)
	_apply_master_panel_style(BoardModelScript.SIDE_LEFT)
	_apply_master_panel_style(BoardModelScript.SIDE_RIGHT)
	_apply_panel_style_from_cache($DuelArea/CenterBoardStack/BattleArea/BoardPanel, Color(0.012, 0.018, 0.045, 0.06), BattleUIThemeScript.GOLD_SOFT, 1)
	_apply_panel_style_from_cache($BottomHand/CardZonePanel, Color(0.018, 0.030, 0.070, 0.82), BattleUIThemeScript.GOLD_SOFT, 1)
	_apply_hand_tray_backplate()
	_apply_battle_asset_button_styles()
	_apply_button_overlay_style()
	_apply_panel_style_from_cache($CardZoneDrawerPanel, StarPaletteScript.PANEL_DRAWER, StarPaletteScript.PANEL_DRAWER_BORDER, 3)
	_apply_panel_style_from_cache($LogPanel, StarPaletteScript.PANEL_LOG, StarPaletteScript.PANEL_LOG_BORDER, 3)
	_apply_panel_style_from_cache($DeployFailureToastPanel, StarPaletteScript.PANEL_TOAST, StarPaletteScript.PANEL_TOAST_BORDER, 4)
	_apply_panel_style_from_cache($UnitDetailPanel, StarPaletteScript.PANEL_DETAIL, StarPaletteScript.PANEL_DETAIL_BORDER, 3)
	_apply_panel_style_from_cache($FirstDeployHintPanel, StarPaletteScript.PANEL_HINT, StarPaletteScript.PANEL_HINT_BORDER, 4)
	_apply_tutorial_progress_row_style()


func _apply_battle_asset_button_styles() -> void:
	for button in [$TopBar/BackButton, $TopBar/LogButton]:
		button.add_theme_stylebox_override("normal", _top_button_style)
		button.add_theme_stylebox_override("hover", _top_button_hover_style)
		button.add_theme_stylebox_override("pressed", _top_button_style)
	card_zone_toggle_button.add_theme_stylebox_override("normal", _secondary_button_style)
	card_zone_toggle_button.add_theme_stylebox_override("hover", _secondary_button_hover_style)
	card_zone_toggle_button.add_theme_stylebox_override("pressed", _secondary_button_style)


func _apply_hand_tray_backplate() -> void:
	var hero_scroll := $BottomHand/Controls/HeroScroll as ScrollContainer
	var backplate := hero_scroll.get_node_or_null("HandTrayBackplate") as TextureRect
	if backplate == null:
		backplate = TextureRect.new()
		backplate.name = "HandTrayBackplate"
		backplate.anchor_left = 0.0
		backplate.anchor_top = 0.0
		backplate.anchor_right = 1.0
		backplate.anchor_bottom = 1.0
		backplate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backplate.stretch_mode = TextureRect.STRETCH_SCALE
		backplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero_scroll.add_child(backplate)
		hero_scroll.move_child(backplate, 0)
	backplate.texture = load(BattleUIAssetsScript.HAND_CARD_BG) as Texture2D
	backplate.material = _white_key_material
	backplate.self_modulate = Color(0.72, 0.84, 1.0, 0.95)


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
	player_master_panel.material = null
	enemy_master_panel.material = null


func _active_side_feedback_color(side: String) -> Color:
	return StarPaletteScript.active_border(side)


func _side_feedback_bg_color(side: String) -> Color:
	return StarPaletteScript.active_bg(side)


func _side_feedback_border_color(side: String) -> Color:
	return StarPaletteScript.inactive_border(side)


func _current_side_feedback_label() -> String:
	return "%s琛屽姩 - %s" % [_side_label(turn_controller.current_side), _side_direction_text(turn_controller.current_side)]


func _apply_button_overlay_style() -> void:
	overlay_dismiss_button.add_theme_stylebox_override("normal", _overlay_button_style)
	overlay_dismiss_button.add_theme_stylebox_override("hover", _overlay_button_style)
	overlay_dismiss_button.add_theme_stylebox_override("pressed", _overlay_button_style)


func _select_hero(hero_id: String) -> void:
	var hand_index := player_hand.find(hero_id)
	_select_hand_slot(hand_index)


func _select_hand_slot(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= player_hand.size():
		_update_status("该手牌槽为空。")
		return
	var hero_id := str(player_hand[hand_index])
	if not battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id):
		_update_status("%s 星力不足，当前无法部署。" % _hero_name(hero_id))
		_show_card_detail(hero_id)
		return
	if not player_hand.has(hero_id):
		_update_status("%s 已不在手牌中。" % _hero_name(hero_id))
		return
	selected_hero_id = hero_id
	selected_hand_index = hand_index
	selected_card_hero_id = hero_id
	_update_hero_buttons()
	_update_first_deploy_hint()
	_show_card_detail(hero_id)
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	_update_status("已选择 %s，请点击左侧蓝色近端星格部署。" % str(hero_def.get("name", hero_id)))


func _on_hand_slot_gui_input(event: InputEvent, hand_index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_show_hand_slot_detail(hand_index)
			accept_event()


func _show_hand_slot_detail(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= player_hand.size():
		_update_status("该手牌槽为空。")
		return
	_show_card_detail(str(player_hand[hand_index]))


func _deploy_selected_to_cell(column: int, row: int) -> void:
	last_touched_cell = Vector2i(column, row)
	_ensure_selected_hand_index()
	var unit_data: Dictionary = battle_state.board.get_unit_at(column, row)
	if not unit_data.is_empty():
		_show_unit_detail(unit_data)
		_refresh_board()
		_update_status("正在查看 %s，点击空格继续部署。" % _unit_display_name(unit_data))
		return
	_hide_unit_detail()
	var hero_id := selected_hero_id
	_apply_deployment_result(battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_LEFT, column, row), hero_id, column, row)


func _ensure_selected_hand_index() -> void:
	if selected_hand_index >= 0 and selected_hand_index < player_hand.size() and str(player_hand[selected_hand_index]) == selected_hero_id:
		return
	selected_hand_index = player_hand.find(selected_hero_id)


func _apply_deployment_result(result: Dictionary, hero_id: String = "", column: int = 0, row: int = 0) -> void:
	if result.ok:
		first_deploy_hint_dismissed = true
		deploy_failure_highlight_active = false
		_hide_deploy_failure_toast()
		_consume_selected_hand_slot(BoardModelScript.SIDE_LEFT, hero_id)
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
		_emit_unit_deployed_visual(unit_data, BoardModelScript.SIDE_LEFT, int(result.cost))
		_emit_star_power_feedback(BoardModelScript.SIDE_LEFT, -int(result.cost))
		_emit_faction_energy_feedback(BoardModelScript.SIDE_LEFT, result.get("faction_energy_results", []))
		_emit_skill_pose_results(unit_data, result.get("skill_results", []))
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
	_emit_side_turn_started_feedback(acting_side, start_result)
	_emit_star_power_feedback(acting_side, int(start_result.get("star_power_after", 0)) - int(start_result.get("star_power_before", 0)))
	_emit_faction_energy_feedback(acting_side, start_result.get("faction_energy_results", []))
	var cards_needed: int = maxi(0, STARTING_HAND_SIZE - _hand_for_side(acting_side).size())
	var drawn_cards: Array = _draw_cards(acting_side, mini(DRAW_PER_SIDE_TURN, cards_needed))
	_add_battle_log(_side_label(acting_side), "回合开始", "星力 +%d，%d -> %d" % [
		int(start_result.star_restore),
		int(start_result.star_power_before),
		int(start_result.star_power_after),
	])
	if cards_needed > 0:
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
	_emit_action_visual_events(acting_units, action_results)
	var end_result: Dictionary = turn_controller.end_side_turn()
	_emit_side_turn_ended_feedback(acting_side, end_result)
	_log_status_results(end_result.get("status_results", []))
	_refresh_board()
	var turn_summary := _format_turn_summary(acting_side, start_result, auto_deploy_result, action_results, end_result)
	_add_battle_log(_side_label(acting_side), "回合摘要", turn_summary)
	_show_battle_event_notice(_format_turn_event_notice(acting_side, start_result, action_results))
	_update_status("")
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
	for hand_index in range(enemy_hand.size()):
		var hero_id := str(enemy_hand[hand_index])
		if not battle_state.can_afford(BoardModelScript.SIDE_RIGHT, hero_id):
			continue
		for row in range(1, BoardModelScript.ROWS + 1):
			var cols_this_row: int = BoardModelScript.get_cols_for_row(row)
			for column in range(1, cols_this_row + 1):
				if not battle_state.board.can_deploy(BoardModelScript.SIDE_RIGHT, column, row):
					continue
				var deploy_result: Dictionary = battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_RIGHT, column, row)
				if deploy_result.ok:
					_consume_hand_index(BoardModelScript.SIDE_RIGHT, hand_index, hero_id)
					_emit_star_power_feedback(BoardModelScript.SIDE_RIGHT, -int(deploy_result.get("cost", 0)))
					_emit_faction_energy_feedback(BoardModelScript.SIDE_RIGHT, deploy_result.get("faction_energy_results", []))
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
		parts.append("敌方自动部署 %s 到 (%d,%d)。" % [
			str(unit_data.get("name", unit_data.get("hero_id", ""))),
			int(unit_data.get("column", 0)),
			int(unit_data.get("row", 0)),
		])
	parts.append("共 %d 个单位行动。" % action_results.size())
	parts.append(_combat_feel_timing_hint())
	parts.append("下一步：点击推进回合，执行第 %d 回合%s。" % [
		int(end_result.turn_number),
		_side_label(str(end_result.next_side)),
	])
	return " ".join(parts)


func _format_turn_event_notice(acting_side: String, start_result: Dictionary, action_results: Array) -> String:
	return "%s行动｜星力 +%d｜%d 单位行动" % [
		_side_label(acting_side),
		int(start_result.get("star_restore", 0)),
		action_results.size(),
	]

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
		_add_battle_log(_side_label(side), "洗牌", "弃牌回收后抽牌")
	return drawn_cards


func _log_drawn_cards(side: String, drawn_cards: Array) -> void:
	if drawn_cards.is_empty():
		_add_battle_log(_side_label(side), "抽牌", "牌库已空")
		return
	var names: Array[String] = []
	for hero_id_value in drawn_cards:
		names.append(_hero_name(str(hero_id_value)))
	_add_battle_log(_side_label(side), "抽牌", "抽到 %s" % "、".join(names))


func _update_status(message: String) -> void:
	if not message.is_empty():
		_show_battle_event_notice(_compact_hud_event_text(message))
	status_label.text = _format_core_hud_label()
	player_hud_label.text = _format_side_hud(BoardModelScript.SIDE_LEFT)
	enemy_hud_label.text = _format_side_hud(BoardModelScript.SIDE_RIGHT)
	player_star_label.text = "星力 %d" % battle_state.get_star_power(BoardModelScript.SIDE_LEFT)
	enemy_star_label.text = "星力 %d" % battle_state.get_star_power(BoardModelScript.SIDE_RIGHT)
	star_label.text = _format_resource_hud_label()
	_update_advance_turn_button()
	_update_tutorial_progress()
	_update_card_zone_summary()
	_update_hero_buttons()
	_refresh_master_panel_styles()
	_update_first_deploy_hint()
	_update_manual_validation_panel()


func get_manual_validation_snapshot() -> Dictionary:
	return {
		"enabled": manual_battle_test_mode,
		"name": manual_battle_test_name,
		"turn_number": turn_controller.turn_number,
		"current_side": turn_controller.current_side,
		"left_star_power": battle_state.get_star_power(BoardModelScript.SIDE_LEFT),
		"right_star_power": battle_state.get_star_power(BoardModelScript.SIDE_RIGHT),
		"left_units": _manual_unit_names(BoardModelScript.SIDE_LEFT),
		"right_units": _manual_unit_names(BoardModelScript.SIDE_RIGHT),
		"stats": battle_state.battle_stats.snapshot(),
	}


func _update_manual_validation_panel() -> void:
	if not manual_battle_test_mode or manual_validation_label == null:
		return
	var snapshot := get_manual_validation_snapshot()
	var stats: Dictionary = snapshot.get("stats", {})
	var lines: Array[String] = [
		"[b]Manual Battle Test[/b]",
		manual_battle_test_name,
		"回合: %d / %s" % [int(snapshot.get("turn_number", 0)), _side_label(str(snapshot.get("current_side", "")))],
		"星力: 我方 %d / 敌方 %d" % [int(snapshot.get("left_star_power", 0)), int(snapshot.get("right_star_power", 0))],
		"我方: %s" % _manual_join(snapshot.get("left_units", [])),
		"敌方: %s" % _manual_join(snapshot.get("right_units", [])),
		"技能触发: %s" % _manual_counter_text(stats.get("skill_triggers", {}), 5),
		"伤害: %s" % _manual_counter_text(stats.get("hero_damage_dealt", {}), 5),
		"承伤: %s" % _manual_counter_text(stats.get("hero_damage_taken", {}), 5),
		"治疗: %s" % _manual_counter_text(stats.get("hero_healing_done", {}), 3),
		"击杀: 左 %d / 右 %d" % [
			int(stats.get("units_defeated", {}).get(BoardModelScript.SIDE_LEFT, 0)),
			int(stats.get("units_defeated", {}).get(BoardModelScript.SIDE_RIGHT, 0)),
		],
		"阵营星力: %s" % _manual_counter_text(stats.get("faction_energy_heroes", {}), 5),
	]
	manual_validation_label.text = "\n".join(lines)


func _manual_unit_names(side: String) -> Array[String]:
	var names: Array[String] = []
	for unit_data: Dictionary in battle_state.get_units_by_side(side):
		if int(unit_data.get("hp", 0)) <= 0:
			continue
		names.append("%s(%d,%d)" % [
			_unit_display_name(unit_data),
			int(unit_data.get("column", 0)),
			int(unit_data.get("row", 0)),
		])
	return names


func _manual_join(values: Array) -> String:
	if values.is_empty():
		return "-"
	var text_values: Array[String] = []
	for value in values:
		text_values.append(str(value))
	return "、".join(text_values)


func _manual_counter_text(counter: Dictionary, limit: int) -> String:
	if counter.is_empty():
		return "-"
	var rows: Array = []
	for key in counter.keys():
		rows.append({"key": str(key), "value": int(counter.get(key, 0))})
	rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("value", 0)) > int(right.get("value", 0))
	)
	var parts: Array[String] = []
	for index in range(mini(limit, rows.size())):
		var row: Dictionary = rows[index]
		parts.append("%s=%d" % [str(row.get("key", "")), int(row.get("value", 0))])
	return "、".join(parts)


func _update_advance_turn_button() -> void:
	if advance_turn_button == null:
		return
	advance_turn_button.text = ""
	var advance_text_label := advance_turn_button.get_node_or_null("AdvanceText") as Label
	if advance_text_label != null:
		advance_text_label.text = "推进\n回合"
		advance_text_label.add_theme_font_size_override("font_size", 26)
	advance_turn_button.tooltip_text = "结算当前行动并推进到下一回合"
	advance_turn_button.custom_minimum_size = Vector2(172, 166)
	advance_turn_button.add_theme_font_size_override("font_size", 26)
	_advance_style.bg_color = Color(0.045, 0.135, 0.245, 0.98)
	_advance_style.border_color = BattleUIThemeScript.GOLD
	_advance_style.set_corner_radius_all(18)
	_advance_style.set_border_width_all(4)
	advance_turn_button.add_theme_stylebox_override("normal", _advance_style)
	advance_turn_button.add_theme_stylebox_override("hover", _advance_style)
	advance_turn_button.add_theme_stylebox_override("pressed", _advance_style)
	advance_turn_button.add_theme_color_override("font_color", BattleUIThemeScript.TEXT_MAIN)


func _format_side_hud(side: String) -> String:
	var deck_count := _deck_for_side(side).size()
	var hand_count := _hand_for_side(side).size()
	var hp: int = battle_state.get_master_hp(side)
	var max_hp: int = battle_state.get_master_max_hp(side)
	return "HP %d/%d\n牌库 %d  手牌 %d" % [
		hp,
		max_hp,
		deck_count,
		hand_count,
	]


func _combat_feel_timing_hint() -> String:
	return "下次星力 +%d｜星潮 %s｜%s" % [
		turn_controller.get_star_restore_amount(),
		_star_tide_hint(),
		_current_decision_hint(),
	]


func _format_core_hud_label() -> String:
	return "第 %d 回合｜%s行动" % [
		turn_controller.turn_number,
		_side_label(turn_controller.current_side),
	]


func _format_resource_hud_label() -> String:
	var side := turn_controller.current_side
	return "星力 %d(+%d)｜星潮 %s｜%s" % [
		battle_state.get_star_power(side),
		turn_controller.get_star_restore_amount(),
		_star_tide_hint(),
		_current_decision_hint(),
	]


func _compact_hud_event_text(message: String) -> String:
	var text := message.strip_edges()
	if text.length() <= 28:
		return text
	return "%s..." % text.substr(0, 28)


func _show_battle_event_notice(message: String) -> void:
	if message.is_empty() or battle_animator == null:
		return
	if battle_animator.has_method("_spawn_screen_notice"):
		battle_animator._spawn_screen_notice(message, Color(0.74, 0.90, 1.0, 1.0), 0.78)


func _star_tide_hint() -> String:
	var completed_rounds := turn_controller.get_completed_rounds()
	var restore_interval := TurnControllerScript.STAR_TIDE_RESTORE_ROUND_INTERVAL
	var next_restore_in := restore_interval - (completed_rounds % restore_interval)
	var master_bonus := turn_controller.get_star_tide_master_damage_bonus()
	if master_bonus > 0:
		return "主将伤害 +%d" % master_bonus
	return "%d 回合后升潮" % next_restore_in


func _current_decision_hint() -> String:
	if turn_controller.turn_number <= 3:
		return "前期：部署站位"
	if turn_controller.turn_number <= 10:
		return "中期：技能窗口"
	return "后期：收割推进"


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
	card_zone_summary_label.text = "牌库剩余 %d" % player_deck.size()
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
			return "0（牌库已空）"
		return "0（牌库已空，弃牌已用 %d）" % _discard_for_side(side).size()
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
	return "%s - 费 %d\n阵营：%s" % [
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
	if not SHOW_BATTLE_LOG_IN_BATTLE:
		battle_log_view.close()
		battle_log_collapsed = true
		_update_overlay_dismiss_visibility()
		return
	battle_log_view.toggle()
	battle_log_collapsed = battle_log_view.collapsed
	_update_log_visibility()


func _close_battle_log() -> void:
	battle_log_view.close()
	battle_log_collapsed = battle_log_view.collapsed
	_update_log_visibility()


func _update_log_visibility() -> void:
	if not SHOW_BATTLE_LOG_IN_BATTLE:
		battle_log_view.collapsed = true
		battle_log_collapsed = true
		log_panel.visible = false
		toggle_log_button.visible = false
		toggle_log_button.disabled = true
		_update_overlay_dismiss_visibility()
		return
	battle_log_view.update_visibility()
	battle_log_collapsed = battle_log_view.collapsed
	_update_overlay_dismiss_visibility()


func _update_overlay_dismiss_visibility() -> void:
	overlay_dismiss_button.visible = not card_zone_collapsed

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
		_emit_unit_deployed_visual(unit_data, BoardModelScript.SIDE_RIGHT, int(auto_deploy_result.get("cost", 0)))
		_emit_skill_pose_results(unit_data, auto_deploy_result.get("skill_results", []))
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
		if index < acting_units.size():
			_emit_skill_pose_results(acting_units[index], action_result.get("skill_results", []))


func _emit_unit_deployed_visual(unit_data: Dictionary, side: String, cost: int) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("unit_deployed"):
		bus.unit_deployed.emit(unit_data, side, cost)


func _emit_side_turn_started_feedback(side: String, start_result: Dictionary) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("side_turn_started"):
		bus.side_turn_started.emit(side, start_result)


func _emit_side_turn_ended_feedback(side: String, end_result: Dictionary) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.has_signal("side_turn_ended"):
		bus.side_turn_ended.emit(side, end_result)
	if bool(end_result.get("completed_round", false)) and bus.has_signal("turn_completed"):
		bus.turn_completed.emit(int(end_result.get("turn_number", turn_controller.turn_number)))


func _emit_star_power_feedback(side: String, amount: int) -> void:
	if amount == 0:
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("star_power_changed"):
		bus.star_power_changed.emit(side, amount)


func _emit_faction_energy_feedback(side: String, faction_energy_results: Array) -> void:
	for result: Dictionary in faction_energy_results:
		var amount := int(result.get("amount", 0))
		if amount > 0:
			_emit_star_power_feedback(side, amount)
			_add_battle_log(_side_label(side), "阵营星力", "%s +%d" % [
				_hero_name(str(result.get("hero_id", ""))),
				amount,
			])


func _emit_action_visual_events(acting_units: Array, action_results: Array) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return
	for index in range(action_results.size()):
		if index >= acting_units.size():
			continue
		var actor: Dictionary = acting_units[index]
		var action_result: Dictionary = action_results[index]
		if action_result.has("move") and bus.has_signal("unit_moved"):
			var move_result: Dictionary = action_result.get("move", {})
			var to_cell: Vector2i = move_result.get("to", Vector2i(int(actor.get("column", 0)), int(actor.get("row", 0))))
			bus.unit_moved.emit(actor, to_cell.x, to_cell.y)
		if str(action_result.get("action", "")) == "attack" and bus.has_signal("unit_attacked"):
			var target := _target_unit_from_action(action_result)
			bus.unit_attacked.emit(actor, target, int(action_result.get("damage", 0)))
			if str(action_result.get("target_type", "")) == "master":
				var target_side := battle_state.get_enemy_side(str(actor.get("side", "")))
				if bus.has_signal("master_damaged"):
					bus.master_damaged.emit(target_side, int(action_result.get("damage", 0)), battle_state.get_master_hp(target_side))
			elif str(action_result.get("target_type", "")) == "unit":
				if bus.has_signal("unit_damaged"):
					bus.unit_damaged.emit(target, int(action_result.get("damage", 0)))
				if int(target.get("hp", 0)) <= int(action_result.get("damage", 0)) and bus.has_signal("unit_died"):
					bus.unit_died.emit(target)


func _target_unit_from_action(action_result: Dictionary) -> Dictionary:
	var target_snapshot = action_result.get("target_snapshot", {})
	if target_snapshot is Dictionary and not target_snapshot.is_empty():
		return target_snapshot
	var target_id := str(action_result.get("target_id", ""))
	if target_id.is_empty():
		return {}
	return battle_state.get_unit_by_id(target_id)


func _log_skill_results(actor: String, skill_results: Array) -> void:
	for skill_result: Dictionary in skill_results:
		_add_battle_log(actor, "技能", _skill_result_summary(skill_result))


func _emit_skill_pose_results(source_unit: Dictionary, skill_results: Array) -> void:
	if source_unit.is_empty() or skill_results.is_empty():
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus == null or not bus.has_signal("unit_skill_triggered"):
		return
	for skill_result: Dictionary in skill_results:
		if bool(skill_result.get("ok", false)):
			bus.unit_skill_triggered.emit(source_unit, skill_result)
			_emit_faction_energy_feedback(str(source_unit.get("side", "")), skill_result.get("faction_energy_results", []))


func _log_status_results(status_results: Array) -> void:
	for status_result: Dictionary in status_results:
		_add_battle_log(str(status_result.get("target_id", "单位")), "状态", "%s 造成 %d 点伤害" % [
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
		"stunned":
			return "眩晕"
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
	elif str(action_result.get("action", "")) == "stunned":
		parts.append("被眩晕，跳过行动")
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
	if str(skill_result.get("effect_type", "")) == "damage":
		return "%s 对 %s 造成 %d 点伤害" % [
			_skill_text(skill_id),
			str(skill_result.get("target_id", "")),
			int(skill_result.get("damage", 0)),
		]
	if str(skill_result.get("effect_type", "")) == "area_damage":
		return "%s 造成范围伤害，命中 %d 个目标" % [
			_skill_text(skill_id),
			(skill_result.get("damaged", []) as Array).size(),
		]
	if str(skill_result.get("effect_type", "")) == "heal":
		return "%s 治疗 %d 个友军" % [
			_skill_text(skill_id),
			(skill_result.get("healed", []) as Array).size(),
		]
	if str(skill_result.get("effect_type", "")) in ["shield", "stun", "attack_buff", "slow"]:
		return "%s 对 %s 施加 %s" % [
			_skill_text(skill_id),
			str(skill_result.get("target_id", "")),
			_status_text(str(skill_result.get("status_id", ""))),
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
			return "当前点到 (%d,%d)，这里不是我方蓝色近端部署格。请把 %s 放到左侧蓝色近端空格。" % [column, row, hero_name]
		"not_enough_star_power":
			var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
			var cost: int = int(hero_def.get("cost", 0))
			var star_power: int = battle_state.get_star_power(BoardModelScript.SIDE_LEFT)
			return "星力不足，%s 需要 %d 星力，当前只有 %d。" % [hero_name, cost, star_power]
		"cell_occupied":
			return "目标格 (%d,%d) 已有单位，请点击蓝色近端部署区内的其他空格。" % [column, row]
		"unknown_hero":
			return "未选择可部署手牌。请先点击底部手牌，再点蓝色近端部署格。"
		"cell_out_of_bounds":
			return "格子 (%d,%d) 超出棋盘。请点击棋盘内蓝色近端部署格。" % [column, row]
		_:
			return "%s。请先选底部手牌，再点左侧蓝色近端部署格。" % _reason_text(reason)


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
		var hint_text: String = "\n可上阵" if _should_show_recommended_deploy_cell(column, row) else ""
		return "%s\n%d,%d%s%s" % [_zone_code(column, row), column, row, terrain_text, hint_text]
	var hero_def: Dictionary = battle_state.get_hero_def(str(unit_data.get("hero_id", "")))
	var faction_id := str(unit_data.get("faction", hero_def.get("faction", "")))
	var side := str(unit_data.get("side", ""))
	var action_hint := "\n%s" % _side_direction_text(side) if side == turn_controller.current_side else ""
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
	_update_status("战斗已重置。")


func _update_hero_buttons() -> void:
	_refresh_hero_button_aliases()
	for hand_index in range(STARTING_HAND_SIZE):
		var hero_button: Button = hero_buttons.get(hand_index) as Button
		if hero_button == null:
			continue
		var in_hand: bool = hand_index < player_hand.size()
		var hero_id := str(player_hand[hand_index]) if in_hand else ""
		var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
		var in_deck: bool = not player_deck.is_empty()
		var selected: bool = hand_index == selected_hand_index and hero_id == selected_hero_id and in_hand
		var affordable: bool = in_hand and battle_state.can_afford(BoardModelScript.SIDE_LEFT, hero_id)
		var selection_text := _hand_piece_state_text(selected, in_hand, in_deck, affordable)
		hero_button.visible = true
		hero_button.disabled = not in_hand or not affordable
		hero_button.text = ""
		_update_hand_card_content(hero_button, hero_def, selection_text, in_hand, in_deck, affordable)
		_apply_hand_piece_button_style(hero_button, hand_index, hero_id, selected, in_hand, affordable)
	_update_next_draw_slot()


func _refresh_hero_button_aliases() -> void:
	for hero_id in _player_battle_hero_ids():
		if not hero_buttons.has(hero_id):
			hero_buttons[hero_id] = hero_buttons.get(0)
	for hand_index in range(mini(STARTING_HAND_SIZE, player_hand.size())):
		var hero_id := str(player_hand[hand_index])
		hero_buttons[hero_id] = hero_buttons.get(hand_index)


func _update_next_draw_slot() -> void:
	var next_slot := hero_button_row.get_node_or_null("NextDrawSlot") as PanelContainer
	if next_slot == null:
		return
	var next_label := next_slot.get_node_or_null("NextDrawLabel") as Label
	var visible_hand_count: int = player_hand.size()
	next_slot.visible = visible_hand_count < STARTING_HAND_SIZE or not player_deck.is_empty()
	if next_label == null:
		return
	if player_deck.is_empty():
		next_label.text = "牌库已空\n空槽"
	else:
		next_label.text = "下一张\n自动补牌"


func _update_hand_card_content(hero_button: Button, hero_def: Dictionary, state_text: String, in_hand: bool, in_deck: bool, affordable: bool) -> void:
	var container := hero_button.get_node_or_null("HandCardContainer") as Control
	if container == null:
		return
	var name_label := container.get_node_or_null("NameBand/NameLabel") as Label
	var legacy_name_label := container.get_node_or_null("TopRow/NameLabel") as Label
	var cost_label := container.get_node_or_null("TopRow/CostLabel") as Label
	var portrait := container.get_node_or_null("PortraitStage/Portrait") as TextureRect
	var portrait_glow := container.get_node_or_null("PortraitStage/PortraitGlow") as ColorRect
	var legacy_portrait := container.get_node_or_null("Portrait") as TextureRect
	var meta_label := container.get_node_or_null("MetaLabel") as Label
	var state_label := container.get_node_or_null("PortraitStage/StateLabel") as Label
	var legacy_state_label := container.get_node_or_null("StateLabel") as Label
	var cost_badge := container.get_node_or_null("CostBadge/CostBadgeInner") as HBoxContainer
	var stats_row := container.get_node_or_null("BottomStatBar") as HBoxContainer
	var badge_row := container.get_node_or_null("HeroCardBody/InfoColumn/BadgeRow") as HBoxContainer
	var legacy_stats_row := container.get_node_or_null("StatsRow") as HBoxContainer
	if name_label != null:
		name_label.text = str(hero_def.get("name", "空槽")) if in_hand else "空槽"
	if legacy_name_label != null:
		legacy_name_label.text = str(hero_def.get("name", "空槽")) if in_hand else "空槽"
	if cost_label != null:
		cost_label.text = "%d" % int(hero_def.get("cost", 0)) if in_hand else "-"
	if portrait != null:
		var portrait_path := str(hero_def.get("portrait", ""))
		portrait.texture = BattleUIAssetsScript.texture(portrait_path) if not portrait_path.is_empty() else null
		portrait.self_modulate = Color(1.08, 1.08, 1.05, 1.0) if affordable else Color(0.45, 0.46, 0.50, 0.62)
		if legacy_portrait != null:
			legacy_portrait.texture = portrait.texture
	if portrait_glow != null:
		portrait_glow.color = _hand_card_rarity_glow(hero_def).darkened(0.20)
		portrait_glow.color.a = 0.18 if affordable and in_hand else 0.07
	if meta_label != null:
		meta_label.text = "%s / %s" % [_faction_text(str(hero_def.get("faction", ""))), _class_text(_hero_class_id(hero_def))] if in_hand else "等待补牌"
		meta_label.visible = false
	if badge_row != null:
		_update_hand_badge_row(badge_row, hero_def, in_hand)
	if cost_badge != null:
		_set_hand_icon_value(cost_badge, "CostItem", BattleUIAssetsScript.attribute_icon("cost"), "%d" % int(hero_def.get("cost", 0)) if in_hand else "-")
	if stats_row != null:
		_update_hand_stats_row(stats_row, hero_def, in_hand)
	if legacy_stats_row != null:
		_update_hand_stats_row(legacy_stats_row, hero_def, in_hand)
		_update_hand_badge_row(legacy_stats_row, hero_def, in_hand)
	if state_label != null:
		state_label.text = state_text if in_hand else ("牌库候补" if in_deck else "空槽")
		var state_color := BattleUIThemeScript.GOLD if state_text == "已选择" else (Color(0.72, 0.96, 1.0, 1.0) if affordable and in_hand else BattleUIThemeScript.TEXT_MUTED)
		state_label.add_theme_color_override("font_color", state_color)
		state_label.visible = state_text == "已选择" or not affordable or not in_hand
	if legacy_state_label != null:
		legacy_state_label.text = state_text if in_hand else ("牌库候补" if in_deck else "空槽")


func _hand_piece_state_text(selected: bool, in_hand: bool, in_deck: bool, affordable: bool) -> String:
	if selected:
		return "已选择"
	if not in_hand:
		return "牌库候补" if in_deck else "空槽"
	return "可部署" if affordable else "星力不足"


func _hand_piece_suffix(in_hand: bool, in_deck: bool, affordable: bool) -> String:
	if not in_hand:
		return "牌库候补" if in_deck else "空槽"
	return "点蓝区部署" if affordable else "先推进回合"


func _update_hand_stats_row(stats_row: HBoxContainer, hero_def: Dictionary, in_hand: bool) -> void:
	_set_hand_icon_value(stats_row, "HpItem", BattleUIAssetsScript.attribute_icon("hp"), "%d" % int(hero_def.get("max_hp", 0)) if in_hand else "-")
	_set_hand_icon_value(stats_row, "AttackItem", BattleUIAssetsScript.attribute_icon("attack"), "%d" % int(hero_def.get("attack", 0)) if in_hand else "-")
	_set_hand_icon_value(stats_row, "CostItem", BattleUIAssetsScript.attribute_icon("cost"), "%d" % int(hero_def.get("cost", 0)) if in_hand else "-")


func _update_hand_badge_row(badge_row: HBoxContainer, hero_def: Dictionary, in_hand: bool) -> void:
	_set_hand_icon_value(badge_row, "FactionItem", BattleUIAssetsScript.faction_icon(str(hero_def.get("faction", ""))) if in_hand else null, "")
	_set_hand_icon_value(badge_row, "ClassItem", BattleUIAssetsScript.class_icon(_hero_class_id(hero_def)) if in_hand else null, "")


func _set_hand_icon_value(stats_row: HBoxContainer, item_name: String, texture: Texture2D, value_text: String) -> void:
	var item := stats_row.get_node_or_null(item_name) as HBoxContainer
	if item == null:
		return
	var icon := item.get_node_or_null("Icon") as TextureRect
	var value := item.get_node_or_null("Value") as Label
	if icon != null:
		icon.texture = texture
	if value != null:
		value.text = value_text


func _apply_hand_piece_button_style(hero_button: Button, hand_index: int, hero_id: String, selected: bool, enabled: bool, affordable: bool) -> void:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	var rarity_tint: Color = _hand_card_rarity_tint(hero_def)
	var rarity_glow: Color = _hand_card_rarity_glow(hero_def)
	var style: StyleBoxFlat = _hero_button_styles.get(hand_index)
	if style == null:
		style = BattleUIAssetsScript.hand_card_style()
		_hero_button_styles[hand_index] = style
	if selected:
		style.bg_color = Color(0.060, 0.105, 0.185, 0.90).lerp(rarity_tint, 0.34)
		style.border_color = BattleUIThemeScript.CARD_SELECTED_BORDER.lerp(rarity_glow, 0.35)
		style.shadow_color = rarity_glow.darkened(0.25)
		style.shadow_size = 9
	elif enabled and affordable:
		style.bg_color = Color(0.065, 0.112, 0.190, 0.86).lerp(rarity_tint, 0.38)
		style.border_color = BattleUIThemeScript.GOLD_SOFT.lerp(rarity_glow, 0.32)
		style.shadow_color = Color(0.17, 0.52, 0.74, 0.24)
		style.shadow_size = 6
	elif enabled and not affordable:
		style.bg_color = Color(0.026, 0.034, 0.056, 0.50).lerp(rarity_tint.darkened(0.42), 0.14)
		style.border_color = BattleUIThemeScript.CARD_DISABLED_BORDER
		style.shadow_color = Color(0, 0, 0, 0.12)
		style.shadow_size = 2
	else:
		style.bg_color = Color(0.024, 0.030, 0.048, 0.46)
		style.border_color = BattleUIThemeScript.CARD_DISABLED_BORDER.darkened(0.20)
		style.shadow_color = Color(0, 0, 0, 0.10)
		style.shadow_size = 1
	hero_button.custom_minimum_size = Vector2(181, 200) if selected else Vector2(172, 190)
	hero_button.add_theme_stylebox_override("normal", style)
	hero_button.add_theme_stylebox_override("hover", style)
	hero_button.add_theme_stylebox_override("pressed", style)
	hero_button.add_theme_stylebox_override("disabled", style)
	hero_button.self_modulate = Color(1, 1, 1, 1) if enabled and affordable else Color(0.50, 0.52, 0.56, 0.68)
	hero_button.add_theme_color_override("font_color", StarPaletteScript.TEXT_CREAM if selected else (StarPaletteScript.TEXT_GREEN_READY if enabled and affordable else StarPaletteScript.TEXT_CREAM))
	hero_button.add_theme_color_override("font_disabled_color", StarPaletteScript.TEXT_SECONDARY)
	hero_button.add_theme_font_size_override("font_size", 26 if selected else 24)


func _hand_card_rarity_id(hero_def: Dictionary) -> String:
	var rarity := str(hero_def.get("rarity", "rare")).to_lower()
	if rarity == "legendary" or rarity == "legend":
		return "legend"
	if rarity == "epic":
		return "epic"
	return "rare"


func _hand_card_rarity_tint(hero_def: Dictionary) -> Color:
	var rarity := _hand_card_rarity_id(hero_def)
	if rarity == "legend":
		return BattleUIThemeScript.CARD_LEGEND_TINT
	if rarity == "epic":
		return BattleUIThemeScript.CARD_EPIC_TINT
	return BattleUIThemeScript.CARD_RARE_TINT


func _hand_card_rarity_glow(hero_def: Dictionary) -> Color:
	var rarity := _hand_card_rarity_id(hero_def)
	if rarity == "legend":
		return BattleUIThemeScript.CARD_LEGEND_GLOW
	if rarity == "epic":
		return BattleUIThemeScript.CARD_EPIC_GLOW
	return BattleUIThemeScript.CARD_RARE_GLOW


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
	_draw_cards(side, maxi(0, STARTING_HAND_SIZE - _hand_for_side(side).size()))


func _consume_selected_hand_slot(side: String, fallback_hero_id: String) -> void:
	var hand_index := selected_hand_index
	if side != BoardModelScript.SIDE_LEFT or hand_index < 0 or hand_index >= _hand_for_side(side).size() or str(_hand_for_side(side)[hand_index]) != fallback_hero_id:
		hand_index = _hand_for_side(side).find(fallback_hero_id)
	_consume_hand_index(side, hand_index, fallback_hero_id)


func _consume_hand_index(side: String, hand_index: int, fallback_hero_id: String = "") -> void:
	var consumed := battle_deck.consume_hand_index(side, hand_index)
	if consumed.is_empty() and not fallback_hero_id.is_empty():
		battle_deck.consume_from_hand(side, fallback_hero_id)
	_sync_card_pile_references()
	_draw_cards(side, maxi(0, STARTING_HAND_SIZE - _hand_for_side(side).size()))
	if side == BoardModelScript.SIDE_LEFT:
		selected_hand_index = -1


func _discard_for_side(side: String) -> Array:
	return battle_deck.discard_for_side(side)

func _select_next_available_hero() -> void:
	if selected_hand_index >= 0 and selected_hand_index < player_hand.size() and str(player_hand[selected_hand_index]) == selected_hero_id:
		return
	if player_hand.is_empty():
		selected_hero_id = ""
		selected_hand_index = -1
		return
	selected_hand_index = 0
	selected_hero_id = str(player_hand[0])

func _hero_name(hero_id: String) -> String:
	var hero_def: Dictionary = battle_state.get_hero_def(hero_id)
	return str(hero_def.get("name", hero_id))


func _hero_class_id(hero_def: Dictionary) -> String:
	return str(hero_def.get("profession", hero_def.get("class", "")))


func _rarity_text(rarity_id: String) -> String:
	match rarity_id:
		"rare":
			return "稀有"
		"epic":
			return "史诗"
		"legendary", "legend":
			return "传说"
		"summon":
			return "召唤"
		_:
			return rarity_id if not rarity_id.is_empty() else "未知"


func _hero_background_text(hero_def: Dictionary) -> String:
	var background := str(hero_def.get("background", ""))
	if background.is_empty():
		background = str(hero_def.get("bio", ""))
	if background.is_empty():
		background = str(hero_def.get("description", ""))
	if background.is_empty():
		background = "背景介绍暂未配置。"
	return background


func _player_battle_hero_ids() -> Array:
	if configured_player_deck.is_empty():
		return _default_player_deck_ids()
	return configured_player_deck.duplicate()


func _enemy_battle_hero_ids() -> Array:
	if configured_enemy_deck.is_empty():
		return _default_enemy_deck_ids()
	return configured_enemy_deck.duplicate()


func _default_player_deck_ids() -> Array:
	return HeroDataLoaderScript.all_hero_ids(false)


func _default_enemy_deck_ids() -> Array:
	var ids: Array = HeroDataLoaderScript.all_hero_ids(false)
	ids.reverse()
	return ids


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
		var result_payload := battle_result.duplicate(true)
		result_payload["battle_log"] = battle_log_entries.duplicate()
		event_bus.screen_changed.emit(RESULT_SCREEN, result_payload)


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
	unit_detail_title.text = "卡牌 - %s - 费用 %d - 阵营 %s" % [
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
		"[b]%s[/b]" % str(hero_def.get("name", hero_id)),
		"[b]阵营[/b]：%s｜[b]职业[/b]：%s｜[b]稀有度[/b]：%s" % [
			_faction_text(str(hero_def.get("faction", ""))),
			_class_text(_hero_class_id(hero_def)),
			_rarity_text(str(hero_def.get("rarity", ""))),
		],
		"[b]费用[/b]：%d｜[b]生命[/b]：%d｜[b]攻击[/b]：%d" % [
			int(hero_def.get("cost", 0)),
			int(hero_def.get("max_hp", hero_def.get("hp", 0))),
			int(hero_def.get("attack", 0)),
		],
		"[b]移动[/b]：%d｜[b]射程[/b]：%d｜[b]格挡[/b]：物理 %d / 法术 %d" % [
			int(hero_def.get("move", 0)),
			int(hero_def.get("range", 0)),
			int(hero_def.get("physical_block", 0)),
			int(hero_def.get("magic_block", 0)),
		],
		"[b]技能[/b]：%s" % _format_hero_skill_descriptions(hero_def),
		"[b]背景[/b]：%s" % _hero_background_text(hero_def),
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
	return str(unit_data.get("name", unit_data.get("hero_id", "单位")))


func _unit_side_color(side: String) -> Color:
	if side == BoardModelScript.SIDE_LEFT:
		return StarPaletteScript.PIECE_PLAYER
	if side == BoardModelScript.SIDE_RIGHT:
		return StarPaletteScript.PIECE_ENEMY
	return StarPaletteScript.PIECE_NEUTRAL
