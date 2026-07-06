extends Control

const BATTLE_SCREEN := "res://scenes/ui/BattleScreen.tscn"
const DECK_SCREEN := "res://scenes/ui/DeckBuilderScene.tscn"
const CODEX_SCREEN := "res://scenes/ui/HeroCodexScene.tscn"
const REPORT_SCREEN := "res://scenes/ui/BattleReportScene.tscn"

const FontScaleScript: GDScript = preload("res://scripts/ui/theme/FontScale.gd")
const DeckDataManagerScript: GDScript = preload("res://scripts/data/DeckDataManager.gd")
const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")
const HomeUIAssetsScript: GDScript = preload("res://scripts/ui/theme/HomeUIAssets.gd")
const MAT_DEPTH_FADE_HOME: ShaderMaterial = preload("res://assets/shaders/materials/depth_fade_home.tres")
const THEME_DEFAULT: Theme = preload("res://assets/theme/default_theme.tres")

const HUD_TEXT := Color(0.82, 0.88, 0.98, 0.82)
const HUD_GOLD := Color(1.0, 0.82, 0.42, 0.9)
const PANEL_FAINT := Color(0.02, 0.035, 0.085, 0.48)
const PANEL_BORDER_FAINT := Color(0.86, 0.68, 0.34, 0.32)
const TOOL_BUTTON := Color(0.04, 0.075, 0.15, 0.54)
const TOOL_BUTTON_HOVER := Color(0.06, 0.12, 0.22, 0.72)
const TOOL_BORDER := Color(0.82, 0.68, 0.38, 0.35)
const MATCH_BUTTON := Color(0.08, 0.34, 0.54, 0.94)
const MATCH_BUTTON_HOVER := Color(0.12, 0.50, 0.72, 1.0)
const MATCH_BORDER := Color(1.0, 0.82, 0.42, 0.82)

@onready var _background_image: TextureRect = $BackgroundLayer/Background
@onready var _app_state: Node = get_node_or_null("/root/AppState")

@onready var _topbar_bg: TextureRect = $TopBarBg
@onready var _coin_icon: TextureRect = $TopBar/CoinIcon
@onready var _coin_label: Label = $TopBar/CoinLabel
@onready var _star_coin_icon: TextureRect = $TopBar/StarCoinIcon
@onready var _star_coin_label: Label = $TopBar/StarCoinLabel
@onready var _star_track_icon: TextureRect = $TopBar/StarTrackIcon
@onready var _star_track_label: Label = $TopBar/StarTrackLabel
@onready var _player_panel_bg: TextureRect = $LeftPanel/PlayerProfilePanel/PlayerPanelBg
@onready var _avatar_frame_art: TextureRect = $LeftPanel/PlayerProfilePanel/AvatarFrameArt
@onready var _player_name_label: Label = $LeftPanel/PlayerProfilePanel/PlayerNameLabel
@onready var _level_label: Label = $LeftPanel/PlayerProfilePanel/LevelLabel
@onready var _exp_bar: ProgressBar = $LeftPanel/PlayerProfilePanel/ExpBar
@onready var _center_world: Control = $CenterWorld
@onready var _outer_starfield: Control = $CenterWorld/OuterStarFieldLayer
@onready var _orbit_system: Control = $CenterWorld/OrbitStarSystemLayer
@onready var _orbit_layer_art: TextureRect = $CenterWorld/OrbitStarSystemLayer/OrbitLayerArt
@onready var _energy_flow: Control = $CenterWorld/OrbitStarSystemLayer/EnergyFlowLines
@onready var _core_node: Control = $CenterWorld/CoreStarNode
@onready var _core_glow_art: TextureRect = $CenterWorld/CoreStarNode/CoreGlowArt
@onready var _core_node_art: TextureRect = $CenterWorld/CoreStarNode/CoreNodeArt
@onready var _core_energy: Control = $CenterWorld/CoreStarNode/PulsingEnergyCore
@onready var _match_button: TextureButton = $CenterWorld/CoreStarNode/MatchCoreButton
@onready var _match_text_label: Label = $CenterWorld/CoreStarNode/MatchCoreButton/MatchTextLabel
@onready var _warp_overlay: ColorRect = $CenterWorld/WarpOverlay
@onready var _star_map_hint_label: Label = $CenterWorld/StarMapHintLabel
@onready var _star_track_level_label: Label = $StarTrackPanel/StarTrackMargin/StarTrackLayout/StarTrackHeader/StarTrackLevel
@onready var _star_track_delta_label: Label = $StarTrackPanel/StarTrackMargin/StarTrackLayout/StarTrackHeader/StarTrackToNext
@onready var _star_track_progress: ProgressBar = $StarTrackPanel/StarTrackMargin/StarTrackLayout/StarTrackProgress
@onready var _star_map_popup: PopupPanel = $StarMapPopup
@onready var _placeholder_popup: PopupPanel = $PlaceholderPopup
@onready var _placeholder_title: Label = $PlaceholderPopup/PopupMargin/PopupLayout/PopupTitle
@onready var _placeholder_body: Label = $PlaceholderPopup/PopupMargin/PopupLayout/PopupBody

