## Signal-driven battle visual feedback — no _process() polling.
## Connect to EventBus signals for attack/move/deploy/die flashes.
## Usage: BattleScreen creates this as a child node and calls setup().
extends Node
class_name BattleAnimator

const FLASH_DURATION: float = 0.3
const DIE_FLASH_DURATION: float = 0.5
const FLASH_COLOR_ATTACK := Color(1.0, 0.2, 0.2, 0.7)
const FLASH_COLOR_MOVE := Color(0.3, 0.6, 1.0, 0.6)
const FLASH_COLOR_DEPLOY := Color(0.3, 1.0, 0.3, 0.7)
const FLASH_COLOR_DIE := Color(1.0, 0.05, 0.05, 0.85)
const FLASH_COLOR_DAMAGE := Color(1.0, 0.5, 0.1, 0.6)
const HIT_STOP_DURATION := 0.06
const HIT_STOP_SCALE := 0.08
const CAMERA_SHAKE_ATTACK := 5.0
const CAMERA_SHAKE_SKILL := 10.0
const CAMERA_SHAKE_DEATH := 8.0
const NOTICE_DURATION := 0.72
const CORE_SKILL_HEROES := {
	"zhaoyun": true,
	"guanyu": true,
	"zhangfei": true,
	"lvbu": true,
	"zhugeliang": true,
	"caocao": true,
	"dianwei": true,
	"zhouyu": true,
	"sunce": true,
	"diaochan": true,
}

var _cell_buttons: Dictionary = {}
var _cell_key_to_unit_id: Callable = Callable()
var _unit_id_to_cell: Callable = Callable()
var _play_unit_pose: Callable = Callable()
var _feedback_root: Control
var _feedback_origin := Vector2.ZERO
var _shake_tween: Tween
var _time_scale_restore_pending: bool = false


func setup(cell_buttons: Dictionary, cell_key_to_unit_id: Callable, unit_id_to_cell: Callable, play_unit_pose: Callable = Callable(), feedback_root: Control = null) -> void:
	_cell_buttons = cell_buttons
	_cell_key_to_unit_id = cell_key_to_unit_id
	_unit_id_to_cell = unit_id_to_cell
	_play_unit_pose = play_unit_pose
	_feedback_root = feedback_root
	if _feedback_root != null:
		_feedback_origin = _feedback_root.position

	var eb := get_node("/root/EventBus")
	if eb == null:
		return
	eb.unit_attacked.connect(_on_unit_attacked)
	eb.unit_damaged.connect(_on_unit_damaged)
	eb.unit_died.connect(_on_unit_died)
	eb.unit_moved.connect(_on_unit_moved)
	eb.unit_deployed.connect(_on_unit_deployed)
	if eb.has_signal("side_turn_started"):
		eb.side_turn_started.connect(_on_side_turn_started)
	if eb.has_signal("turn_completed"):
		eb.turn_completed.connect(_on_turn_completed)
	if eb.has_signal("star_power_changed"):
		eb.star_power_changed.connect(_on_star_power_changed)
	if eb.has_signal("master_damaged"):
		eb.master_damaged.connect(_on_master_damaged)
	if eb.has_signal("unit_skill_triggered"):
		eb.unit_skill_triggered.connect(_on_unit_skill_triggered)


## EventBus signal: unit_attacked(attacker: Dictionary, target: Dictionary, damage: int)
func _on_unit_attacked(attacker: Dictionary, target: Dictionary, damage: int) -> void:
	_play_pose_by_unit(attacker, "attack")
	_flash_by_unit(attacker, FLASH_COLOR_ATTACK, FLASH_DURATION * 0.5)
	_flash_by_unit(target, FLASH_COLOR_ATTACK, FLASH_DURATION)
	_hit_stop()
	_shake_feedback(CAMERA_SHAKE_ATTACK, 0.10)


func _on_unit_skill_triggered(source_unit: Dictionary, skill_result: Dictionary) -> void:
	_play_pose_by_unit(source_unit, "skill")
	_spawn_skill_banner(source_unit, skill_result)
	_spawn_skill_fx(source_unit, skill_result)
	if _is_core_skill_hero(source_unit):
		_shake_feedback(CAMERA_SHAKE_SKILL, 0.16)


