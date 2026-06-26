extends Control

const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")

@export_file("*.tscn") var initial_screen: String

## Fade durations in seconds for screen transitions.
const FADE_OUT_DURATION := 0.15
const FADE_IN_DURATION := 0.20

var current_screen: Control
var _transitioning: bool = false


func _ready() -> void:
	print("万古星图启动：ScreenRouter ready，初始页面=%s" % initial_screen)
	DataLoaderScript.load_all()

	# Listen for navigation requests from any scene via EventBus.
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("screen_changed"):
		if not bus.screen_changed.is_connected(_on_screen_changed):
			bus.screen_changed.connect(_on_screen_changed)

	if initial_screen.is_empty():
		push_error("Boot requires an initial screen path.")
		return
	show_screen(initial_screen)


func _on_screen_changed(scene_path: String, screen_data: Dictionary = {}) -> void:
	show_screen(scene_path, screen_data)


func show_screen(scene_path: String, screen_data: Dictionary = {}) -> void:
	if _transitioning:
		push_warning("ScreenRouter: transition already in progress, skipping %s" % scene_path)
		return

	print("万古星图切换页面：%s" % scene_path)

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Unable to load screen: %s" % scene_path)
		return

	var new_screen := packed_scene.instantiate() as Control
	if new_screen == null:
		push_error("Screen root must be a Control: %s" % scene_path)
		return

	# Pass data before adding to tree so it's available in _ready().
	if not screen_data.is_empty() and new_screen.has_method("set_screen_data"):
		new_screen.set_screen_data(screen_data)
	elif not screen_data.is_empty() and new_screen.has_method("set_result"):
		new_screen.set_result(screen_data)

	new_screen.set_anchors_preset(Control.PRESET_FULL_RECT)

	var old_screen := current_screen
	if old_screen != null:
		# ── Fade out old, then swap ──
		_transitioning = true
		old_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween_out := create_tween()
		tween_out.tween_property(old_screen, "modulate:a", 0.0, FADE_OUT_DURATION)
		tween_out.tween_callback(_swap_screens.bind(old_screen, new_screen, scene_path))
	else:
		# ── No old screen — instant fade-in ──
		_add_and_fade_in(new_screen, scene_path)


func _swap_screens(old_screen: Control, new_screen: Control, scene_path: String) -> void:
	remove_child(old_screen)
	old_screen.queue_free()
	current_screen = null
	_add_and_fade_in(new_screen, scene_path)


func _add_and_fade_in(new_screen: Control, scene_path: String) -> void:
	current_screen = new_screen
	new_screen.modulate.a = 0.0
	add_child(new_screen)
	var tween_in := create_tween()
	tween_in.tween_property(new_screen, "modulate:a", 1.0, FADE_IN_DURATION)
	tween_in.tween_callback(_on_transition_done.bind(scene_path, new_screen))


func _on_transition_done(scene_path: String, new_screen: Control) -> void:
	_transitioning = false
	print("万古星图页面已加载：%s，节点=%s" % [scene_path, new_screen.name])