var _pulse_tween: Tween
var _hovered_star_core := false
var _transitioning := false


func _ready() -> void:
	theme = THEME_DEFAULT
	_apply_common_styles()
	_apply_home_art_assets()
	_apply_depth_fade()
	_apply_polish_text()
	_connect_navigation()
	_connect_home_polish_navigation_overrides()
	_refresh_runtime_data()
	_apply_font_scale()
	_start_star_core_pulse()


func _process(delta: float) -> void:
	_orbit_system.rotation += delta * 0.018 * _layer_boost(_orbit_system)
	_energy_flow.rotation -= delta * 0.026 * _layer_boost(_energy_flow)


func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _is_inside_match_core(touch.position):
			get_viewport().set_input_as_handled()
			_open_battle()
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT and _is_inside_match_core(click.position):
			get_viewport().set_input_as_handled()
			_open_battle()


func _apply_depth_fade() -> void:
	if _background_image != null:
		_background_image.material = MAT_DEPTH_FADE_HOME


func _apply_home_art_assets() -> void:
	_background_image.texture = HomeUIAssetsScript.direct("star_map_background")
	_topbar_bg.texture = HomeUIAssetsScript.direct("topbar_panel")
	_coin_icon.texture = HomeUIAssetsScript.direct("coin")
	_star_coin_icon.texture = HomeUIAssetsScript.direct("star_coin")
	_star_track_icon.texture = HomeUIAssetsScript.direct("star_track")
	_player_panel_bg.texture = HomeUIAssetsScript.direct("player_panel")
	_avatar_frame_art.texture = HomeUIAssetsScript.direct("player_avatar_frame")
	_orbit_layer_art.texture = HomeUIAssetsScript.direct("star_map_orbit")
	_core_glow_art.texture = HomeUIAssetsScript.direct("star_map_glow")
	_core_node_art.texture = HomeUIAssetsScript.direct("star_map_node")
	_style_progress_with_home_art(_exp_bar)

	_setup_texture_button(_match_button, "star_core")
	_setup_texture_button($TopBar/UtilityButtons/FriendsButton, "friends")
	_setup_texture_button($TopBar/UtilityButtons/MailButton, "mail")
	_setup_texture_button($TopBar/UtilityButtons/SettingsButton, "settings", true)
	_setup_texture_button($RightPanel/Btn_Quest, "quest")
	_setup_texture_button($RightPanel/Btn_Activity, "activity", true)
	_setup_texture_button($RightPanel/Btn_Deck, "deck")
	_setup_texture_button($RightPanel/Btn_Codex, "codex")
	_setup_texture_button($RightPanel/Btn_Summon, "summon")
	_setup_texture_button($RightPanel/Btn_Report, "report", true)


func _apply_polish_text() -> void:
	_match_text_label.text = "开始\n对弈"
	_match_text_label.add_theme_color_override(&"font_color", Color(0.96, 0.98, 1.0, 1.0))
	_match_text_label.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.01, 0.04, 0.95))
	_match_text_label.add_theme_constant_override(&"shadow_offset_x", 0)
	_match_text_label.add_theme_constant_override(&"shadow_offset_y", 3)
	var labels := {
		"RightPanel/Btn_Quest/EntryLabel": "武将",
		"RightPanel/Btn_Activity/EntryLabel": "阵容",
		"RightPanel/Btn_Deck/EntryLabel": "任务",
		"RightPanel/Btn_Codex/EntryLabel": "活动",
		"RightPanel/Btn_Summon/EntryLabel": "图鉴",
		"RightPanel/Btn_Report/EntryLabel": "设置",
	}
	for path in labels:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.text = labels[path]
			label.add_theme_color_override(&"font_color", Color(0.98, 0.88, 0.62, 1.0))
			label.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
			label.add_theme_constant_override(&"shadow_offset_y", 2)
	$VersionLabel.visible = false


