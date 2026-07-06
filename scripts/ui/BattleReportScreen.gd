extends Control

const HOME_SCREEN := "res://scenes/ui/MainMenuScene.tscn"
const BATTLE_SCREEN := "res://scenes/ui/BattleScreen.tscn"
const DECK_SCREEN := "res://scenes/ui/DeckBuilderScene.tscn"

const BattleReportManagerScript: GDScript = preload("res://scripts/data/BattleReportManager.gd")
const DeckDataManagerScript: GDScript = preload("res://scripts/data/DeckDataManager.gd")
const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const SkillDataLoaderScript: GDScript = preload("res://scripts/data/SkillDataLoader.gd")

var report_data: Dictionary = {}
var _title: Label
var _summary: RichTextLabel
var _cards_root: VBoxContainer


func set_screen_data(screen_data: Dictionary) -> void:
	report_data = screen_data.duplicate(true)


func _ready() -> void:
	_build_screen()
	if report_data.is_empty():
		report_data = BattleReportManagerScript.latest_report()
	elif report_data.has("outcome"):
		report_data = BattleReportManagerScript.record_report(report_data)
	_refresh()


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.015, 0.022, 0.06, 1.0)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "BattleReportMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "BattleReportLayout"
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.name = "BattleReportHeader"
	layout.add_child(header)

	var home := _make_button("HomeButton", "返回主界面", Vector2(160, 54))
	home.pressed.connect(_return_home)
	header.add_child(home)

	_title = Label.new()
	_title.name = "Title"
	_title.text = "战报记录"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color(0.94, 0.86, 0.62, 1.0))
	header.add_child(_title)

	var retry := _make_button("RetryButton", "下一局", Vector2(140, 54))
	retry.pressed.connect(_retry_battle)
	header.add_child(retry)

	var panel := PanelContainer.new()
	panel.name = "BattleReportPanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())
	layout.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.name = "BattleReportScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	_cards_root = VBoxContainer.new()
	_cards_root.name = "BattleReportCards"
	_cards_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_root.add_theme_constant_override("separation", 14)
	scroll.add_child(_cards_root)

	_summary = RichTextLabel.new()
	_summary.name = "BattleReportSummary"
	_summary.bbcode_enabled = true
	_summary.fit_content = false
	_summary.scroll_active = true
	_summary.visible = false
	_summary.custom_minimum_size = Vector2(1, 1)
	panel.add_child(_summary)


func _refresh() -> void:
	if report_data.is_empty():
		_title.text = "暂无战报"
		_summary.text = "完成一局战斗后，这里会显示胜负、MVP、星力来源、英雄贡献和战斗日志回放。"
		_clear_cards()
		_cards_root.add_child(_make_empty_card())
		return
	var outcome := str(report_data.get("outcome", "unknown"))
	var mvp_id := str(report_data.get("mvp", ""))
	var mvp_name := _hero_name(mvp_id)
	_title.text = "战报 - %s" % _outcome_text(outcome)
	var lines: Array[String] = []
	lines.append("[b]战斗结果[/b]")
	lines.append("胜负: %s" % _outcome_text(outcome))
	lines.append("回合数: %d" % int(report_data.get("round_number", 0)))
	lines.append("MVP: %s" % mvp_name)
	lines.append(_star_track_result_text())
	lines.append("MVP原因: %s" % _clean_report_text(str(report_data.get("mvp_reason", "综合贡献最高"))))
	lines.append("节奏: %s" % _clean_report_text(str(report_data.get("pace", ""))))
	lines.append("")
	lines.append("[b]阵营表现[/b]")
	lines.append(_array_lines(report_data.get("faction_performance_lines", [])))
	lines.append("星力来源:")
	lines.append(_array_lines(report_data.get("star_power_lines", [])))
	lines.append("技能触发:")
	lines.append(_array_lines(report_data.get("skill_trigger_lines", [])))
	lines.append("")
	lines.append("[b]英雄表现[/b]")
	lines.append(_array_lines(report_data.get("hero_contributions", [])))
	lines.append("")
	lines.append("[b]战斗日志回放[/b]")
	lines.append(_log_lines(report_data.get("battle_log", [])))
	_summary.text = "\n".join(lines)
	_refresh_cards(outcome, mvp_id, mvp_name)


