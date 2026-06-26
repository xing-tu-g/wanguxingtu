class_name ResultScreen
extends Control

## Displays battle results, rewards, and unit stats after a match ends.
## Navigates back to home via EventBus — no parent dependency.

const HOME_SCREEN := "res://scenes/ui/HomeScreen.tscn"
const FontScaleScript: GDScript = preload("res://scripts/ui/theme/FontScale.gd")

# ── Cached child nodes ────────────────────────────────────────────────

@onready var _home_button: Button = $Margin/Layout/HomeButton
@onready var _title_label: Label = $Margin/Layout/Title
@onready var _body_label: Label = $Margin/Layout/Body
@onready var _app_state: Node = get_node("/root/AppState")

# ── State ─────────────────────────────────────────────────────────────

var result_data: Dictionary = {}

## Cached outcome string — computed once in set_result().
var _outcome: String = "unknown"


func _ready() -> void:
	if not _home_button.pressed.is_connected(_return_home):
		_home_button.pressed.connect(_return_home)
	_apply_font_scale()
	_refresh()


## Called by ScreenRouter when this screen is shown with battle result data.
func set_result(new_result_data: Dictionary) -> void:
	result_data = new_result_data.duplicate(true)
	_outcome = str(result_data.get("outcome", "unknown"))
	_apply_battle_rewards()
	_apply_font_scale()
	_refresh()


# ── Style ─────────────────────────────────────────────────────────────

func _apply_font_scale() -> void:
	var vw := get_viewport_rect().size.x
	_title_label.add_theme_font_size_override(&"font_size", FontScaleScript.title_size(vw) - 4)
	_body_label.add_theme_font_size_override(&"font_size", FontScaleScript.body_size(vw))


# ── Rewards ───────────────────────────────────────────────────────────

func _apply_battle_rewards() -> void:
	_app_state.record_battle()
	match _outcome:
		"left_wins":
			_app_state.earn_gold(_gold_reward(true))
			_app_state.earn_star_stone(1)
		"right_wins", "both_failed":
			_app_state.earn_gold(_gold_reward(false))
		_:
			pass


func _gold_reward(is_win: bool) -> int:
	if is_win:
		return 50 + _app_state.master_level * 10
	return 15 + _app_state.master_level * 3


func _star_stone_reward() -> int:
	return 1 if _outcome == "left_wins" else 0


# ── Display ───────────────────────────────────────────────────────────

func _refresh() -> void:
	var stats: Dictionary = result_data.get("stats", {})

	_title_label.text = _format_outcome()

	var lines: Array[String] = [
		"战斗结果：%s" % _format_outcome(),
		"结束回合：第 %d 回合" % int(result_data.get("round_number", 0)),
		"我方奕星师 HP：%d" % int(result_data.get("left_hp", 0)),
		"敌方奕星师 HP：%d" % int(result_data.get("right_hp", 0)),
		"我方存活单位：%d" % int(result_data.get("left_survivors", 0)),
		"敌方存活单位：%d" % int(result_data.get("right_survivors", 0)),
		"我方部署 / 击破：%d / %d" % [_stat_value(stats, "deployments", "left"),
			_stat_value(stats, "units_defeated", "left")],
		"敌方部署 / 击破：%d / %d" % [_stat_value(stats, "deployments", "right"),
			_stat_value(stats, "units_defeated", "right")],
		"我方单位/奕星师伤害：%d / %d" % [_stat_value(stats, "unit_damage_dealt", "left"),
			_stat_value(stats, "master_damage_dealt", "left")],
		"敌方单位/奕星师伤害：%d / %d" % [_stat_value(stats, "unit_damage_dealt", "right"),
			_stat_value(stats, "master_damage_dealt", "right")],
		"",
		"[b]战利品[/b]：金币 +%d  星石 +%d  总战斗 %d" % [
			_gold_reward(_outcome == "left_wins"),
			_star_stone_reward(),
			_app_state.battles_fought,
		],
		"",
		"本场最佳武将：MVP 阶段暂不评选",
		"下一步：返回首页后可重新开局，继续测试不同部署。",
	]
	_body_label.text = "\n".join(lines)


func _stat_value(stats: Dictionary, section: String, side: String) -> int:
	var section_data: Variant = stats.get(section, {})
	if section_data is Dictionary:
		return int(section_data.get(side, 0))
	return 0


func _format_outcome() -> String:
	match _outcome:
		"left_wins":
			return "我方胜利"
		"right_wins":
			return "敌方胜利"
		"both_failed":
			return "双方失败"
		_:
			return "战斗结算"


# ── Navigation ────────────────────────────────────────────────────────

## Emits screen_changed through EventBus — no parent coupling.
func _return_home() -> void:
	var bus := _get_event_bus()
	if bus != null:
		bus.screen_changed.emit(HOME_SCREEN)


func _get_event_bus() -> Node:
	# get_node("/root/...") works on all platforms including Android,
	# unlike Engine.get_singleton() which can return null on mobile.
	return get_node_or_null("/root/EventBus")
