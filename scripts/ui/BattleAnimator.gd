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

var _cell_buttons: Dictionary = {}
var _cell_key_to_unit_id: Callable = Callable()
var _unit_id_to_cell: Callable = Callable()


func setup(cell_buttons: Dictionary, cell_key_to_unit_id: Callable, unit_id_to_cell: Callable) -> void:
	_cell_buttons = cell_buttons
	_cell_key_to_unit_id = cell_key_to_unit_id
	_unit_id_to_cell = unit_id_to_cell

	var eb := get_node("/root/EventBus")
	if eb == null:
		return
	eb.unit_attacked.connect(_on_unit_attacked)
	eb.unit_damaged.connect(_on_unit_damaged)
	eb.unit_died.connect(_on_unit_died)
	eb.unit_moved.connect(_on_unit_moved)
	eb.unit_deployed.connect(_on_unit_deployed)


## EventBus signal: unit_attacked(attacker: Dictionary, target: Dictionary, damage: int)
func _on_unit_attacked(attacker: Dictionary, target: Dictionary, damage: int) -> void:
	_flash_by_unit(attacker, FLASH_COLOR_ATTACK, FLASH_DURATION * 0.5)
	_flash_by_unit(target, FLASH_COLOR_ATTACK, FLASH_DURATION)


## EventBus signal: unit_damaged(unit: Dictionary, damage: int)
func _on_unit_damaged(unit: Dictionary, damage: int) -> void:
	_flash_by_unit(unit, FLASH_COLOR_DAMAGE, FLASH_DURATION * 0.6)


## EventBus signal: unit_died(unit: Dictionary)
func _on_unit_died(unit: Dictionary) -> void:
	_flash_by_unit(unit, FLASH_COLOR_DIE, DIE_FLASH_DURATION)


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


func _resolve_cell_key(unit_id: String) -> String:
	if _unit_id_to_cell.is_valid():
		return str(_unit_id_to_cell.call(unit_id))
	return ""


func _flash_by_unit(unit: Dictionary, color: Color, duration: float) -> void:
	var unit_id := str(unit.get("instance_id", ""))
	var cell_key: String = _resolve_cell_key(unit_id)
	if cell_key != "":
		_flash_cell(cell_key, color, duration)


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

	_cell_buttons.clear()