## EventBus signal: unit_damaged(unit: Dictionary, damage: int)
func _on_unit_damaged(unit: Dictionary, damage: int) -> void:
	_flash_by_unit(unit, FLASH_COLOR_DAMAGE, FLASH_DURATION * 0.6)
	_play_hit_by_unit(unit)
	_spawn_damage_number(unit, damage)


## EventBus signal: unit_died(unit: Dictionary)
func _on_unit_died(unit: Dictionary) -> void:
	_flash_by_unit(unit, FLASH_COLOR_DIE, DIE_FLASH_DURATION)
	_play_death_by_unit(unit)
	_spawn_death_feedback(unit)
	_shake_feedback(CAMERA_SHAKE_DEATH, 0.14)


## EventBus signal: unit_moved(unit: Dictionary, target_column: int, target_row: int)
func _on_unit_moved(unit: Dictionary, target_column: int, target_row: int) -> void:
	var unit_id := str(unit.get("instance_id", ""))
	var old_cell_key: String = _resolve_cell_key(unit_id)
	if old_cell_key != "":
		_flash_cell(old_cell_key, FLASH_COLOR_MOVE, FLASH_DURATION)
	var new_cell_key := "%d,%d" % [target_column, target_row]
	_flash_cell(new_cell_key, FLASH_COLOR_MOVE, FLASH_DURATION)


## EventBus signal: unit_deployed(unit: Dictionary, side: String, cost: int)
func _on_unit_deployed(unit: Dictionary, side: String, cost: int) -> void:
	var col := int(unit.get("column", 0))
	var row := int(unit.get("row", 0))
	var cell_key := "%d,%d" % [col, row]
	_flash_cell(cell_key, FLASH_COLOR_DEPLOY, FLASH_DURATION * 1.2)
	_spawn_cell_notice(cell_key, "登场 -%d" % cost, Color(0.64, 0.95, 1.0, 1.0), 0.42)


func _on_side_turn_started(side: String, turn_info: Dictionary) -> void:
	var restore := int(turn_info.get("star_restore", 0))
	var turn_number := int(turn_info.get("turn_number", 0))
	var text := "%s行动  第%d回合  星力+%d" % [_side_label(side), turn_number, restore]
	_spawn_screen_notice(text, Color(0.64, 0.90, 1.0, 1.0))


func _on_turn_completed(turn_number: int) -> void:
	_spawn_screen_notice("回合推进：第%d回合" % turn_number, Color(1.0, 0.86, 0.45, 1.0))


func _on_star_power_changed(side: String, amount: int) -> void:
	if amount == 0:
		return
	var prefix := "+" if amount > 0 else ""
	var color := Color(0.52, 0.92, 1.0, 1.0) if amount > 0 else Color(1.0, 0.72, 0.46, 1.0)
	_spawn_screen_notice("%s星力 %s%d" % [_side_label(side), prefix, amount], color)


func _on_master_damaged(side: String, damage: int, remaining_hp: int) -> void:
	if damage <= 0:
		return
	_spawn_screen_notice("%s弈星师 -%d  HP %d" % [_side_label(side), damage, remaining_hp], Color(1.0, 0.48, 0.36, 1.0))
	_shake_feedback(CAMERA_SHAKE_SKILL, 0.12)


func _resolve_cell_key(unit_id: String) -> String:
	if _unit_id_to_cell.is_valid():
		return str(_unit_id_to_cell.call(unit_id))
	return ""


func _flash_by_unit(unit: Dictionary, color: Color, duration: float) -> void:
	var unit_id := str(unit.get("instance_id", ""))
	var cell_key: String = _resolve_cell_key(unit_id)
	if cell_key != "":
		_flash_cell(cell_key, color, duration)


func _play_pose_by_unit(unit: Dictionary, pose: String) -> void:
	if not _play_unit_pose.is_valid():
		return
	var unit_id := str(unit.get("instance_id", ""))
	if unit_id.is_empty():
		return
	_play_unit_pose.call(unit_id, pose)


func _play_hit_by_unit(unit: Dictionary) -> void:
	var sprite := _sprite_for_unit(unit)
	if sprite != null and sprite.has_method("play_hit"):
		sprite.play_hit()


func _play_death_by_unit(unit: Dictionary) -> void:
	var sprite := _sprite_for_unit(unit)
	if sprite != null and sprite.has_method("play_death"):
		sprite.play_death()


