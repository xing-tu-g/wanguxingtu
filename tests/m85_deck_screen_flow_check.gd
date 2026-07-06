extends SceneTree

const DeckScreenScene: PackedScene = preload("res://scenes/ui/DeckScreen.tscn")
const HomeScreenScript: GDScript = preload("res://scripts/ui/HomeScreen.gd")
const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")
const DeckDataManagerScript: GDScript = preload("res://scripts/data/DeckDataManager.gd")


func _init() -> void:
	var failures: Array[String] = []
	await _check_deck_screen_payload(failures)
	_check_home_routes_to_deck(failures)
	_finish(failures)


func _check_deck_screen_payload(failures: Array[String]) -> void:
	var screen: Control = DeckScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var expected_count: int = HeroDataLoaderScript.all_hero_ids(false).size()
	_expect(screen.player_deck.size() == DeckDataManagerScript.MAX_BATTLE_DECK_SIZE, "deck screen uses 20-card player deck", failures)
	_expect(screen.enemy_deck.size() == DeckDataManagerScript.MAX_BATTLE_DECK_SIZE, "enemy deck is data-driven 20-card fallback", failures)
	_expect(screen._all_heroes.size() == expected_count, "deck builder still lists all non-summon heroes", failures)
	_expect(screen.player_deck.size() >= 5, "player deck can draw opening five", failures)
	_expect(screen.enemy_deck == DeckDataManagerScript.default_enemy_deck(), "enemy deck uses deterministic manager fallback", failures)
	screen.queue_free()


func _check_home_routes_to_deck(failures: Array[String]) -> void:
	_expect(HomeScreenScript.DECK_SCREEN == "res://scenes/ui/DeckBuilderScene.tscn", "home exposes deck builder route", failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("M85 deck screen flow checks passed")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