func _setup_texture_button(button: TextureButton, group: String, simulate_state_feedback := false) -> void:
	if button == null:
		return
	button.texture_normal = HomeUIAssetsScript.button_state(group, "default")
	button.texture_hover = HomeUIAssetsScript.button_state(group, "hover")
	button.texture_pressed = HomeUIAssetsScript.button_state(group, "pressed")
	button.texture_focused = button.texture_hover
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.pivot_offset = button.custom_minimum_size * 0.5
	if simulate_state_feedback:
		_connect_simulated_button_feedback(button)


func _connect_simulated_button_feedback(button: TextureButton) -> void:
	if not button.mouse_entered.is_connected(_on_simulated_button_hovered.bind(button)):
		button.mouse_entered.connect(_on_simulated_button_hovered.bind(button))
	if not button.mouse_exited.is_connected(_on_simulated_button_unhovered.bind(button)):
		button.mouse_exited.connect(_on_simulated_button_unhovered.bind(button))
	if not button.button_down.is_connected(_on_simulated_button_pressed.bind(button)):
		button.button_down.connect(_on_simulated_button_pressed.bind(button))
	if not button.button_up.is_connected(_on_simulated_button_hovered.bind(button)):
		button.button_up.connect(_on_simulated_button_hovered.bind(button))


func _on_simulated_button_hovered(button: TextureButton) -> void:
	_tween_button_state(button, Vector2(1.05, 1.05), Color(1.15, 1.15, 1.22, 1.0), 0.12)


func _on_simulated_button_unhovered(button: TextureButton) -> void:
	_tween_button_state(button, Vector2.ONE, Color.WHITE, 0.12)


func _on_simulated_button_pressed(button: TextureButton) -> void:
	_tween_button_state(button, Vector2(0.95, 0.95), Color(0.85, 0.85, 0.9, 1.0), 0.08)


func _tween_button_state(button: TextureButton, scale_value: Vector2, color_value: Color, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", scale_value, duration)
	tween.parallel().tween_property(button, "modulate", color_value, duration)


func _style_progress_with_home_art(progress: ProgressBar) -> void:
	if progress == null:
		return
	var bg := StyleBoxTexture.new()
	bg.texture = HomeUIAssetsScript.direct("player_exp_bg")
	bg.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	bg.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	var fill := StyleBoxTexture.new()
	fill.texture = HomeUIAssetsScript.direct("player_exp_fill")
	fill.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	fill.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	progress.add_theme_stylebox_override("background", bg)
	progress.add_theme_stylebox_override("fill", fill)


func _apply_common_styles() -> void:
	$LeftPanel/PlayerProfilePanel.add_theme_stylebox_override("panel", _panel_style(PANEL_FAINT, PANEL_BORDER_FAINT, 1, 10))
	$LeftPanel/PlayerProfilePanel/AvatarFrame.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.02, 0.05, 0.36), PANEL_BORDER_FAINT, 1, 8))
	_style_match_button(_match_button)
	for path in [
		"TopBar/UtilityButtons/FriendsButton",
		"TopBar/UtilityButtons/MailButton",
		"TopBar/UtilityButtons/SettingsButton",
		"RightPanel/Btn_Quest",
		"RightPanel/Btn_Activity",
		"RightPanel/Btn_Deck",
		"RightPanel/Btn_Codex",
		"RightPanel/Btn_Summon",
		"RightPanel/Btn_Report",
		"StarMapPopup/PopupMargin/PopupLayout/PopupCloseButton",
		"PlaceholderPopup/PopupMargin/PopupLayout/PopupCloseButton",
		"LogoArea/ButtonColumn/BattleButton",
		"LogoArea/ButtonColumn/DeckBuilderButton",
		"LogoArea/ButtonColumn/HeroCodexButton",
		"LogoArea/ButtonColumn/ResultButton",
	]:
		_style_tool_button(get_node_or_null(path) as BaseButton)

	_style_progress(_exp_bar, Color(0.42, 0.78, 1.0, 0.78))
	_style_progress(_star_track_progress, Color(0.42, 0.78, 1.0, 0.95))
	for label in [_coin_label, _star_coin_label, _star_track_label, _star_map_hint_label]:
		label.add_theme_color_override("font_color", HUD_TEXT)
	_star_track_label.add_theme_color_override("font_color", HUD_GOLD)


