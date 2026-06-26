extends SceneTree

const BattleDeckScript: GDScript = preload("res://scripts/battle/BattleDeck.gd")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const LEFT_DECK := ["guanyu", "zhouyu", "zhangjiao", "zhaoyun"]
const RIGHT_DECK := ["zhouyu", "guanyu", "zhaoyun", "zhangfei"]
const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"
const M19_PATH := "res://tests/m19_pacing_trend_probe_check.gd"
const M22_PATH := "res://tests/m22_pacing_multi_sample_check.gd"


func _init() -> void:
	var failures: Array[String] = []
	_check_setup_and_initial_draw(failures)
	_check_draw_and_empty_deck(failures)
	_check_optional_discard_recycle(failures)
	_check_consume_to_discard(failures)
	_check_reset_replaces_piles(failures)
	_check_runtime_and_probes_share_helper(failures)
	await process_frame

	if failures.is_empty():
		print("M30 battle deck helper checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_setup_and_initial_draw(failures: Array[String]) -> void:
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(LEFT_DECK, RIGHT_DECK, 2)
	_expect(battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT) == ["guanyu", "zhouyu"], "left opening hand draws from left deck", failures)
	_expect(battle_deck.deck_for_side(BoardModelScript.SIDE_LEFT) == ["zhangjiao", "zhaoyun"], "left deck keeps undrawn cards", failures)
	_expect(battle_deck.hand_for_side(BoardModelScript.SIDE_RIGHT) == ["zhouyu", "guanyu"], "right opening hand draws from right deck", failures)
	_expect(battle_deck.discard_for_side(BoardModelScript.SIDE_RIGHT).is_empty(), "right discard starts empty", failures)
	_expect(not battle_deck.has_no_deck_hand(BoardModelScript.SIDE_LEFT), "side with deck and hand is not exhausted", failures)


func _check_draw_and_empty_deck(failures: Array[String]) -> void:
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(["guanyu"], [], 0)
	_expect(battle_deck.draw(BoardModelScript.SIDE_LEFT, 2) == ["guanyu"], "draw stops when deck empties", failures)
	_expect(battle_deck.draw(BoardModelScript.SIDE_LEFT, 1).is_empty(), "empty deck draw returns empty array", failures)
	_expect(battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT) == ["guanyu"], "empty deck draw keeps hand unchanged", failures)
	_expect(battle_deck.has_no_deck_hand(BoardModelScript.SIDE_RIGHT), "empty right deck and hand are exhausted", failures)


func _check_optional_discard_recycle(failures: Array[String]) -> void:
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(["guanyu"], [], 1, true)
	_expect(battle_deck.consume_from_hand(BoardModelScript.SIDE_LEFT, "guanyu"), "consume card before recycle", failures)
	_expect(not battle_deck.has_no_deck_hand(BoardModelScript.SIDE_LEFT), "discard prevents exhaustion when recycle is enabled", failures)
	_expect(battle_deck.draw(BoardModelScript.SIDE_LEFT, 1) == ["guanyu"], "draw recycles discard when deck is empty", failures)
	_expect(battle_deck.discard_for_side(BoardModelScript.SIDE_LEFT).is_empty(), "recycle clears discard", failures)
	_expect(battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT) == ["guanyu"], "recycled card enters hand", failures)


func _check_consume_to_discard(failures: Array[String]) -> void:
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(LEFT_DECK, RIGHT_DECK, 2)
	_expect(battle_deck.consume_from_hand(BoardModelScript.SIDE_LEFT, "zhouyu"), "consume returns true for hand card", failures)
	_expect(not battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT).has("zhouyu"), "consumed card leaves hand", failures)
	_expect(battle_deck.discard_for_side(BoardModelScript.SIDE_LEFT) == ["zhouyu"], "consumed card enters discard", failures)
	_expect(not battle_deck.consume_from_hand(BoardModelScript.SIDE_LEFT, "sunshangxiang"), "consume returns false for missing card", failures)
	_expect(battle_deck.discard_for_side(BoardModelScript.SIDE_LEFT) == ["zhouyu"], "missing consume does not mutate discard", failures)


func _check_reset_replaces_piles(failures: Array[String]) -> void:
	var battle_deck = BattleDeckScript.new()
	battle_deck.setup(LEFT_DECK, RIGHT_DECK, 2)
	battle_deck.consume_from_hand(BoardModelScript.SIDE_LEFT, "guanyu")
	battle_deck.setup(["zhaoyun"], ["zhangfei"], 1)
	_expect(battle_deck.hand_for_side(BoardModelScript.SIDE_LEFT) == ["zhaoyun"], "setup replaces left hand", failures)
	_expect(battle_deck.deck_for_side(BoardModelScript.SIDE_LEFT).is_empty(), "setup replaces left deck", failures)
	_expect(battle_deck.discard_for_side(BoardModelScript.SIDE_LEFT).is_empty(), "setup clears left discard", failures)
	var snapshot: Dictionary = battle_deck.snapshot()
	_expect(int(snapshot.get("left_hand", 0)) == 1 and int(snapshot.get("right_hand", 0)) == 1, "snapshot reports both hand counts", failures)


func _check_runtime_and_probes_share_helper(failures: Array[String]) -> void:
	var battle_screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	var m19_source := FileAccess.get_file_as_string(M19_PATH)
	var m22_source := FileAccess.get_file_as_string(M22_PATH)
	for source_pair in [["BattleScreen", battle_screen_source], ["M19", m19_source], ["M22", m22_source]]:
		var label := str(source_pair[0])
		var source := str(source_pair[1])
		_expect(source.contains("BattleDeckScript"), "%s preloads BattleDeck helper" % label, failures)
		_expect(source.contains("battle_deck.draw"), "%s draws through BattleDeck helper" % label, failures)
		_expect(source.contains("battle_deck.consume_from_hand"), "%s consumes through BattleDeck helper" % label, failures)
		_expect(source.contains("battle_deck.has_no_deck_hand"), "%s checks exhaustion through BattleDeck helper" % label, failures)
	_expect(not m19_source.contains("func _draw_cards") and not m22_source.contains("func _draw_cards"), "probes do not keep private draw helpers", failures)
	_expect(not m19_source.contains("func _consume_card") and not m22_source.contains("func _consume_card"), "probes do not keep private consume helpers", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