func _sprite_for_unit(unit: Dictionary) -> Control:
	var cell_key: String = _resolve_cell_key(str(unit.get("instance_id", "")))
	if cell_key.is_empty() or not _cell_buttons.has(cell_key):
		return null
	var button: Button = _cell_buttons[cell_key] as Button
	if button == null or not is_instance_valid(button):
		return null
	return button.get_node_or_null("HeroBattleSprite") as Control


func _flash_cell(cell_key: String, color: Color, duration: float) -> void:
	if not _cell_buttons.has(cell_key):
		return
	var button: Button = _cell_buttons[cell_key] as Button
	if button == null or not is_instance_valid(button):
		return

	var flash_style := StyleBoxFlat.new()
	flash_style.bg_color = color
	button.add_theme_stylebox_override("normal", flash_style)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration)
	tween.tween_callback(_restore_cell_style.bind(button))


func _spawn_damage_number(unit: Dictionary, damage: int) -> void:
	if damage <= 0:
		return
	var button := _button_for_unit(unit)
	if button == null:
		return
	var label := Label.new()
	label.name = "DamageFloat"
	label.text = "-%d" % damage
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.25, 0.03, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	button.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 34.0, 0.46)
	tween.tween_property(label, "modulate:a", 0.0, 0.46)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _spawn_skill_banner(source_unit: Dictionary, skill_result: Dictionary) -> void:
	var button := _button_for_unit(source_unit)
	if button == null:
		return
	var label := Label.new()
	label.name = "SkillNameBanner"
	label.text = str(skill_result.get("skill_name", skill_result.get("skill_id", "技能")))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = -0.35
	label.anchor_right = 1.35
	label.anchor_top = -0.38
	label.anchor_bottom = 0.02
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.89, 0.48, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.10, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	button.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 18.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.16)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _spawn_skill_fx(source_unit: Dictionary, skill_result: Dictionary) -> void:
	var button := _button_for_unit(source_unit)
	if button == null:
		return
	var fx := ColorRect.new()
	fx.name = "SkillFxPlaceholder"
	fx.color = _fx_color_for_skill(skill_result)
	fx.anchor_left = 0.16
	fx.anchor_right = 0.84
	fx.anchor_top = 0.10
	fx.anchor_bottom = 0.78
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(fx)
	fx.scale = Vector2(0.70, 0.70)
	fx.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "scale", Vector2(1.20, 1.20), 0.32)
	tween.tween_property(fx, "modulate:a", 0.0, 0.32)
	tween.set_parallel(false)
	tween.tween_callback(fx.queue_free)


func _spawn_death_feedback(unit: Dictionary) -> void:
	var button := _button_for_unit(unit)
	if button == null:
		return
	var label := Label.new()
	label.name = "DefeatFloat"
	label.text = "破阵"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = -0.20
	label.anchor_right = 1.20
	label.anchor_top = 0.18
	label.anchor_bottom = 0.82
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.30, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.10, 0.00, 0.00, 1.0))
	label.add_theme_constant_override("outline_size", 5)
	button.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42).set_delay(0.12)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _spawn_cell_notice(cell_key: String, text: String, color: Color, duration: float = NOTICE_DURATION) -> void:
	if not _cell_buttons.has(cell_key):
		return
	var button := _cell_buttons[cell_key] as Button
	if button == null or not is_instance_valid(button):
		return
	var label := Label.new()
	label.name = "CellFeelNotice"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = -0.18
	label.anchor_right = 1.18
	label.anchor_top = -0.20
	label.anchor_bottom = 0.30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.06, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	button.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 16.0, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.45)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _spawn_screen_notice(text: String, color: Color, duration: float = NOTICE_DURATION) -> void:
	if _feedback_root == null or not is_instance_valid(_feedback_root):
		return
	var label := Label.new()
	label.name = "BattleFeelNotice"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.12
	label.anchor_right = 0.88
	label.anchor_top = -0.10
	label.anchor_bottom = 0.02
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 1.0))
	label.add_theme_constant_override("outline_size", 5)
	_feedback_root.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 22.0, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.48)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _fx_color_for_skill(skill_result: Dictionary) -> Color:
	match str(skill_result.get("effect_type", "")):
		"heal":
			return Color(0.24, 0.95, 0.62, 0.34)
		"shield", "attack_buff":
			return Color(0.42, 0.78, 1.0, 0.34)
		"stun", "slow":
			return Color(0.75, 0.55, 1.0, 0.34)
		"area_damage":
			return Color(1.0, 0.38, 0.16, 0.34)
		_:
			return Color(1.0, 0.82, 0.20, 0.34)