func _refresh_cards(outcome: String, mvp_id: String, mvp_name: String) -> void:
	_clear_cards()
	_cards_root.add_child(_make_summary_card(outcome, mvp_id, mvp_name))
	_cards_root.add_child(_make_faction_card())
	_cards_root.add_child(_make_hero_card_list(mvp_id))
	_cards_root.add_child(_make_replay_card())


func _clear_cards() -> void:
	if _cards_root == null:
		return
	for child in _cards_root.get_children():
		child.queue_free()


func _make_empty_card() -> Control:
	var card := _make_card("EmptyReportCard", false)
	var body := card.get_node("CardMargin/CardBody")
	body.add_child(_make_label("完成一局战斗后，这里会显示可分享的战斗结果。", 26, Color(0.92, 0.91, 0.84, 1.0)))
	return card


func _make_summary_card(outcome: String, mvp_id: String, mvp_name: String) -> PanelContainer:
	var card := _make_card("SummaryCard", true)
	var body: VBoxContainer = card.get_node("CardMargin/CardBody")
	var top := HBoxContainer.new()
	top.name = "SummaryTopRow"
	top.add_theme_constant_override("separation", 18)
	body.add_child(top)

	var outcome_box := VBoxContainer.new()
	outcome_box.name = "OutcomeBlock"
	outcome_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(outcome_box)
	var outcome_color := Color(0.38, 0.93, 0.78, 1.0) if outcome == "left_wins" else Color(1.0, 0.42, 0.40, 1.0)
	outcome_box.add_child(_make_label(_outcome_text(outcome), 44, outcome_color, true))
	outcome_box.add_child(_make_label("回合数: %d    节奏: %s" % [
		int(report_data.get("round_number", 0)),
		_clean_report_text(str(report_data.get("pace", ""))),
	], 22, Color(0.78, 0.84, 0.95, 1.0)))
	var star_track_label := _make_label(_star_track_result_text(), 22, Color(1.0, 0.84, 0.36, 1.0), true)
	star_track_label.name = "StarTrackResult"
	outcome_box.add_child(star_track_label)

	var mvp_box := PanelContainer.new()
	mvp_box.name = "MvpHighlight"
	mvp_box.custom_minimum_size = Vector2(360, 112)
	mvp_box.add_theme_stylebox_override("panel", _card_style(true, Color(0.95, 0.73, 0.28, 0.96)))
	top.add_child(mvp_box)
	var mvp_margin := MarginContainer.new()
	mvp_margin.add_theme_constant_override("margin_left", 18)
	mvp_margin.add_theme_constant_override("margin_top", 12)
	mvp_margin.add_theme_constant_override("margin_right", 18)
	mvp_margin.add_theme_constant_override("margin_bottom", 12)
	mvp_box.add_child(mvp_margin)
	var mvp_body := VBoxContainer.new()
	mvp_body.name = "MvpBody"
	mvp_margin.add_child(mvp_body)
	mvp_body.add_child(_make_label("MVP", 18, Color(1.0, 0.86, 0.44, 1.0), true))
	mvp_body.add_child(_make_label(mvp_name, 34, Color(1.0, 0.95, 0.74, 1.0), true))
	mvp_body.add_child(_make_label(_clean_report_text(str(report_data.get("mvp_reason", "综合贡献最高"))), 17, Color(0.95, 0.91, 0.78, 1.0)))
	return card


func _make_faction_card() -> PanelContainer:
	var card := _make_card("FactionCard", false)
	var body: VBoxContainer = card.get_node("CardMargin/CardBody")
	body.add_child(_make_card_title("阵营表现", "星力 / 承伤 / 治疗按阵营汇总，击杀按双方统计"))

	var kill_row := HBoxContainer.new()
	kill_row.name = "KillComparisonRow"
	kill_row.add_theme_constant_override("separation", 12)
	body.add_child(kill_row)
	var kills: Dictionary = report_data.get("kills", {})
	kill_row.add_child(_make_metric_pill("我方击杀", int(kills.get("left", 0)), Color(0.27, 0.78, 0.95, 1.0)))
	kill_row.add_child(_make_metric_pill("敌方击杀", int(kills.get("right", 0)), Color(0.95, 0.34, 0.34, 1.0)))

	var grid := GridContainer.new()
	grid.name = "FactionGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	var faction_rows := _faction_rows()
	for faction_id in ["shu", "wei", "wu", "qun"]:
		grid.add_child(_make_faction_tile(faction_id, faction_rows.get(faction_id, {})))
	return card


