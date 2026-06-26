class_name BattleLogView
extends Node

## Emitted when collapsed state changes (toggle / close).
signal visibility_changed(collapsed: bool)

const DEFAULT_MAX_LINES := 20
const DEFAULT_MAX_RESULT_CHARS := 44

var entries: Array[String] = []
var collapsed := true
var max_lines := DEFAULT_MAX_LINES
var max_result_chars := DEFAULT_MAX_RESULT_CHARS
var log_panel: PanelContainer
var log_text: TextEdit
var toggle_button: Button


func setup(panel: PanelContainer, text_edit: TextEdit, toggle_control: Button, close_button: Button) -> void:
	log_panel = panel
	log_text = text_edit
	toggle_button = toggle_control
	if toggle_button != null and not toggle_button.pressed.is_connected(toggle):
		toggle_button.pressed.connect(toggle)
	if close_button != null and not close_button.pressed.is_connected(close):
		close_button.pressed.connect(close)
	update_visibility()


func add(turn_number: int, actor: String, action: String, result: String) -> void:
	entries.append("R%d - %s - %s - %s" % [
		turn_number,
		actor,
		action,
		compact_result(result),
	])
	while entries.size() > max_lines:
		entries.pop_front()
	refresh()


func refresh() -> void:
	if log_text != null:
		log_text.text = "\n".join(entries)
		log_text.scroll_vertical = max(0, log_text.get_line_count() - 1)


func toggle() -> void:
	collapsed = not collapsed
	update_visibility()
	visibility_changed.emit(collapsed)


func close() -> void:
	collapsed = true
	update_visibility()
	visibility_changed.emit(collapsed)


func update_visibility() -> void:
	if log_panel != null:
		log_panel.visible = not collapsed
	if toggle_button != null:
		toggle_button.text = "战报" if collapsed else "收起战报"


func compact_result(result: String) -> String:
	var compact := result
	compact = compact.replace("当前点到 ", "点到")
	compact = compact.replace("这里不是我方蓝色部署区", "非蓝区")
	compact = compact.replace("请把", "放")
	compact = compact.replace("放到左侧 1-3 列的空格", "->蓝区1-3列")
	compact = compact.replace("左侧蓝色部署区", "蓝区")
	compact = compact.replace("星力不足：", "星力不足 ")
	compact = compact.replace("当前只有", "现")
	compact = compact.replace("可先点「推进回合」恢复星力，或改选低费手牌", "点推进回星/换低费")
	compact = compact.replace("从 ", "")
	compact = compact.replace(" 移动到 ", "->")
	compact = compact.replace("，步数 ", " 步")
	compact = compact.replace("攻击弈星师，造成 ", "打主公 ")
	compact = compact.replace("攻击 ", "打")
	compact = compact.replace("，造成 ", " ")
	compact = compact.replace(" 点伤害", "伤")
	compact = compact.replace("；", " ")
	compact = compact.replace("。", "")
	compact = compact.replace("，", " ")
	compact = compact.replace(";", " ")
	while compact.find("  ") >= 0:
		compact = compact.replace("  ", " ")
	compact = compact.strip_edges()
	if compact.length() > max_result_chars:
		compact = compact.substr(0, max_result_chars - 1) + "\u2026"
	return compact
