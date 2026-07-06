extends Control

const HOME_SCREEN := "res://scenes/ui/MainMenuScene.tscn"
const BATTLE_SCREEN := "res://scenes/ui/BattleScreen.tscn"

const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const DeckDataManagerScript: GDScript = preload("res://scripts/data/DeckDataManager.gd")
const StarTrackSystemScript: GDScript = preload("res://scripts/data/StarTrackSystem.gd")
const BattleUIAssetsScript: GDScript = preload("res://scripts/ui/theme/BattleUIAssets.gd")
const FontScaleScript: GDScript = preload("res://scripts/ui/theme/FontScale.gd")

var player_deck: Array = []
var enemy_deck: Array = []
var _all_heroes: Array = []
var _filter_faction := "all"
var _filter_class := "all"

var _count_label: Label
var _grid: GridContainer
var _start_button: Button
var _filter_label: Label


func _ready() -> void:
	_all_heroes = HeroDataLoaderScript.all_heroes(false)
	player_deck = DeckDataManagerScript.load_player_deck()
	enemy_deck = DeckDataManagerScript.default_enemy_deck()
	_build_screen()
	_refresh_grid()
	_refresh_summary()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.02, 0.03, 0.09, 1.0)
	add_child(background)

	var bg_image := TextureRect.new()
	bg_image.name = "DeckBackgroundImage"
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.texture = BattleUIAssetsScript.background_texture()
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate = Color(1, 1, 1, 0.26)
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(bg_image)

	var wash := ColorRect.new()
	wash.name = "DeckReadabilityWash"
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.01, 0.015, 0.04, 0.68)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(wash)

	var margin := MarginContainer.new()
	margin.name = "DeckMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "DeckLayout"
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	layout.add_child(_build_header())
	layout.add_child(_build_filters())
	layout.add_child(_build_roster_panel())
	layout.add_child(_build_footer())


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.name = "DeckHeader"
	header.custom_minimum_size = Vector2(0, 72)

	var back_button := _make_button("BackButton", "返回", Vector2(112, 54))
	back_button.pressed.connect(_return_home)
	header.add_child(back_button)

	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.name = "Title"
	title.text = "卡组编辑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FontScaleScript.title_size(get_viewport_rect().size.x) - 10)
	title.add_theme_color_override("font_color", Color(0.94, 0.86, 0.62, 1.0))
	title_box.add_child(title)

	_count_label = Label.new()
	_count_label.name = "DeckCountLabel"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 20)
	_count_label.add_theme_color_override("font_color", Color(0.70, 0.86, 1.0, 0.86))
	title_box.add_child(_count_label)

	var save_button := _make_button("SaveDeckButton", "保存卡组", Vector2(140, 54))
	save_button.pressed.connect(_save_deck)
	header.add_child(save_button)
	return header


func _build_filters() -> Control:
	var row := HBoxContainer.new()
	row.name = "DeckFilterRow"
	row.custom_minimum_size = Vector2(0, 52)
	row.add_theme_constant_override("separation", 10)

	_filter_label = Label.new()
	_filter_label.name = "DeckFilterLabel"
	_filter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_filter_label.add_theme_font_size_override("font_size", 18)
	_filter_label.add_theme_color_override("font_color", Color(0.76, 0.84, 0.94, 0.9))
	row.add_child(_filter_label)

	for item in [
		["all", "全部阵营", "faction"], ["shu", "蜀", "faction"], ["wei", "魏", "faction"], ["wu", "吴", "faction"], ["qun", "群", "faction"],
		["warrior", "战士", "class"], ["mage", "法师", "class"], ["tank", "坦克", "class"], ["assassin", "刺客", "class"], ["archer", "射手", "class"],
	]:
		var button := _make_button("Filter_%s_%s" % [item[2], item[0]], item[1], Vector2(88, 42))
		button.pressed.connect(_apply_filter.bind(str(item[2]), str(item[0])))
		row.add_child(button)
	return row


func _build_roster_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "DeckRosterPanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())

	var margin := MarginContainer.new()
	margin.name = "RosterMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "RosterScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	_grid = GridContainer.new()
	_grid.name = "HeroDeckGrid"
	_grid.columns = 8
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)
	return panel


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.name = "DeckFooter"
	footer.custom_minimum_size = Vector2(0, 72)
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 14)

	var hint := Label.new()
	hint.name = "DeckHint"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.text = "点击武将加入或移出当前卡组。战斗卡组上限 20，保存后主菜单开始战斗会使用当前卡组。"
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.74, 0.80, 0.92, 0.86))
	footer.add_child(hint)

	var reset_button := _make_button("ResetDefaultDeckButton", "推荐卡组", Vector2(160, 62))
	reset_button.pressed.connect(_reset_default_deck)
	footer.add_child(reset_button)

	_start_button = _make_button("StartBattleButton", "进入战斗", Vector2(220, 62))
	_start_button.pressed.connect(_start_battle)
	footer.add_child(_start_button)
	return footer


func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for hero in _all_heroes:
		if not _matches_filter(hero):
			continue
		_grid.add_child(_make_hero_tile(str(hero.get("id", ""))))


