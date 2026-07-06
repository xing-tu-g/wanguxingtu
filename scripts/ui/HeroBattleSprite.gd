extends Control
class_name HeroBattleSprite

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const STATE_IDLE := "idle"
const STATE_ATTACK := "attack"
const STATE_SKILL := "skill"
const POSE_DURATION := 0.34
const BREATH_OFFSET := 3.0
const BREATH_DURATION := 1.45
const HIT_SHAKE_OFFSET := 5.0
const HIT_SHAKE_DURATION := 0.12
const DEATH_DURATION := 0.28

var hero_id: String = ""
var side: String = BoardModelScript.SIDE_LEFT
var hero_def: Dictionary = {}
var _pose_token: int = 0
var _breath_tween: Tween
var _hit_tween: Tween
var _death_tween: Tween
var _base_sprite_position: Vector2 = Vector2.ZERO

@onready var sprite: TextureRect = TextureRect.new()


func _ready() -> void:
	if sprite.get_parent() == null:
		sprite.name = "BattleSpriteTexture"
		sprite.anchor_left = 0.06
		sprite.anchor_right = 0.94
		sprite.anchor_top = -0.20
		sprite.anchor_bottom = 1.02
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
	_base_sprite_position = sprite.position
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup_from_unit(unit_data: Dictionary, new_hero_def: Dictionary) -> void:
	_ensure_sprite()
	if unit_data.is_empty():
		clear()
		return
	hero_id = str(unit_data.get("hero_id", ""))
	side = str(unit_data.get("side", BoardModelScript.SIDE_LEFT))
	hero_def = new_hero_def.duplicate(true)
	_apply_orientation()
	visible = true
	modulate = Color.WHITE
	sprite.position = _base_sprite_position
	sprite.scale = Vector2.ONE
	show_idle()
	_start_idle_breath()


func clear() -> void:
	_ensure_sprite()
	hero_id = ""
	hero_def.clear()
	_kill_motion_tweens()
	sprite.texture = null
	sprite.flip_h = false
	sprite.position = _base_sprite_position
	sprite.scale = Vector2.ONE
	modulate = Color.WHITE
	visible = false


func show_idle() -> void:
	_set_pose(STATE_IDLE)


func play_attack() -> void:
	_play_temporary_pose(STATE_ATTACK)


func play_skill() -> void:
	_play_temporary_pose(STATE_SKILL)


func play_hit() -> void:
	_ensure_sprite()
	if hero_id.is_empty():
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	var direction := -1.0 if side == BoardModelScript.SIDE_LEFT else 1.0
	_hit_tween = create_tween()
	_hit_tween.set_trans(Tween.TRANS_SINE)
	_hit_tween.set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(sprite, "position:x", _base_sprite_position.x + HIT_SHAKE_OFFSET * direction, HIT_SHAKE_DURATION * 0.35)
	_hit_tween.tween_property(sprite, "position:x", _base_sprite_position.x - HIT_SHAKE_OFFSET * 0.45 * direction, HIT_SHAKE_DURATION * 0.25)
	_hit_tween.tween_property(sprite, "position:x", _base_sprite_position.x, HIT_SHAKE_DURATION * 0.40)


func play_death() -> void:
	_ensure_sprite()
	if hero_id.is_empty():
		return
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_stop_idle_breath()
	_death_tween = create_tween()
	_death_tween.set_parallel(true)
	_death_tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION)
	_death_tween.tween_property(sprite, "scale", Vector2(0.82, 0.82), DEATH_DURATION)
	_death_tween.set_parallel(false)
	_death_tween.tween_callback(clear)


func has_pose(pose: String) -> bool:
	return _texture_path_for_pose(pose) != ""


func _play_temporary_pose(pose: String) -> void:
	_ensure_sprite()
	if hero_id.is_empty():
		return
	_pose_token += 1
	var token := _pose_token
	_set_pose(pose)
	var tween := create_tween()
	tween.tween_interval(POSE_DURATION)
	tween.tween_callback(_return_to_idle_if_current.bind(token))


func _return_to_idle_if_current(token: int) -> void:
	if token != _pose_token:
		return
	show_idle()


func _set_pose(pose: String) -> void:
	_ensure_sprite()
	var path := _texture_path_for_pose(pose)
	if path.is_empty():
		path = _texture_path_for_pose(STATE_IDLE)
	if path.is_empty():
		sprite.texture = null
		visible = false
		return
	var tex := _load_texture(path)
	sprite.texture = tex
	_apply_orientation()
	visible = tex != null
	if visible:
		_start_idle_breath()


func _texture_path_for_pose(pose: String) -> String:
	if hero_def.is_empty():
		return ""
	match pose:
		STATE_ATTACK:
			return str(hero_def.get("battle_attack", hero_def.get("battle_idle", "")))
		STATE_SKILL:
			return str(hero_def.get("battle_skill", hero_def.get("battle_idle", "")))
		_:
			return str(hero_def.get("battle_idle", hero_def.get("portrait", "")))


func _apply_orientation() -> void:
	_ensure_sprite()
	sprite.flip_h = side == BoardModelScript.SIDE_RIGHT


func _ensure_sprite() -> void:
	if sprite == null:
		sprite = get_node_or_null("BattleSpriteTexture") as TextureRect
	if sprite == null:
		sprite = TextureRect.new()
		sprite.name = "BattleSpriteTexture"
		add_child(sprite)
	_base_sprite_position = sprite.position


func _start_idle_breath() -> void:
	if sprite == null or not visible or hero_id.is_empty():
		return
	if _breath_tween != null and _breath_tween.is_valid():
		return
	_breath_tween = create_tween()
	_breath_tween.set_loops()
	_breath_tween.set_trans(Tween.TRANS_SINE)
	_breath_tween.set_ease(Tween.EASE_IN_OUT)
	_breath_tween.tween_property(sprite, "position:y", _base_sprite_position.y - BREATH_OFFSET, BREATH_DURATION)
	_breath_tween.tween_property(sprite, "position:y", _base_sprite_position.y + BREATH_OFFSET * 0.45, BREATH_DURATION)
	_breath_tween.tween_property(sprite, "position:y", _base_sprite_position.y, BREATH_DURATION * 0.55)


func _stop_idle_breath() -> void:
	if _breath_tween != null and _breath_tween.is_valid():
		_breath_tween.kill()
	_breath_tween = null
	if sprite != null:
		sprite.position.y = _base_sprite_position.y


func _kill_motion_tweens() -> void:
	_stop_idle_breath()
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	_hit_tween = null
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = null


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var file_path := path
	if file_path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(file_path)
	if not FileAccess.file_exists(file_path):
		return null
	var image := Image.new()
	var error := image.load(file_path)
	if error != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _exit_tree() -> void:
	_kill_motion_tweens()
