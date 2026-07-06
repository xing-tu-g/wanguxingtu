extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const HeroBattleSpriteScript: GDScript = preload("res://scripts/ui/HeroBattleSprite.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const HERO_IDS := ["zhaoyun", "guanyu", "zhangfei", "machao", "huangzhong", "weiyan", "jiangwei", "zhugeliang", "pangtong", "caocao", "simayi", "zhangliao", "luxun", "lvbu", "zhouyu", "zhangjiao", "sunshangxiang", "yellow_turban", "guojia", "dianwei", "xunyu", "dongzhuo", "diaochan", "gongsunzan", "huaxiong", "guanping", "zhangbao", "mifuren", "madai", "xuchu", "zhenji", "caoren", "caopi", "lejin", "xiahoudun", "ganning", "sunjian", "lumeng", "xiaoqiao", "taishici", "huanggai", "zhoutai", "lingtong", "lusu", "chengpu", "sunquan", "daqiao", "sunce", "xusheng"]


func _init() -> void:
	var failures: Array[String] = []
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_asset_paths(screen, failures)
	_check_board_sprite_component(screen, failures)
	_check_pose_switching(screen, failures)

	screen.queue_free()
	if failures.is_empty():
		print("M83 hero battle sprite assets checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _check_asset_paths(screen: Control, failures: Array[String]) -> void:
	for hero_id in HERO_IDS:
		var hero_def: Dictionary = screen.battle_state.get_hero_def(hero_id)
		_expect(str(hero_def.get("hero_master", "")) == "res://assets/heroes/%s/hero_master.png" % hero_id, "%s has hero_master path" % hero_id, failures)
		_expect(str(hero_def.get("portrait", "")) == str(hero_def.get("hero_master", "")), "%s HeroCard portrait uses hero_master" % hero_id, failures)
		for key in ["hero_master", "battle_idle", "battle_attack", "battle_skill"]:
			var path := str(hero_def.get(key, ""))
			_expect(path == "res://assets/heroes/%s/%s.png" % [hero_id, key], "%s has %s path" % [hero_id, key], failures)
			_expect(_asset_exists(path), "%s resource exists at %s" % [hero_id, path], failures)
			_expect(_asset_has_transparency(path), "%s %s has transparent background" % [hero_id, key], failures)


func _check_board_sprite_component(screen: Control, failures: Array[String]) -> void:
	var hero_def: Dictionary = screen.battle_state.get_hero_def("zhaoyun")
	var unit_data: Dictionary = screen.battle_state.build_unit_data("zhaoyun", hero_def)
	unit_data["instance_id"] = "unit_test_zhaoyun"
	var place_result: Dictionary = screen.battle_state.create_unit_instance(unit_data, BoardModelScript.SIDE_LEFT, 1, 3)
	_expect(bool(place_result.get("ok", false)), "zhaoyun test unit can be placed", failures)
	screen._refresh_board()
	await_process()
	var cell_button: Button = screen.cell_buttons.get("1,3") as Button
	var battle_sprite: Control = cell_button.get_node_or_null("HeroBattleSprite") as Control
	_expect(battle_sprite != null, "board cell uses HeroBattleSprite component", failures)
	if battle_sprite != null:
		var texture_rect := battle_sprite.get_node_or_null("BattleSpriteTexture") as TextureRect
		_expect(texture_rect != null and texture_rect.texture != null, "HeroBattleSprite displays idle texture", failures)
		_expect(not texture_rect.flip_h, "left side sprite faces right by default", failures)


func _check_pose_switching(screen: Control, failures: Array[String]) -> void:
	var hero_def: Dictionary = screen.battle_state.get_hero_def("guanyu")
	var sprite: Control = HeroBattleSpriteScript.new()
	root.add_child(sprite)
	await_process()
	sprite.setup_from_unit({"hero_id": "guanyu", "side": BoardModelScript.SIDE_RIGHT}, hero_def)
	var texture_rect := sprite.get_node("BattleSpriteTexture") as TextureRect
	var idle_texture := texture_rect.texture
	_expect(texture_rect.flip_h, "right side sprite flips left", failures)
	sprite.play_attack()
	await_process()
	_expect(texture_rect.texture != null and texture_rect.texture != idle_texture, "attack pose switches texture", failures)
	sprite.play_skill()
	await_process()
	_expect(texture_rect.texture != null and texture_rect.texture != idle_texture, "skill pose switches texture", failures)
	sprite.queue_free()


func await_process() -> void:
	await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)


func _asset_exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	var file_path := path
	if file_path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(file_path)
	return FileAccess.file_exists(file_path)


func _asset_has_transparency(path: String) -> bool:
	var file_path := path
	if file_path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(file_path)
	var image := Image.new()
	if image.load(file_path) != OK or image.is_empty():
		return false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.01:
				return true
	return false