func _make_hero_card_list(mvp_id: String) -> PanelContainer:
	var card := _make_card("HeroCardList", false)
	var body: VBoxContainer = card.get_node("CardMargin/CardBody")
	body.add_child(_make_card_title("英雄表现", "MVP置顶，其余按贡献排序"))
	var rows := _hero_rows_for_display(mvp_id)
	if rows.is_empty():
		body.add_child(_make_label("无英雄贡献数据", 20, Color(0.72, 0.77, 0.86, 1.0)))
		return card
	for row in rows:
		body.add_child(_make_hero_row(row, str(row.get("hero_id", "")) == mvp_id))
	return card


func _make_replay_card() -> PanelContainer:
	var card := _make_card("ReplayCard", false)
	var body: VBoxContainer = card.get_node("CardMargin/CardBody")
	body.add_child(_make_card_title("战斗日志回放", "最近关键事件"))
	var logs := _log_lines(report_data.get("battle_log", [])).split("\n")
	var count := 0
	for line in logs:
		if str(line).strip_edges().is_empty() or str(line) == "无":
			continue
		body.add_child(_make_label(str(line), 17, Color(0.76, 0.82, 0.92, 1.0)))
		count += 1
		if count >= 5:
			break
	if count == 0:
		body.add_child(_make_label("无", 18, Color(0.72, 0.77, 0.86, 1.0)))
	return card


func _make_card(node_name: String, highlighted: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _card_style(highlighted))
	var margin := MarginContainer.new()
	margin.name = "CardMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	var body := VBoxContainer.new()
	body.name = "CardBody"
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	return card


func _make_card_title(title: String, subtitle: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "%sTitleRow" % title
	row.add_theme_constant_override("separation", 14)
	var title_label := _make_label(title, 25, Color(1.0, 0.87, 0.52, 1.0), true)
	title_label.custom_minimum_size = Vector2(128, 0)
	row.add_child(title_label)
	var subtitle_label := _make_label(subtitle, 16, Color(0.62, 0.69, 0.82, 1.0))
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(subtitle_label)
	return row


func _make_metric_pill(label_text: String, value: int, color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "%sPill" % label_text
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_theme_stylebox_override("panel", _pill_style(color))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	pill.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var label := _make_label(label_text, 18, Color(0.80, 0.86, 0.95, 1.0))
	label.custom_minimum_size = Vector2(96, 0)
	row.add_child(label)
	var value_label := _make_label(str(value), 28, color, true)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_label)
	return pill


func _make_faction_tile(faction_id: String, row: Dictionary) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.name = "Faction_%s" % faction_id
	tile.add_theme_stylebox_override("panel", _tile_style(_faction_color(faction_id)))
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	tile.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	margin.add_child(body)
	body.add_child(_make_label(_faction_text(faction_id), 23, _faction_color(faction_id), true))
	body.add_child(_make_label("星力: %d" % int(row.get("energy", 0)), 17, Color(0.88, 0.90, 0.95, 1.0)))
	body.add_child(_make_label("承伤: %d" % int(row.get("taken", 0)), 17, Color(0.88, 0.90, 0.95, 1.0)))
	body.add_child(_make_label("治疗: %d" % int(row.get("healing", 0)), 17, Color(0.88, 0.90, 0.95, 1.0)))
	return tile


func _make_hero_row(row: Dictionary, is_mvp: bool) -> PanelContainer:
	var item := PanelContainer.new()
	item.name = "HeroRow_%s" % str(row.get("hero_id", "unknown"))
	item.add_theme_stylebox_override("panel", _hero_row_style(is_mvp))
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	item.add_child(margin)
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 12)
	margin.add_child(row_box)
	var name_text := "%s · %s" % [str(row.get("name", "未知")), _class_text(str(row.get("class", "")))]
	row_box.add_child(_make_label(name_text, 21, Color(1.0, 0.90, 0.62, 1.0) if is_mvp else Color(0.92, 0.94, 0.98, 1.0), is_mvp))
	var summary := _make_label(str(row.get("summary", "")), 18, Color(0.72, 0.80, 0.92, 1.0))
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row_box.add_child(summary)
	return item


