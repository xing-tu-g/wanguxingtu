extends Control

const HOME_SCREEN := "res://scenes/ui/MainMenuScene.tscn"

const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const SkillDataLoaderScript: GDScript = preload("res://scripts/data/SkillDataLoader.gd")
const HeroIdentityDataScript: GDScript = preload("res://scripts/data/HeroIdentityData.gd")

var _grid: GridContainer
var _detail: RichTextLabel
var _filter_faction := "all"
var _filter_class := "all"


func _ready() -> void:
	_build_screen()
	_refresh_grid()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.015, 0.022, 0.06, 1.0)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "CodexMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "CodexLayout"
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	layout.add_child(_build_header())
	layout.add_child(_build_filters())

	var body := HBoxContainer.new()
	body.name = "CodexBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	layout.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.name = "HeroCodexScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	_grid = GridContainer.new()
	_grid.name = "HeroCodexGrid"
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "HeroCodexDetailPanel"
	detail_panel.custom_minimum_size = Vector2(520, 0)
	detail_panel.add_theme_stylebox_override("panel", _panel_style())
	body.add_child(detail_panel)

	_detail = RichTextLabel.new()
	_detail.name = "HeroCodexDetail"
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	detail_panel.add_child(_detail)


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.name = "CodexHeader"
	row.custom_minimum_size = Vector2(0, 64)

	var back := _make_button("BackButton", "返回", Vector2(110, 52))
	back.pressed.connect(_return_home)
	row.add_child(back)

	var title := Label.new()
	title.name = "Title"
	title.text = "武将图鉴"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.94, 0.86, 0.62, 1.0))
	row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(110, 52)
	row.add_child(spacer)
	return row


func _build_filters() -> Control:
	var row := HBoxContainer.new()
	row.name = "CodexFilterRow"
	row.add_theme_constant_override("separation", 10)
	for item in [
		["all", "全部阵营", "faction"], ["shu", "蜀", "faction"], ["wei", "魏", "faction"], ["wu", "吴", "faction"], ["qun", "群", "faction"],
		["all", "全部职业", "class"], ["warrior", "战士", "class"], ["mage", "法师", "class"], ["tank", "坦克", "class"], ["assassin", "刺客", "class"], ["archer", "射手", "class"],
	]:
		var button := _make_button("CodexFilter_%s_%s" % [item[2], item[0]], item[1], Vector2(90, 42))
		button.pressed.connect(_apply_filter.bind(str(item[2]), str(item[0])))
		row.add_child(button)
	return row


func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var first_id := ""
	for hero: Dictionary in HeroDataLoaderScript.all_heroes(false):
		if not _matches_filter(hero):
			continue
		var hero_id := str(hero.get("id", ""))
		if first_id.is_empty():
			first_id = hero_id
		_grid.add_child(_make_hero_button(hero))
	if not first_id.is_empty():
		_show_detail(first_id)
	else:
		_detail.text = "没有符合筛选条件的武将。"


func _make_hero_button(hero: Dictionary) -> Button:
	var hero_id := str(hero.get("id", ""))
	var button := Button.new()
	button.name = "CodexHero_%s" % hero_id
	button.custom_minimum_size = Vector2(220, 96)
	button.text = "%s\n%s / %s" % [
		str(hero.get("name", hero_id)),
		_faction_text(str(hero.get("faction", ""))),
		_class_text(str(hero.get("profession", hero.get("class", "")))),
	]
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.pressed.connect(_show_detail.bind(hero_id))
	return button


func _show_detail(hero_id: String) -> void:
	var hero: Dictionary = HeroDataLoaderScript.hero_by_id(hero_id)
	var identity: Dictionary = HeroIdentityDataScript.identity_for(hero_id)
	var skill_lines: Array[String] = []
	for skill_id in hero.get("skill_ids", []):
		var skill: Dictionary = SkillDataLoaderScript.skill_by_id(str(skill_id))
		skill_lines.append("%s：%s" % [
			str(skill.get("name", skill_id)),
			str(skill.get("description", skill.get("desc", "暂无说明"))),
		])
	_detail.text = "\n".join([
		"[b]%s[/b]" % str(hero.get("name", hero_id)),
		"阵营：%s    职业：%s    稀有度：%s" % [_faction_text(str(hero.get("faction", ""))), _class_text(str(hero.get("profession", hero.get("class", "")))), _rarity_text(str(hero.get("rarity", "")))],
		"费用：%d  生命：%d  攻击：%d  移动：%d  射程：%d" % [int(hero.get("cost", 0)), int(hero.get("max_hp", 0)), int(hero.get("attack", 0)), int(hero.get("move", 0)), int(hero.get("range", 0))],
		"",
		"[b]一句话定位[/b]",
		str(identity.get("positioning", "")),
		"",
		"[b]核心玩法[/b]",
		str(identity.get("playstyle", "")),
		"",
		"[b]战斗标签[/b]",
		str(identity.get("tags", "")),
		"",
		"[b]技能[/b]",
		"\n".join(skill_lines) if not skill_lines.is_empty() else "暂无技能",
	])


func _apply_filter(kind: String, value: String) -> void:
	if kind == "faction":
		_filter_faction = value
	else:
		_filter_class = value
	_refresh_grid()


func _matches_filter(hero: Dictionary) -> bool:
	if _filter_faction != "all" and str(hero.get("faction", "")) != _filter_faction:
		return false
	var class_id := str(hero.get("profession", hero.get("class", "")))
	if _filter_class != "all" and class_id != _filter_class:
		return false
	return true


func _return_home() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.screen_changed.emit(HOME_SCREEN, {})


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
	style.bg_color = Color(0.04, 0.055, 0.12, 0.86)
	style.border_color = Color(0.86, 0.72, 0.38, 0.42)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	return style


func _button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.16, 0.30, 0.94) if not active else Color(0.08, 0.24, 0.40, 0.98)
	style.border_color = Color(0.93, 0.74, 0.36, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style


func _faction_text(faction: String) -> String:
	return {"all": "全部", "shu": "蜀", "wei": "魏", "wu": "吴", "qun": "群"}.get(faction, faction)


func _class_text(class_id: String) -> String:
	return {"all": "全部", "warrior": "战士", "mage": "法师", "tank": "坦克", "assassin": "刺客", "archer": "射手"}.get(class_id, class_id)


func _rarity_text(rarity: String) -> String:
	return {"rare": "稀有", "epic": "史诗", "legendary": "传说", "legend": "传说"}.get(rarity, rarity)
