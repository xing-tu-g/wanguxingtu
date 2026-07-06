extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")
const DataLoaderScript: GDScript = preload("res://scripts/data/DataLoader.gd")

const OUTPUT_DIR := "res://tmp/battle_polish/core_skills"
const CORE_HERO_IDS := [
	"zhaoyun",
	"guanyu",
	"zhangfei",
	"lvbu",
	"zhugeliang",
	"caocao",
	"dianwei",
	"zhouyu",
	"sunce",
	"diaochan",
]


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	DataLoaderScript.load_all()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var ok := true
	for index in range(CORE_HERO_IDS.size()):
		ok = await _capture_hero_skill(str(CORE_HERO_IDS[index]), index) and ok

	Engine.time_scale = 1.0
	if ok:
		print("CORE_SKILL_SCREENSHOTS_CLEAN")
		quit(0)
		return
	quit(1)


func _capture_hero_skill(hero_id: String, index: int) -> bool:
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await _settle_frames(8)

	screen.first_deploy_hint_dismissed = true
	screen.battle_state.set_star_power(BoardModelScript.SIDE_LEFT, 10)
	var row := 1 + (index % BoardModelScript.ROWS)
	var deploy_result: Dictionary = screen.battle_state.deploy_hero(hero_id, BoardModelScript.SIDE_LEFT, 1, row)
	if not bool(deploy_result.get("ok", false)):
		printerr("CORE_SKILL_DEPLOY_FAILED: %s %s" % [hero_id, str(deploy_result)])
		screen.queue_free()
		await _settle_frames(3)
		return false

	screen._refresh_board()
	await _settle_frames(3)

	var unit: Dictionary = deploy_result.get("unit", {})
	var skill_result := _presentation_skill_result(hero_id)
	if skill_result.is_empty():
		printerr("CORE_SKILL_RESULT_MISSING: %s" % hero_id)
		screen.queue_free()
		await _settle_frames(3)
		return false

	var bus := root.get_node_or_null("EventBus")
	if bus == null or not bus.has_signal("unit_skill_triggered"):
		printerr("CORE_SKILL_EVENTBUS_MISSING")
		screen.queue_free()
		await _settle_frames(3)
		return false

	bus.unit_skill_triggered.emit(unit, skill_result)
	await _settle_frames(4)
	var ok := await _save_viewport("%02d_%s_skill.png" % [index + 1, hero_id])
	screen.queue_free()
	await _settle_frames(5)
	return ok


func _presentation_skill_result(hero_id: String) -> Dictionary:
	var hero := _hero_def(hero_id)
	if hero.is_empty():
		return {}
	var skill_ids: Array = hero.get("skill_ids", [])
	if skill_ids.is_empty():
		return {}
	var skill_id := str(skill_ids[0])
	var skill := _skill_def(skill_id)
	return {
		"ok": true,
		"skill_id": skill_id,
		"skill_name": str(skill.get("name", skill_id)),
		"effect_type": str(skill.get("effect_type", "")),
	}


func _hero_def(hero_id: String) -> Dictionary:
	for hero: Dictionary in DataLoaderScript.data.get("heroes", []):
		if str(hero.get("id", "")) == hero_id:
			return hero
	return {}


func _skill_def(skill_id: String) -> Dictionary:
	for skill: Dictionary in DataLoaderScript.data.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			return skill
	return {}


func _save_viewport(file_name: String) -> bool:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("CORE_SKILL_SCREENSHOT_FAILED: %s" % file_name)
		return false
	image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
	return true


func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