func _make_hero_tile(hero_id: String) -> Control:
	var hero_def: Dictionary = HeroDataLoaderScript.hero_by_id(hero_id)
	var unlocked: bool = StarTrackSystemScript.is_hero_unlocked(hero_id)
	var button := Button.new()
	button.name = "HeroTile_%s" % hero_id
	button.custom_minimum_size = Vector2(196, 218)
	button.toggle_mode = true
	button.button_pressed = player_deck.has(hero_id)
	button.disabled = not unlocked
	button.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.45, 0.48, 0.55, 0.72)
	button.add_theme_stylebox_override("normal", _hero_tile_style(hero_def, false))
	button.add_theme_stylebox_override("pressed", _hero_tile_style(hero_def, true))
	button.add_theme_stylebox_override("hover", _hero_tile_style(hero_def, true))
	button.pressed.connect(_toggle_hero.bind(hero_id))

	var layout := VBoxContainer.new()
	layout.name = "HeroTileLayout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 4)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layout)

	var portrait := TextureRect.new()
	portrait.name = "HeroPortrait"
	portrait.custom_minimum_size = Vector2(150, 122)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = _load_texture(str(hero_def.get("hero_master", hero_def.get("portrait", ""))))
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(portrait)

	var name_label := Label.new()
	name_label.name = "HeroName"
	name_label.text = str(hero_def.get("name", hero_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.78, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(name_label)

	var meta_label := Label.new()
	meta_label.name = "HeroMeta"
	meta_label.text = "%s / %s / 费%d" % [
		_faction_text(str(hero_def.get("faction", ""))),
		_class_text(str(hero_def.get("profession", hero_def.get("class", "")))),
		int(hero_def.get("cost", 0)),
	]
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 16)
	meta_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.92, 0.82))
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(meta_label)

	if not unlocked:
		var lock_label := Label.new()
		lock_label.name = "LockLabel"
		lock_label.text = "星轨未解锁"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 15)
		lock_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36, 0.96))
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(lock_label)
	return button


func _toggle_hero(hero_id: String) -> void:
	if not StarTrackSystemScript.is_hero_unlocked(hero_id):
		return
	if player_deck.has(hero_id):
		player_deck.erase(hero_id)
	elif player_deck.size() < DeckDataManagerScript.MAX_BATTLE_DECK_SIZE:
		player_deck.append(hero_id)
	_refresh_grid()
	_refresh_summary()


func _save_deck() -> void:
	DeckDataManagerScript.save_player_deck(player_deck)
	_refresh_summary("已保存")


func _reset_default_deck() -> void:
	player_deck = DeckDataManagerScript.default_player_deck()
	_refresh_grid()
	_refresh_summary("已载入推荐卡组")


func _apply_filter(kind: String, value: String) -> void:
	if kind == "faction":
		_filter_faction = value
	else:
		_filter_class = value
	_refresh_grid()
	_refresh_summary()


func _matches_filter(hero: Dictionary) -> bool:
	if _filter_faction != "all" and str(hero.get("faction", "")) != _filter_faction:
		return false
	var class_id := str(hero.get("profession", hero.get("class", "")))
	if _filter_class != "all" and class_id != _filter_class:
		return false
	return true


func _refresh_summary(extra: String = "") -> void:
	var text := "当前卡组 %d / %d，可用武将 %d" % [
		player_deck.size(),
		DeckDataManagerScript.MAX_BATTLE_DECK_SIZE,
		StarTrackSystemScript.unlocked_hero_ids().size(),
	]
	if not extra.is_empty():
		text += "，%s" % extra
	if _count_label != null:
		_count_label.text = text
	if _filter_label != null:
		_filter_label.text = "阵营：%s    职业：%s" % [_faction_text(_filter_faction), _class_text(_filter_class)]
	if _start_button != null:
		_start_button.disabled = player_deck.size() < DeckDataManagerScript.MIN_BATTLE_DECK_SIZE


func _start_battle() -> void:
	DeckDataManagerScript.save_player_deck(player_deck)
	_route_to(BATTLE_SCREEN, {
		"player_deck": player_deck,
		"enemy_deck": enemy_deck,
	})


func _return_home() -> void:
	_route_to(HOME_SCREEN)


func _route_to(scene_path: String, screen_data: Dictionary = {}) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.screen_changed.emit(scene_path, screen_data)
		return
	var router := get_parent()
	if router != null and router.has_method("show_screen"):
		router.show_screen(scene_path, screen_data)


func _make_button(node_name: String, label: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = min_size
	button.text = label
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.055, 0.12, 0.78)
	style.border_color = Color(0.86, 0.72, 0.38, 0.42)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	return style


func _hero_tile_style(hero_def: Dictionary, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match str(hero_def.get("rarity", "rare")):
		"legendary", "legend":
			style.bg_color = Color(0.38, 0.25, 0.08, 0.78 if selected else 0.58)
			style.border_color = Color(1.0, 0.78, 0.30, 0.94 if selected else 0.64)
		"epic":
			style.bg_color = Color(0.22, 0.12, 0.34, 0.78 if selected else 0.58)
			style.border_color = Color(0.72, 0.44, 1.0, 0.92 if selected else 0.60)
		_:
			style.bg_color = Color(0.08, 0.20, 0.34, 0.78 if selected else 0.58)
			style.border_color = Color(0.34, 0.76, 1.0, 0.90 if selected else 0.58)
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.16, 0.30, 0.94) if not active else Color(0.08, 0.24, 0.40, 0.98)
	style.border_color = Color(0.93, 0.74, 0.36, 0.78) if not active else Color(1.0, 0.82, 0.42, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	return style


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _faction_text(faction: String) -> String:
	return {"all": "全部", "shu": "蜀", "wei": "魏", "wu": "吴", "qun": "群"}.get(faction, faction)


func _class_text(class_id: String) -> String:
	return {
		"all": "全部",
		"warrior": "战士",
		"mage": "法师",
		"tank": "坦克",
		"assassin": "刺客",
		"archer": "射手",
	}.get(class_id, class_id)
