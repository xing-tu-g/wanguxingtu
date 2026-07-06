extends SceneTree

const HERO_SPRITE_SCRIPT := "res://scripts/ui/HeroBattleSprite.gd"
const BATTLE_ANIMATOR_SCRIPT := "res://scripts/ui/BattleAnimator.gd"
const SCREEN_ROUTER_SCRIPT := "res://scripts/ui/ScreenRouter.gd"
const RESULT_SCENE := "res://scenes/ui/ResultScreen.tscn"
const HEROES_DATA := "res://data/heroes.json"
const SKILLS_DATA := "res://data/skills.json"
const CORE_SKILL_CAPTURE_SCRIPT := "res://scripts/tools/capture_core_skill_screens.gd"
const CORE_SKILL_HERO_IDS := [
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
	var failures: Array[String] = []
	_check_hero_battle_sprite(failures)
	_check_battle_animator_feedback(failures)
	_check_fx_directories(failures)
	_check_router_queue(failures)
	_check_result_screen_nodes(failures)
	_check_core_skill_hero_data(failures)
	_check_core_skill_capture_script(failures)

	if failures.is_empty():
		print("M86 battle polish feedback checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_hero_battle_sprite(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(HERO_SPRITE_SCRIPT)
	_expect(source.contains("BREATH_OFFSET"), "idle breathing offset is defined", failures)
	_expect(source.contains("_start_idle_breath"), "idle breathing animation is started", failures)
	_expect(source.contains("play_hit"), "hit reaction method exists", failures)
	_expect(source.contains("play_death"), "death fade method exists", failures)


func _check_battle_animator_feedback(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(BATTLE_ANIMATOR_SCRIPT)
	_expect(source.contains("HIT_STOP_DURATION"), "hit stop duration is defined", failures)
	_expect(source.contains("_spawn_damage_number"), "damage float text is spawned", failures)
	_expect(source.contains("_spawn_skill_banner"), "skill name banner is spawned", failures)
	_expect(source.contains("_spawn_skill_fx"), "runtime skill FX placeholder is spawned", failures)
	_expect(source.contains("CORE_SKILL_HEROES"), "core skill hero list exists", failures)
	_expect(source.contains("CAMERA_SHAKE_SKILL"), "skill camera shake is defined", failures)


func _check_fx_directories(failures: Array[String]) -> void:
	for path in [
		"res://assets/fx/hit/.keep",
		"res://assets/fx/slash/.keep",
		"res://assets/fx/dash/.keep",
		"res://assets/fx/fire/.keep",
		"res://assets/fx/lightning/.keep",
		"res://assets/fx/heal/.keep",
		"res://assets/fx/buff/.keep",
	]:
		_expect(FileAccess.file_exists(path), "FX directory marker exists: %s" % path, failures)


func _check_router_queue(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(SCREEN_ROUTER_SCRIPT)
	_expect(source.contains("_queued_scene_path"), "screen router stores queued route", failures)
	_expect(not source.contains("transition already in progress"), "screen router no longer warns on queued route", failures)


func _check_result_screen_nodes(failures: Array[String]) -> void:
	var scene: PackedScene = load(RESULT_SCENE)
	var screen := scene.instantiate()
	root.add_child(screen)
	_expect(screen.get_node_or_null("Margin/Layout/ResultPanel/ResultGrid") != null, "result screen has formal stat grid", failures)
	_expect(screen.get_node_or_null("Margin/Layout/ButtonRow/RetryButton") != null, "result screen has retry button", failures)
	_expect(screen.get_node_or_null("Margin/Layout/Body") != null, "legacy debug body remains for compatibility", failures)
	screen.queue_free()


func _check_core_skill_hero_data(failures: Array[String]) -> void:
	var heroes: Array = JSON.parse_string(FileAccess.get_file_as_string(HEROES_DATA))
	var skills: Array = JSON.parse_string(FileAccess.get_file_as_string(SKILLS_DATA))
	var heroes_by_id := {}
	var skills_by_id := {}
	for hero: Dictionary in heroes:
		heroes_by_id[str(hero.get("id", ""))] = hero
	for skill: Dictionary in skills:
		skills_by_id[str(skill.get("id", ""))] = skill
	for hero_id: String in CORE_SKILL_HERO_IDS:
		_expect(heroes_by_id.has(hero_id), "core skill hero exists: %s" % hero_id, failures)
		if not heroes_by_id.has(hero_id):
			continue
		var hero: Dictionary = heroes_by_id[hero_id]
		var battle_skill_path := str(hero.get("battle_skill", ""))
		_expect(FileAccess.file_exists(battle_skill_path), "core skill hero has battle_skill art: %s" % hero_id, failures)
		var skill_ids: Array = hero.get("skill_ids", [])
		_expect(not skill_ids.is_empty(), "core skill hero has at least one skill: %s" % hero_id, failures)
		if not skill_ids.is_empty():
			_expect(skills_by_id.has(str(skill_ids[0])), "core skill hero first skill exists: %s" % hero_id, failures)


func _check_core_skill_capture_script(failures: Array[String]) -> void:
	_expect(FileAccess.file_exists(CORE_SKILL_CAPTURE_SCRIPT), "core skill screenshot script exists", failures)
	var source := FileAccess.get_file_as_string(CORE_SKILL_CAPTURE_SCRIPT)
	for hero_id: String in CORE_SKILL_HERO_IDS:
		_expect(source.contains("\"%s\"" % hero_id), "core skill capture covers %s" % hero_id, failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
