extends SceneTree

const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"
const CARD_ZONE_VIEW_PATH := "res://scripts/ui/CardZoneView.gd"


func _init() -> void:
	var failures: Array[String] = []
	var screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	var card_zone_source := FileAccess.get_file_as_string(CARD_ZONE_VIEW_PATH)

	_expect(not screen_source.is_empty(), "BattleScreen.gd is readable", failures)
	_expect(not card_zone_source.is_empty(), "CardZoneView.gd is readable", failures)
	_expect(card_zone_source.contains("class_name CardZoneView"), "CardZoneView exposes a class name", failures)
	_expect(screen_source.contains("CardZoneView"), "BattleScreen references CardZoneView via class_name (global type)", failures)
	_expect(screen_source.contains("card_zone_view.setup("), "BattleScreen initializes CardZoneView", failures)
	_expect(screen_source.contains("func _update_card_zone_summary"), "BattleScreen keeps card-zone compatibility wrapper", failures)
	_expect(screen_source.contains("card_zone_view.refresh()"), "card-zone summary wrapper delegates to CardZoneView", failures)
	_expect(screen_source.contains("card_zone_view.toggle()"), "toggle wrapper delegates to CardZoneView", failures)
	_expect(screen_source.contains("card_zone_view.close()"), "close wrapper delegates to CardZoneView", failures)
	_expect(screen_source.contains("changed.connect"), "BattleScreen connects to CardZoneView signal", failures)
	_expect(card_zone_source.contains("func refresh_cards"), "CardZoneView owns card row refresh", failures)
	_expect(card_zone_source.contains("func refresh_inspect_label"), "CardZoneView owns inspect refresh", failures)
	_expect(card_zone_source.contains("func select_card_for_inspect"), "CardZoneView owns inspect selection", failures)

	if failures.is_empty():
		print("M76 card zone view split checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