func _make_label(text: String, font_size: int, color: Color, bold: bool = false, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return label


func _dict_lines(value) -> String:
	if not (value is Dictionary) or value.is_empty():
		return "无"
	var lines: Array[String] = []
	for key in value.keys():
		lines.append("%s: %s" % [_display_key_name(str(key)), str(value.get(key))])
	return "\n".join(lines)


func _array_lines(value) -> String:
	if not (value is Array) or value.is_empty():
		return "无"
	var lines: Array[String] = []
	for item in value:
		lines.append(_clean_report_text(str(item)))
	return "\n".join(lines)


func _log_lines(value) -> String:
	if not (value is Array) or value.is_empty():
		return "无"
	var lines: Array[String] = []
	var start := maxi(0, value.size() - 12)
	for index in range(start, value.size()):
		lines.append(_clean_report_text(str(value[index])))
	return "\n".join(lines)


func _star_track_result_text() -> String:
	var result: Dictionary = report_data.get("star_track_result", {})
	if result.is_empty():
		return "星轨: 未记录"
	var delta := int(result.get("delta", 0))
	var before: Dictionary = result.get("before", {})
	var after: Dictionary = result.get("after", {})
	var before_value := int(before.get("current_star_track_value", 0))
	var after_value := int(after.get("current_star_track_value", before_value + delta))
	var after_division: Dictionary = after.get("division", {})
	var division_name := str(after_division.get("name", after.get("current_star_track_division", "")))
	var sign := "+" if delta > 0 else ""
	if division_name.is_empty():
		return "星轨: %s%d (%d -> %d)" % [sign, delta, before_value, after_value]
	return "星轨: %s%d (%d -> %d) · %s" % [sign, delta, before_value, after_value, division_name]


func _hero_name(hero_id: String) -> String:
	if hero_id.is_empty() or hero_id == "暂未评定":
		return "暂未评定"
	var hero: Dictionary = HeroDataLoaderScript.hero_by_id(hero_id)
	return str(hero.get("name", hero_id))


func _display_key_name(key: String) -> String:
	var skill: Dictionary = SkillDataLoaderScript.skill_by_id(key)
	if not skill.is_empty():
		var owner_name := _hero_name(str(skill.get("owner_hero_id", "")))
		return "%s·%s" % [owner_name, str(skill.get("name", key))]
	if key == "left":
		return "我方"
	if key == "right":
		return "敌方"
	return _hero_name(key)


func _clean_report_text(text: String) -> String:
	var result := text
	for skill: Dictionary in SkillDataLoaderScript.all_skills():
		var skill_id := str(skill.get("id", ""))
		if not skill_id.is_empty():
			result = result.replace(skill_id, _display_key_name(skill_id))
	result = result.replace("：", ": ")
	result = result.replace("（", "(")
	result = result.replace("）", ")")
	result = result.replace("，", ", ")
	return result


func _faction_rows() -> Dictionary:
	var rows := {
		"shu": {"energy": 0, "taken": 0, "healing": 0},
		"wei": {"energy": 0, "taken": 0, "healing": 0},
		"wu": {"energy": 0, "taken": 0, "healing": 0},
		"qun": {"energy": 0, "taken": 0, "healing": 0},
	}
	var stats: Dictionary = report_data.get("raw", {}).get("stats", {})
	if stats.is_empty():
		stats = report_data.get("stats", {})
	_merge_faction_stat(rows, stats.get("faction_energy_heroes", {}), "energy")
	_merge_faction_stat(rows, stats.get("hero_damage_taken", {}), "taken")
	_merge_faction_stat(rows, stats.get("hero_healing_done", {}), "healing")
	return rows


func _merge_faction_stat(rows: Dictionary, values, field: String) -> void:
	if not (values is Dictionary):
		return
	for hero_id_value in values.keys():
		var hero_id := str(hero_id_value)
		var hero: Dictionary = HeroDataLoaderScript.hero_by_id(hero_id)
		var faction := str(hero.get("faction", ""))
		if not rows.has(faction):
			continue
		var row: Dictionary = rows[faction]
		row[field] = int(row.get(field, 0)) + int(values.get(hero_id_value, 0))
		rows[faction] = row


func _hero_rows_for_display(mvp_id: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var stats: Dictionary = report_data.get("raw", {}).get("stats", {})
	if stats.is_empty():
		stats = report_data.get("stats", {})
	var contribution_lines: Array = report_data.get("hero_contributions", [])
	for line_value in contribution_lines:
		var line := _clean_report_text(str(line_value))
		var hero_id := _hero_id_from_contribution(line)
		var hero: Dictionary = HeroDataLoaderScript.hero_by_id(hero_id)
		if hero.is_empty():
			continue
		var summary := line
		var prefix := "%s - " % str(hero.get("name", ""))
		if summary.begins_with(prefix):
			summary = summary.substr(prefix.length())
		var score := _hero_contribution_score(hero_id, stats)
		rows.append({
			"hero_id": hero_id,
			"name": str(hero.get("name", hero_id)),
			"class": str(hero.get("profession", hero.get("class", ""))),
			"summary": summary,
			"score": score,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_mvp := str(a.get("hero_id", "")) == mvp_id
		var b_mvp := str(b.get("hero_id", "")) == mvp_id
		if a_mvp != b_mvp:
			return a_mvp
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	return rows


func _hero_id_from_contribution(line: String) -> String:
	var hero_name := line.split(" - ")[0]
	for hero: Dictionary in HeroDataLoaderScript.all_heroes(false):
		if str(hero.get("name", "")) == hero_name:
			return str(hero.get("id", ""))
	return ""


func _hero_contribution_score(hero_id: String, stats: Dictionary) -> int:
	return int(stats.get("hero_damage_dealt", {}).get(hero_id, 0)) \
		+ int(stats.get("hero_damage_taken", {}).get(hero_id, 0)) \
		+ int(stats.get("hero_healing_done", {}).get(hero_id, 0)) \
		+ int(stats.get("faction_energy_heroes", {}).get(hero_id, 0)) * 2


func _faction_text(faction: String) -> String:
	match faction:
		"shu":
			return "蜀"
		"wei":
			return "魏"
		"wu":
			return "吴"
		"qun":
			return "群"
		_:
			return "未定"


func _class_text(class_id: String) -> String:
	match class_id:
		"mage":
			return "法师"
		"warrior":
			return "战士"
		"tank":
			return "坦克"
		"assassin":
			return "刺客"
		"archer":
			return "射手"
		_:
			return "职业"


func _faction_color(faction: String) -> Color:
	match faction:
		"shu":
			return Color(0.31, 0.82, 0.55, 1.0)
		"wei":
			return Color(0.40, 0.70, 1.0, 1.0)
		"wu":
			return Color(0.95, 0.38, 0.34, 1.0)
		"qun":
			return Color(0.82, 0.52, 1.0, 1.0)
		_:
			return Color(0.78, 0.78, 0.82, 1.0)


func _outcome_text(outcome: String) -> String:
	match outcome:
		"left_wins":
			return "我方胜利"
		"right_wins":
			return "敌方胜利"
		"both_failed":
			return "双方失败"
		_:
			return "未结算"


func _return_home() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.screen_changed.emit(HOME_SCREEN, {})


func _retry_battle() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.screen_changed.emit(BATTLE_SCREEN, {
			"player_deck": DeckDataManagerScript.load_player_deck(),
			"enemy_deck": DeckDataManagerScript.default_enemy_deck(),
		})


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
	style.content_margin_left = 20
	style.content_margin_top = 18
	style.content_margin_right = 20
	style.content_margin_bottom = 18
	return style


func _button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.16, 0.30, 0.94) if not active else Color(0.08, 0.24, 0.40, 0.98)
	style.border_color = Color(0.93, 0.74, 0.36, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style


func _card_style(highlighted: bool, border_color: Color = Color(0.86, 0.72, 0.38, 0.52)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.070, 0.145, 0.92) if not highlighted else Color(0.10, 0.095, 0.16, 0.96)
	style.border_color = border_color
	style.set_border_width_all(2 if not highlighted else 3)
	style.set_corner_radius_all(12)
	return style


func _tile_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r * 0.12, color.g * 0.12, color.b * 0.12, 0.70)
	style.border_color = Color(color.r, color.g, color.b, 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _pill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.052, 0.105, 0.88)
	style.border_color = Color(color.r, color.g, color.b, 0.56)
	style.set_border_width_all(1)
	style.set_corner_radius_all(999)
	return style


func _hero_row_style(is_mvp: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.075, 0.14, 0.74) if not is_mvp else Color(0.16, 0.13, 0.06, 0.88)
	style.border_color = Color(0.34, 0.45, 0.68, 0.35) if not is_mvp else Color(1.0, 0.76, 0.28, 0.82)
	style.set_border_width_all(1 if not is_mvp else 2)
	style.set_corner_radius_all(8)
	return style
