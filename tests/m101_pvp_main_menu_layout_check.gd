extends SceneTree

const MainMenuScene: PackedScene = preload("res://scenes/ui/MainMenuScene.tscn")
const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")
const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")

var _original_save: Dictionary = {}
var _had_original_save := false


func _init() -> void:
	var failures: Array[String] = []
	_backup_save()
	StarTrackSystemScript.save_state(520)
	await _check_star_chart_focus_menu(failures)
	_restore_save()
	if failures.is_empty():
		print("M101 star chart focus main menu checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _backup_save() -> void:
	_original_save = SaveServiceScript.load_game()
	_had_original_save = not _original_save.is_empty()


func _restore_save() -> void:
	if _had_original_save:
		SaveServiceScript.save_game(_original_save)
	else:
		SaveServiceScript.delete_save()


func _check_star_chart_focus_menu(failures: Array[String]) -> void:
	var screen: Control = MainMenuScene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect(screen.has_node("BackgroundLayer/Background"), "has requested background layer texture", failures)
	_expect(screen.has_node("TopBar/CoinLabel"), "top bar exposes coin label", failures)
	_expect(screen.has_node("TopBar/CoinIcon"), "top bar exposes coin icon", failures)
	_expect(screen.has_node("TopBar/StarCoinLabel"), "top bar exposes star coin label", failures)
	_expect(screen.has_node("TopBar/StarCoinIcon"), "top bar exposes star coin icon", failures)
	_expect(screen.has_node("TopBar/StarTrackLabel"), "top bar exposes star track label", failures)
	_expect(screen.has_node("TopBar/StarTrackIcon"), "top bar exposes star track icon", failures)
	_expect(screen.has_node("TopBarBg"), "top bar has art background", failures)
	_expect(screen.has_node("LeftPanel/PlayerProfilePanel/AvatarFrame/Avatar"), "left panel has weakened avatar slot", failures)
	_expect(screen.has_node("LeftPanel/PlayerProfilePanel/PlayerPanelBg"), "left panel has player art background", failures)
	_expect(screen.has_node("LeftPanel/PlayerProfilePanel/AvatarFrameArt"), "left panel has avatar frame art", failures)
	_expect(screen.has_node("LeftPanel/PlayerProfilePanel/LevelLabel"), "left panel has runtime level label", failures)
	_expect(screen.has_node("LeftPanel/PlayerProfilePanel/ExpBar"), "left panel has runtime exp bar", failures)
	_expect(screen.has_node("CenterWorld/OuterStarFieldLayer"), "center world has outer drifting star field layer", failures)
	_expect(screen.has_node("CenterWorld/OrbitStarSystemLayer"), "center world has orbit star system layer", failures)
	_expect(screen.has_node("CenterWorld/OrbitStarSystemLayer/OrbitLayerArt"), "center world has orbit art texture layer", failures)
	_expect(screen.has_node("CenterWorld/OrbitStarSystemLayer/EnergyFlowLines"), "center world has energy flow layer", failures)
	_expect(screen.has_node("CenterWorld/CoreStarNode/CoreGlowArt"), "center core has glow art texture layer", failures)
	_expect(screen.has_node("CenterWorld/CoreStarNode/CoreNodeArt"), "center core has node art texture layer", failures)
	_expect(screen.has_node("CenterWorld/CoreStarNode/PulsingEnergyCore"), "center world has pulsing core layer", failures)
	_expect(screen.has_node("CenterWorld/CoreStarNode/MatchCoreButton"), "match button is embedded as star core trigger", failures)
	_expect(screen.has_node("CenterWorld/WarpOverlay"), "center world has warp overlay for transition", failures)
	_expect(screen.has_node("CenterWorld/StarMapHintLabel"), "center world has small hint text", failures)
	_expect(screen.has_node("RightPanel/Btn_Quest"), "right toolbar has quest entry", failures)
	_expect(screen.has_node("RightPanel/Btn_Activity"), "right toolbar has activity entry", failures)
	_expect(screen.has_node("RightPanel/Btn_Deck"), "right toolbar has deck entry", failures)
	_expect(screen.has_node("RightPanel/Btn_Codex"), "right toolbar has codex entry", failures)
	_expect(screen.has_node("RightPanel/Btn_Summon"), "right toolbar has summon entry", failures)
	_expect(screen.has_node("RightPanel/Btn_Report"), "right toolbar has report entry", failures)
	_expect(screen.has_node("RightPanel/Btn_Quest/EntryLabel"), "right toolbar quest slot has readable label", failures)
	_expect(screen.has_node("RightPanel/Btn_Report/EntryLabel"), "right toolbar report slot has readable label", failures)
	_expect(screen.has_node("BottomLayer"), "bottom layer is reserved", failures)

	var core: Control = screen.get_node("CenterWorld")
	var match_button: TextureButton = screen.get_node("CenterWorld/CoreStarNode/MatchCoreButton")
	var right_panel: VBoxContainer = screen.get_node("RightPanel")
	var left_panel: Control = screen.get_node("LeftPanel")
	var orbit_layer: Control = screen.get_node("CenterWorld/OrbitStarSystemLayer")
	var core_node: Control = screen.get_node("CenterWorld/CoreStarNode")
	_expect(orbit_layer.size.x >= 620.0 and orbit_layer.size.y >= 620.0, "star world occupies the central visual mass", failures)
	_expect(match_button.get_parent() == core_node, "match start button is not an independent external button", failures)
	_expect(match_button.custom_minimum_size.x >= 210.0, "match start button is enlarged for home polish v1", failures)
	_expect(match_button.texture_normal != null and match_button.texture_hover != null and match_button.texture_pressed != null, "match start button uses three-state star core textures", failures)
	_expect(right_panel.custom_minimum_size.x <= 120.0, "right entries are reduced into a toolbar", failures)
	_expect(left_panel.size.x >= 250.0 and left_panel.size.x <= 290.0, "player profile is widened but still edge-weighted", failures)

	var right_order: Array[String] = []
	for child in right_panel.get_children():
		if child is TextureButton:
			right_order.append(child.name)
	_expect(right_order == ["Btn_Quest", "Btn_Activity", "Btn_Deck", "Btn_Codex", "Btn_Summon", "Btn_Report"], "right toolbar order matches art spec", failures)

	var star_track_label: Label = screen.get_node("TopBar/StarTrackLabel")
	_expect(star_track_label.text.contains("520"), "star track value is runtime-bound into top status bar", failures)
	var hint: Label = screen.get_node("CenterWorld/StarMapHintLabel")
	_expect(hint.text.contains("520"), "star map hint is runtime-bound", failures)
	var match_text: Label = screen.get_node("CenterWorld/CoreStarNode/MatchCoreButton/MatchTextLabel")
	_expect(match_text.text.contains("对弈"), "match core text uses polished Chinese call to action", failures)
	_expect(match_text.get_theme_font_size(&"font_size") >= 34, "match core text is larger and readable", failures)
	_expect(not screen.get_node("VersionLabel").visible, "English alpha label is hidden in polished home", failures)
	var expected_labels := {
		"RightPanel/Btn_Quest/EntryLabel": "武将",
		"RightPanel/Btn_Activity/EntryLabel": "阵容",
		"RightPanel/Btn_Deck/EntryLabel": "任务",
		"RightPanel/Btn_Codex/EntryLabel": "活动",
		"RightPanel/Btn_Summon/EntryLabel": "图鉴",
		"RightPanel/Btn_Report/EntryLabel": "设置",
	}
	for path in expected_labels:
		var label: Label = screen.get_node(path)
		_expect(label.text == expected_labels[path], "%s uses home polish v1 label" % path, failures)
	var progress: ProgressBar = screen.get_node("StarTrackPanel/StarTrackMargin/StarTrackLayout/StarTrackProgress")
	_expect(progress.max_value > 0.0 and progress.value > 0.0, "compat star track progress remains runtime-bound", failures)

	_expect(screen.has_node("LogoArea/ButtonColumn/BattleButton"), "keeps legacy battle button alias for game loop tests", failures)
	screen.queue_free()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
