extends SceneTree

const MainMenuScene: PackedScene = preload("res://scenes/ui/MainMenuScene.tscn")
const HomeUIAssetsScript: GDScript = preload("res://scripts/ui/theme/HomeUIAssets.gd")

const EXPECTED_FILES := [
	"icon_star_core_default.png",
	"icon_star_core_hover.png",
	"icon_star_core_pressed.png",
	"icon_star_core_matching.png",
	"icon_quest_default.png",
	"icon_quest_hover.png",
	"icon_quest_pressed.png",
	"icon_activity_default.png",
	"icon_activity_hover.png",
	"icon_activity_pressed.png",
	"icon_deck_default.png",
	"icon_deck_hover.png",
	"icon_deck_pressed.png",
	"icon_codex_default.png",
	"icon_codex_hover.png",
	"icon_codex_pressed.png",
	"icon_summon_default.png",
	"icon_summon_hover.png",
	"icon_summon_pressed.png",
	"icon_report_default.png",
	"icon_report_hover.png",
	"icon_settings_default.png",
	"icon_settings_hover.png",
	"icon_settings_pressed.png",
	"icon_mail_default.png",
	"icon_mail_hover.png",
	"icon_mail_pressed.png",
	"icon_friends_default.png",
	"icon_friends_hover.png",
	"icon_friends_pressed.png",
	"panel_player_bg.png",
	"panel_player_avatar_frame.png",
	"panel_player_exp_bar_bg.png",
	"panel_player_exp_bar_fill.png",
	"star_map_background.png",
	"star_map_orbit_layer.png",
	"star_map_node.png",
	"star_map_glow.png",
	"panel_topbar_bg.png",
	"icon_coin.png",
	"icon_star_coin.png",
	"icon_star_track.png",
]

const OPAQUE_ALLOWED := {
	"star_map_background.png": true,
}


func _init() -> void:
	var failures: Array[String] = []
	_check_files_exist(failures)
	_check_processed_alpha(failures)
	await _check_scene_bindings(failures)
	if failures.is_empty():
		print("M102 home UI assets checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_files_exist(failures: Array[String]) -> void:
	for file_name in EXPECTED_FILES:
		_expect(FileAccess.file_exists("res://assets/ui/home/%s" % file_name), "home art source exists: %s" % file_name, failures)
	_expect(FileAccess.file_exists("res://assets/ui/home/home_ui_asset_report.json"), "home art processing report exists", failures)


func _check_processed_alpha(failures: Array[String]) -> void:
	for file_name in EXPECTED_FILES:
		if OPAQUE_ALLOWED.has(file_name):
			continue
		var used_path: String = HomeUIAssetsScript.texture_path(file_name)
		if used_path.contains("/processed/"):
			_expect(_has_transparent_corners(used_path), "processed texture has transparent edge background: %s" % used_path, failures)


func _check_scene_bindings(failures: Array[String]) -> void:
	var screen: Control = MainMenuScene.instantiate()
	root.add_child(screen)
	await process_frame

	var match_button := screen.get_node("CenterWorld/CoreStarNode/MatchCoreButton") as TextureButton
	_expect(match_button.texture_normal != null, "star core normal texture bound", failures)
	_expect(match_button.texture_hover != null, "star core hover texture bound", failures)
	_expect(match_button.texture_pressed != null, "star core pressed texture bound", failures)

	var right_panel := screen.get_node("RightPanel") as VBoxContainer
	var right_order: Array[String] = []
	for child in right_panel.get_children():
		if child is TextureButton:
			right_order.append(child.name)
	_expect(right_order == ["Btn_Quest", "Btn_Activity", "Btn_Deck", "Btn_Codex", "Btn_Summon", "Btn_Report"], "right toolbar order is quest/activity/deck/codex/summon/report", failures)

	var utility := screen.get_node("TopBar/UtilityButtons") as HBoxContainer
	var utility_order: Array[String] = []
	for child in utility.get_children():
		if child is TextureButton:
			utility_order.append(child.name)
	_expect(utility_order == ["FriendsButton", "MailButton", "SettingsButton"], "utility toolbar order is friends/mail/settings", failures)

	for path in [
		"RightPanel/Btn_Quest",
		"RightPanel/Btn_Activity",
		"RightPanel/Btn_Deck",
		"RightPanel/Btn_Codex",
		"RightPanel/Btn_Summon",
		"RightPanel/Btn_Report",
		"TopBar/UtilityButtons/FriendsButton",
		"TopBar/UtilityButtons/MailButton",
		"TopBar/UtilityButtons/SettingsButton",
	]:
		var button := screen.get_node(path) as TextureButton
		_expect(button.texture_normal != null, "%s normal texture bound" % path, failures)
		_expect(button.texture_hover != null, "%s hover texture bound or fallback bound" % path, failures)
		_expect(button.texture_pressed != null, "%s pressed texture bound or fallback bound" % path, failures)

	for path in [
		"TopBarBg",
		"TopBar/CoinIcon",
		"TopBar/StarCoinIcon",
		"TopBar/StarTrackIcon",
		"LeftPanel/PlayerProfilePanel/PlayerPanelBg",
		"LeftPanel/PlayerProfilePanel/AvatarFrameArt",
		"CenterWorld/OrbitStarSystemLayer/OrbitLayerArt",
		"CenterWorld/CoreStarNode/CoreGlowArt",
		"CenterWorld/CoreStarNode/CoreNodeArt",
	]:
		var texture_rect := screen.get_node(path) as TextureRect
		_expect(texture_rect.texture != null, "%s texture bound" % path, failures)
	screen.queue_free()


func _has_transparent_corners(path: String) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return false
	if image.get_format() not in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH]:
		return false
	var w := image.get_width()
	var h := image.get_height()
	for point in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		if image.get_pixelv(point).a > 0.02:
			return false
	return true


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