func _connect_navigation() -> void:
	_connect_button("CenterWorld/CoreStarNode/MatchCoreButton", _open_battle)
	_connect_button("LogoArea/ButtonColumn/BattleButton", _open_battle_direct)
	_connect_button("RightPanel/Btn_Deck", _open_deck_builder)
	_connect_button("LogoArea/ButtonColumn/DeckBuilderButton", _open_deck_builder)
	_connect_button("RightPanel/Btn_Codex", _open_codex)
	_connect_button("LogoArea/ButtonColumn/HeroCodexButton", _open_codex)
	_connect_button("RightPanel/Btn_Report", _open_report)
	_connect_button("LogoArea/ButtonColumn/ResultButton", _open_report)
	_connect_button("StarMapPopup/PopupMargin/PopupLayout/PopupCloseButton", _close_star_map_popup)
	_connect_button("PlaceholderPopup/PopupMargin/PopupLayout/PopupCloseButton", _close_placeholder_popup)
	_connect_placeholder("TopBar/UtilityButtons/SettingsButton", "设置", "设置入口占位，后续接入音量、画质与账号选项。")
	_connect_placeholder("TopBar/UtilityButtons/MailButton", "邮件", "邮件入口占位，后续接入系统通知与奖励领取。")
	_connect_placeholder("TopBar/UtilityButtons/FriendsButton", "好友", "好友入口占位，后续接入好友列表与邀请。")
	_connect_placeholder("RightPanel/Btn_Quest", "任务", "任务入口占位，当前阶段不接入任务系统。")
	_connect_placeholder("RightPanel/Btn_Activity", "活动", "活动入口占位，当前阶段不接入活动系统。")
	_connect_placeholder("RightPanel/Btn_Summon", "召唤", "召唤入口占位，当前阶段不接入抽卡系统。")

	if not _match_button.mouse_entered.is_connected(_on_star_core_hovered):
		_match_button.mouse_entered.connect(_on_star_core_hovered)
	if not _match_button.mouse_exited.is_connected(_on_star_core_unhovered):
		_match_button.mouse_exited.connect(_on_star_core_unhovered)


func _connect_home_polish_navigation_overrides() -> void:
	_rewire_button("RightPanel/Btn_Quest", _open_codex)
	_rewire_button("RightPanel/Btn_Activity", _open_deck_builder)
	_rewire_placeholder("RightPanel/Btn_Deck", "任务", "任务入口占位，当前阶段不接入任务系统。")
	_rewire_placeholder("RightPanel/Btn_Codex", "活动", "活动入口占位，当前阶段不接入活动系统。")
	_rewire_placeholder("RightPanel/Btn_Summon", "图鉴", "图鉴入口占位，后续继续优化武将资料入口。")
	_rewire_placeholder("RightPanel/Btn_Report", "设置", "设置入口占位，正式设置面板后续接入。")
	if not _match_button.button_down.is_connected(_on_star_core_pressed):
		_match_button.button_down.connect(_on_star_core_pressed)
	if not _match_button.button_up.is_connected(_on_star_core_released):
		_match_button.button_up.connect(_on_star_core_released)


func _rewire_button(path: NodePath, target: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button == null:
		return
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection["callable"])
	button.pressed.connect(target)


func _rewire_placeholder(path: NodePath, title: String, body: String) -> void:
	var callback := func() -> void:
		_open_placeholder_popup(title, body)
	_rewire_button(path, callback)


