class_name CardZoneView
extends Node

## Emitted when collapsed state changes (toggle / close).
signal visibility_changed(collapsed: bool)

## Emitted when user selects a card for inspection.
signal card_selected(hero_id: String)

## Emitted on any structural refresh that may affect overlay dismiss visibility.
signal changed

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"

var collapsed := true
var selected_card_hero_id := ""

var card_zone_label: Label
var toggle_button: Button
var summary_label: Label
var drawer_panel: PanelContainer
var detail_label: RichTextLabel
var scroll: ScrollContainer
var cards_container: VBoxContainer
var inspect_label: RichTextLabel

var callbacks: Dictionary = {}
var player_hand: Array = []
var player_discard: Array = []
var enemy_hand: Array = []
var enemy_discard: Array = []

# ── Animation state ──
var _drawer_tween: Tween


func setup(
	zone_label: Label,
	toggle_control: Button,
	summary_control: Label,
	drawer_control: PanelContainer,
	close_button: Button,
	detail_control: RichTextLabel,
	scroll_control: ScrollContainer,
	cards_control: VBoxContainer,
	inspect_control: RichTextLabel,
	view_callbacks: Dictionary
) -> void:
	card_zone_label = zone_label
	toggle_button = toggle_control
	summary_label = summary_control
	drawer_panel = drawer_control
	detail_label = detail_control
	scroll = scroll_control
	cards_container = cards_control
	inspect_label = inspect_control
	callbacks = view_callbacks
	if toggle_button != null and not toggle_button.pressed.is_connected(toggle):
		toggle_button.pressed.connect(toggle)
	if close_button != null and not close_button.pressed.is_connected(close):
		close_button.pressed.connect(close)
	refresh()


func set_piles(new_player_hand: Array, new_player_discard: Array, new_enemy_hand: Array, new_enemy_discard: Array) -> void:
	player_hand = new_player_hand
	player_discard = new_player_discard
	enemy_hand = new_enemy_hand
	enemy_discard = new_enemy_discard


func refresh() -> void:
	if card_zone_label == null:
		return
	card_zone_label.text = "%s - %s" % [
		_call_string("format_zone_for_side", [SIDE_LEFT]),
		_call_string("format_zone_for_side", [SIDE_RIGHT]),
	]
	if summary_label != null:
		summary_label.text = card_zone_label.text
	if detail_label != null:
		detail_label.text = _call_string("format_detail")
	update_visibility()
	refresh_cards()
	refresh_inspect_label()


func toggle() -> void:
	collapsed = not collapsed
	refresh()
	changed.emit()


func close() -> void:
	collapsed = true
	refresh()
	changed.emit()


## Applies visibility + tween animation on the drawer panel.
func update_visibility() -> void:
	if drawer_panel == null:
		return

	if toggle_button != null:
		toggle_button.text = "展开牌区" if collapsed else "收起牌区"

	if collapsed:
		_animate_drawer_close()
	else:
		_animate_drawer_open()

	# Non-drawer elements toggle instantly
	if detail_label != null:
		detail_label.visible = not collapsed
	if scroll != null:
		scroll.visible = not collapsed
	if inspect_label != null:
		inspect_label.visible = not collapsed


func _animate_drawer_open() -> void:
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()
	_drawer_tween = create_tween()
	_drawer_tween.set_parallel(true)
	drawer_panel.visible = true
	drawer_panel.modulate.a = 0.0
	drawer_panel.position.y -= 18.0
	_drawer_tween.tween_property(drawer_panel, "modulate:a", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	_drawer_tween.tween_property(drawer_panel, "position:y", drawer_panel.position.y + 18.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	visibility_changed.emit(false)


func _animate_drawer_close() -> void:
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()
	_drawer_tween = create_tween()
	_drawer_tween.set_parallel(true)
	_drawer_tween.tween_property(drawer_panel, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	_drawer_tween.tween_property(drawer_panel, "position:y", drawer_panel.position.y - 18.0, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_drawer_tween.tween_callback(func():
		drawer_panel.visible = false
		drawer_panel.position.y += 18.0  # restore position for next open
	)
	visibility_changed.emit(true)


func refresh_cards() -> void:
	if cards_container == null:
		return
	for child in cards_container.get_children():
		child.queue_free()
	_add_card_zone_row("我方手牌", player_hand)
	_add_card_zone_row("我方弃牌", player_discard)
	_add_card_zone_row("敌方手牌", enemy_hand)
	_add_card_zone_row("敌方弃牌", enemy_discard)
	if selected_card_hero_id.is_empty() or _hero_id_not_in_visible_card_zones(selected_card_hero_id):
		selected_card_hero_id = _first_visible_card_id()


func refresh_inspect_label() -> void:
	if inspect_label == null:
		return
	if selected_card_hero_id.is_empty():
		inspect_label.text = "[b]牌面说明[/b]：暂无可查看卡牌。"
		return
	inspect_label.text = _call_string("format_inspect", [selected_card_hero_id])


func select_card_for_inspect(hero_id: String) -> void:
	selected_card_hero_id = hero_id
	refresh()
	card_selected.emit(hero_id)
	changed.emit()


func _add_card_zone_row(title: String, hero_ids: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	cards_container.add_child(row)
	var title_label := Label.new()
	title_label.custom_minimum_size = Vector2(96, 40)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.text = title
	row.add_child(title_label)
	if hero_ids.is_empty():
		var empty_label := Label.new()
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.text = "无"
		row.add_child(empty_label)
		return
	for hero_id_value in hero_ids:
		var hero_id := str(hero_id_value)
		var card_button := Button.new()
		card_button.custom_minimum_size = Vector2(188, 72)
		card_button.focus_mode = Control.FOCUS_NONE
		card_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card_button.text = _call_string("format_button_text", [hero_id])
		card_button.tooltip_text = _call_string("format_tooltip", [hero_id])
		_call("apply_button_style", [card_button, hero_id, hero_id == selected_card_hero_id])
		if hero_id == selected_card_hero_id:
			card_button.text = "> %s" % card_button.text
		card_button.pressed.connect(select_card_for_inspect.bind(hero_id))
		row.add_child(card_button)


func _hero_id_not_in_visible_card_zones(hero_id: String) -> bool:
	return not player_hand.has(hero_id) and not player_discard.has(hero_id) and not enemy_hand.has(hero_id) and not enemy_discard.has(hero_id)


func _first_visible_card_id() -> String:
	for hero_ids in [player_hand, player_discard, enemy_hand, enemy_discard]:
		if not hero_ids.is_empty():
			return str(hero_ids[0])
	return ""


func _call_string(callback_name: String, args: Array = []) -> String:
	var value = _call(callback_name, args)
	return str(value)


func _call(callback_name: String, args: Array = []) -> Variant:
	var callback: Callable = callbacks.get(callback_name, Callable())
	if callback.is_valid():
		return callback.callv(args)
	return ""
