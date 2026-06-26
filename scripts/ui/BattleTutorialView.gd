extends RefCounted
class_name BattleTutorialView

var first_deploy_hint_dismissed := false
var tutorial_turn_advanced := false
var deploy_failure_toast_time_left := 0.0
var deploy_failure_toast_duration := 2.8
var deploy_failure_toast_fade_duration := 0.8

var tutorial_progress_label: Label
var tutorial_step_select_label: Label
var tutorial_step_deploy_label: Label
var tutorial_step_turn_label: Label
var first_deploy_hint_panel: PanelContainer
var first_deploy_hint_body: Label
var deploy_failure_toast_panel: PanelContainer
var deploy_failure_toast_label: Label
var callbacks: Dictionary = {}


func setup(
	progress_label: Label,
	select_label: Label,
	deploy_label: Label,
	turn_label: Label,
	hint_panel: PanelContainer,
	hint_body: Label,
	hint_button: Button,
	toast_panel: PanelContainer,
	toast_label: Label,
	tutorial_callbacks: Dictionary
) -> void:
	tutorial_progress_label = progress_label
	tutorial_step_select_label = select_label
	tutorial_step_deploy_label = deploy_label
	tutorial_step_turn_label = turn_label
	first_deploy_hint_panel = hint_panel
	first_deploy_hint_body = hint_body
	deploy_failure_toast_panel = toast_panel
	deploy_failure_toast_label = toast_label
	callbacks = tutorial_callbacks
	if hint_button != null and not hint_button.pressed.is_connected(dismiss_first_deploy_hint):
		hint_button.pressed.connect(dismiss_first_deploy_hint)


func process(delta: float) -> void:
	if deploy_failure_toast_panel == null or not deploy_failure_toast_panel.visible:
		return
	deploy_failure_toast_time_left = maxf(0.0, deploy_failure_toast_time_left - delta)
	var fade_ratio := 1.0
	if deploy_failure_toast_fade_duration > 0.0:
		fade_ratio = clampf(deploy_failure_toast_time_left / deploy_failure_toast_fade_duration, 0.0, 1.0)
	deploy_failure_toast_panel.modulate.a = fade_ratio if deploy_failure_toast_time_left < deploy_failure_toast_fade_duration else 1.0
	if deploy_failure_toast_time_left <= 0.0:
		hide_deploy_failure_toast()


func dismiss_first_deploy_hint() -> void:
	first_deploy_hint_dismissed = true
	update_first_deploy_hint()
	_emit_changed()


func update_first_deploy_hint() -> void:
	if first_deploy_hint_panel == null:
		return
	var should_show: bool = not first_deploy_hint_dismissed and bool(_call("has_no_player_units"))
	first_deploy_hint_panel.visible = should_show
	if not should_show:
		return
	if first_deploy_hint_body == null:
		return


func update_tutorial_progress() -> void:
	if tutorial_progress_label == null:
		return
	tutorial_progress_label.text = "新手流程"
	_update_tutorial_step_label(tutorial_step_select_label, "选牌", bool(_call("has_selected_card")))
	_update_tutorial_step_label(tutorial_step_deploy_label, "点推荐格", bool(_call("has_player_unit")))
	_update_tutorial_step_label(tutorial_step_turn_label, "推进回合", tutorial_turn_advanced)


func apply_progress_row_style() -> void:
	_apply_tutorial_step_style(tutorial_progress_label, false, true)
	_apply_tutorial_step_style(tutorial_step_select_label, false)
	_apply_tutorial_step_style(tutorial_step_deploy_label, false)
	_apply_tutorial_step_style(tutorial_step_turn_label, false)


func show_deploy_failure_toast(reason: String) -> void:
	if deploy_failure_toast_panel == null or deploy_failure_toast_label == null:
		return
	if not _should_activate_deploy_failure_highlight(reason):
		hide_deploy_failure_toast()
		return
	deploy_failure_toast_label.text = "金边格就是当前可部署位置｜请点左侧蓝色部署区空格"
	deploy_failure_toast_time_left = deploy_failure_toast_duration
	deploy_failure_toast_panel.modulate.a = 1.0
	deploy_failure_toast_panel.visible = true


func hide_deploy_failure_toast() -> void:
	deploy_failure_toast_time_left = 0.0
	if deploy_failure_toast_panel != null:
		deploy_failure_toast_panel.visible = false
		deploy_failure_toast_panel.modulate.a = 1.0


func _update_tutorial_step_label(label: Label, text: String, done: bool) -> void:
	if label == null:
		return
	label.text = "%s %s" % [_step_marker(done), text]
	_apply_tutorial_step_style(label, done)


func _apply_tutorial_step_style(label: Label, done: bool, title: bool = false) -> void:
	if label == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.10, 0.20, 0.92) if title else (Color(0.11, 0.27, 0.22, 0.94) if done else Color(0.07, 0.09, 0.16, 0.90))
	style.border_color = Color(0.70, 0.86, 1.0, 0.82) if title else (Color(0.42, 1.0, 0.76, 0.92) if done else Color(0.46, 0.56, 0.72, 0.76))
	style.set_border_width_all(3 if done else 2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", Color(0.98, 1.0, 0.92, 1.0) if done else Color(0.84, 0.90, 1.0, 1.0))


func _step_marker(done: bool) -> String:
	return "✓" if done else "○"


func _should_activate_deploy_failure_highlight(reason: String) -> bool:
	return [
		"not_deployment_zone",
		"not_own_deployment_zone",
		"cell_occupied",
		"not_enough_star_power",
		"unknown_hero",
	].has(reason)


func _call_string(callback_name: String, args: Array = []) -> String:
	return str(_call(callback_name, args))


func _call(callback_name: String, args: Array = []) -> Variant:
	var callback: Callable = callbacks.get(callback_name, Callable())
	if callback.is_valid():
		return callback.callv(args)
	return false


func _emit_changed() -> void:
	var callback: Callable = callbacks.get("changed", Callable())
	if callback.is_valid():
		callback.call()