func _connect_button(path: NodePath, target: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(target):
		button.pressed.connect(target)


func _connect_placeholder(path: NodePath, title: String, body: String) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button == null:
		return
	var callback := func() -> void:
		_open_placeholder_popup(title, body)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _refresh_runtime_data() -> void:
	var state: Dictionary = _app_snapshot()
	var star_track: Dictionary = StarTrackSystemScript.load_state()
	var progress: Dictionary = star_track.get("progress", {})
	var division: Dictionary = star_track.get("division", {})
	var value := int(star_track.get("current_star_track_value", state.get("star_track_value", 0)))
	var level := int(star_track.get("current_star_track_level", state.get("star_track_level", 1)))
	var division_name := str(division.get("short_name", division.get("name", "初星")))
	var to_next := int(progress.get("to_next", 0))

	_coin_label.text = "%d" % int(state.get("gold", 0))
	_star_coin_label.text = "%d" % int(state.get("star_stone", 0))
	_star_track_label.text = "%d · %s" % [value, division_name]
	_player_name_label.text = str(state.get("player_name", "玩家"))
	_level_label.text = "Lv.%d" % int(state.get("master_level", 1))
	_exp_bar.max_value = 100
	_exp_bar.value = int(state.get("player_exp", 0))
	_star_map_hint_label.text = "当前%s · 星轨值 %d · 距离下一段 %d" % [division_name, value, to_next]
	_star_track_level_label.text = "星轨 %d · %s" % [value, division_name]
	_star_track_delta_label.text = "距下段 %d" % to_next
	_star_track_progress.max_value = float(progress.get("progress_max", 1))
	_star_track_progress.value = float(progress.get("progress_value", 0))

	if _app_state != null:
		if "star_track_value" in _app_state:
			_app_state.star_track_value = value
		if "star_track_level" in _app_state:
			_app_state.star_track_level = level


func _app_snapshot() -> Dictionary:
	if _app_state != null and _app_state.has_method("snapshot"):
		return _app_state.snapshot()
	return {
		"player_name": "玩家",
		"master_level": 1,
		"star_track_value": 0,
		"star_track_level": 1,
		"gold": 0,
		"star_stone": 0,
		"battles_fought": 0,
	}


func _open_battle() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _play_warp_transition()
	_open_battle_direct()


func _open_battle_direct() -> void:
	_route_to(BATTLE_SCREEN, {
		"player_deck": DeckDataManagerScript.load_player_deck(),
		"enemy_deck": DeckDataManagerScript.default_enemy_deck(),
	})


func _open_deck_builder() -> void:
	_route_to(DECK_SCREEN)


func _open_codex() -> void:
	_route_to(CODEX_SCREEN)


func _open_report() -> void:
	_route_to(REPORT_SCREEN)


func _close_star_map_popup() -> void:
	_star_map_popup.hide()


func _open_placeholder_popup(title: String, body: String) -> void:
	_placeholder_title.text = title
	_placeholder_body.text = body
	_placeholder_popup.popup_centered(Vector2i(420, 220))


func _close_placeholder_popup() -> void:
	_placeholder_popup.hide()


func _route_to(scene_path: String, screen_data: Dictionary = {}) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.screen_changed.emit(scene_path, screen_data)
		return
	var router := get_parent()
	if router != null and router.has_method("show_screen"):
		router.show_screen(scene_path, screen_data)


func _start_star_core_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_core_node, "scale", Vector2(1.05, 1.05), 1.35)
	_pulse_tween.parallel().tween_method(_set_core_intensity, 1.0, 1.32, 1.35)
	_pulse_tween.tween_property(_core_node, "scale", Vector2.ONE, 1.35)
	_pulse_tween.parallel().tween_method(_set_core_intensity, 1.32, 1.0, 1.35)


func _on_star_core_hovered() -> void:
	if _hovered_star_core:
		return
	_hovered_star_core = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_world_hover_boost, 1.0, 2.25, 0.18)
	tween.parallel().tween_property(_orbit_system, "scale", Vector2(0.98, 0.98), 0.18)
	tween.parallel().tween_property(_match_button, "scale", Vector2(1.06, 1.06), 0.18)
	tween.parallel().tween_property(_match_button, "modulate", Color(1.14, 1.14, 1.22, 1.0), 0.18)
	tween.parallel().tween_property(_core_glow_art, "modulate:a", 0.62, 0.18)