func _button_for_unit(unit: Dictionary) -> Button:
	var cell_key: String = _resolve_cell_key(str(unit.get("instance_id", "")))
	if cell_key.is_empty() or not _cell_buttons.has(cell_key):
		return null
	var button := _cell_buttons[cell_key] as Button
	if button == null or not is_instance_valid(button):
		return null
	return button


func _is_core_skill_hero(unit: Dictionary) -> bool:
	return CORE_SKILL_HEROES.has(str(unit.get("hero_id", "")))


func _side_label(side: String) -> String:
	return "我方" if side == "left" else "敌方"


func _hit_stop() -> void:
	if _time_scale_restore_pending:
		return
	_time_scale_restore_pending = true
	Engine.time_scale = HIT_STOP_SCALE
	var timer := get_tree().create_timer(HIT_STOP_DURATION, true, false, true)
	timer.timeout.connect(_restore_time_scale)


func _restore_time_scale() -> void:
	Engine.time_scale = 1.0
	_time_scale_restore_pending = false


func _shake_feedback(strength: float, duration: float) -> void:
	if _feedback_root == null or not is_instance_valid(_feedback_root):
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_feedback_root.position = _feedback_origin
	_shake_tween = create_tween()
	_shake_tween.tween_property(_feedback_root, "position", _feedback_origin + Vector2(strength, -strength * 0.35), duration * 0.24)
	_shake_tween.tween_property(_feedback_root, "position", _feedback_origin + Vector2(-strength * 0.65, strength * 0.28), duration * 0.24)
	_shake_tween.tween_property(_feedback_root, "position", _feedback_origin + Vector2(strength * 0.35, strength * 0.18), duration * 0.20)
	_shake_tween.tween_property(_feedback_root, "position", _feedback_origin, duration * 0.32)


func _restore_cell_style(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.remove_theme_stylebox_override("normal")


func _exit_tree() -> void:
	var eb := get_node("/root/EventBus")
	if eb == null:
		_cell_buttons.clear()
		return

	if eb.has_signal("unit_attacked") and eb.unit_attacked.is_connected(_on_unit_attacked):
		eb.unit_attacked.disconnect(_on_unit_attacked)
	if eb.has_signal("unit_damaged") and eb.unit_damaged.is_connected(_on_unit_damaged):
		eb.unit_damaged.disconnect(_on_unit_damaged)
	if eb.has_signal("unit_died") and eb.unit_died.is_connected(_on_unit_died):
		eb.unit_died.disconnect(_on_unit_died)
	if eb.has_signal("unit_moved") and eb.unit_moved.is_connected(_on_unit_moved):
		eb.unit_moved.disconnect(_on_unit_moved)
	if eb.has_signal("unit_deployed") and eb.unit_deployed.is_connected(_on_unit_deployed):
		eb.unit_deployed.disconnect(_on_unit_deployed)
	if eb.has_signal("side_turn_started") and eb.side_turn_started.is_connected(_on_side_turn_started):
		eb.side_turn_started.disconnect(_on_side_turn_started)
	if eb.has_signal("turn_completed") and eb.turn_completed.is_connected(_on_turn_completed):
		eb.turn_completed.disconnect(_on_turn_completed)
	if eb.has_signal("star_power_changed") and eb.star_power_changed.is_connected(_on_star_power_changed):
		eb.star_power_changed.disconnect(_on_star_power_changed)
	if eb.has_signal("master_damaged") and eb.master_damaged.is_connected(_on_master_damaged):
		eb.master_damaged.disconnect(_on_master_damaged)
	if eb.has_signal("unit_skill_triggered") and eb.unit_skill_triggered.is_connected(_on_unit_skill_triggered):
		eb.unit_skill_triggered.disconnect(_on_unit_skill_triggered)

	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	if _feedback_root != null and is_instance_valid(_feedback_root):
		_feedback_root.position = _feedback_origin
	if _time_scale_restore_pending:
		_restore_time_scale()
	_cell_buttons.clear()