func _on_star_core_unhovered() -> void:
	_hovered_star_core = false
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_world_hover_boost, 2.25, 1.0, 0.18)
	tween.parallel().tween_property(_orbit_system, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(_match_button, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(_match_button, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(_core_glow_art, "modulate:a", 0.45, 0.18)


func _on_star_core_pressed() -> void:
	_tween_button_state(_match_button, Vector2(0.94, 0.94), Color(0.82, 0.86, 0.92, 1.0), 0.08)


func _on_star_core_released() -> void:
	if _hovered_star_core:
		_tween_button_state(_match_button, Vector2(1.06, 1.06), Color(1.14, 1.14, 1.22, 1.0), 0.10)
	else:
		_tween_button_state(_match_button, Vector2.ONE, Color.WHITE, 0.10)


func _set_world_hover_boost(value: float) -> void:
	_set_layer_boost(_outer_starfield, lerpf(1.0, 1.35, (value - 1.0) / 1.25))
	_set_layer_boost(_orbit_system, value)
	_set_layer_boost(_energy_flow, value * 1.18)
	_set_layer_boost(_core_energy, value)
	_set_layer_intensity(_outer_starfield, lerpf(1.0, 1.12, (value - 1.0) / 1.25))
	_set_layer_intensity(_orbit_system, lerpf(1.0, 1.45, (value - 1.0) / 1.25))
	_set_layer_intensity(_energy_flow, lerpf(0.42, 0.76, (value - 1.0) / 1.25))
	_set_layer_intensity(_core_energy, lerpf(1.0, 1.55, (value - 1.0) / 1.25))


func _set_core_intensity(value: float) -> void:
	if not _hovered_star_core and not _transitioning:
		_set_layer_intensity(_core_energy, value)


func _is_inside_match_core(screen_position: Vector2) -> bool:
	if _match_button == null or not _match_button.is_visible_in_tree():
		return false
	var rect := _match_button.get_global_rect()
	var center := rect.get_center()
	var radius: float = maxf(rect.size.x, rect.size.y) * 0.58
	return screen_position.distance_to(center) <= radius


func _layer_boost(layer: Control) -> float:
	var value = layer.get("hover_boost")
	if value == null:
		return 1.0
	return float(value)


func _set_layer_boost(layer: Control, value: float) -> void:
	if layer.has_method("set_hover_boost"):
		layer.call("set_hover_boost", value)


func _set_layer_intensity(layer: Control, value: float) -> void:
	if layer.has_method("set_intensity"):
		layer.call("set_intensity", value)


func _play_warp_transition() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	_set_world_hover_boost(2.8)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_core_node, "scale", Vector2(0.82, 0.82), 0.16)
	tween.parallel().tween_property($TopBar, "modulate:a", 0.20, 0.16)
	tween.parallel().tween_property($LeftPanel, "modulate:a", 0.14, 0.16)
	tween.parallel().tween_property($RightPanel, "modulate:a", 0.12, 0.16)
	tween.tween_property(_core_node, "scale", Vector2(1.30, 1.30), 0.22)
	tween.parallel().tween_property(_orbit_system, "scale", Vector2(1.12, 1.12), 0.22)
	tween.parallel().tween_property(_warp_overlay, "modulate:a", 0.42, 0.22)
	tween.parallel().tween_property(_match_button, "scale", Vector2(0.72, 0.72), 0.22)
	await tween.finished


func _apply_font_scale() -> void:
	var vw := get_viewport_rect().size.x
	_match_text_label.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw) + 19)
	_star_map_hint_label.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw) - 1)
	$VersionLabel.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw) - 3)


func _style_tool_button(button: BaseButton) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", HUD_TEXT)
	button.add_theme_font_size_override("font_size", 14)
	if button is TextureButton:
		return
	button.add_theme_stylebox_override("normal", _button_style(TOOL_BUTTON, TOOL_BORDER, 8, 1))
	button.add_theme_stylebox_override("hover", _button_style(TOOL_BUTTON_HOVER, Color(0.9, 0.78, 0.48, 0.48), 8, 1))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.03, 0.06, 0.13, 0.78), TOOL_BORDER, 8, 1))


func _style_match_button(button: BaseButton) -> void:
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	if button is TextureButton:
		return
	button.add_theme_stylebox_override("normal", _button_style(MATCH_BUTTON, MATCH_BORDER, 999, 3))
	button.add_theme_stylebox_override("hover", _button_style(MATCH_BUTTON_HOVER, Color(1.0, 0.88, 0.52, 1.0), 999, 3))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.06, 0.24, 0.42, 1.0), MATCH_BORDER, 999, 3))


func _panel_style(color: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 4
	return style


func _circle_style(color: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.1, 0.5, 0.9, 0.28)
	style.shadow_size = 18
	return style


func _button_style(color: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _style_progress(progress: ProgressBar, fill_color: Color) -> void:
	if progress == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.01, 0.02, 0.055, 0.72)
	bg.set_corner_radius_all(999)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(999)
	progress.add_theme_stylebox_override("background", bg)
	progress.add_theme_stylebox_override("fill", fill)
