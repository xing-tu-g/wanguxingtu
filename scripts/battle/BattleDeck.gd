extends RefCounted
class_name BattleDeck

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

var decks: Dictionary = {
	BoardModelScript.SIDE_LEFT: [],
	BoardModelScript.SIDE_RIGHT: [],
}
var hands: Dictionary = {
	BoardModelScript.SIDE_LEFT: [],
	BoardModelScript.SIDE_RIGHT: [],
}
var discards: Dictionary = {
	BoardModelScript.SIDE_LEFT: [],
	BoardModelScript.SIDE_RIGHT: [],
}
var recycle_discard_on_empty: bool = false


func setup(left_deck_ids: Array, right_deck_ids: Array, starting_hand_size: int = 0, recycle_discard: bool = false, shuffle_seed: int = -1) -> void:
	recycle_discard_on_empty = recycle_discard
	reset(left_deck_ids, right_deck_ids, shuffle_seed)
	draw(BoardModelScript.SIDE_LEFT, starting_hand_size)
	draw(BoardModelScript.SIDE_RIGHT, starting_hand_size)


func reset(left_deck_ids: Array, right_deck_ids: Array, shuffle_seed: int = -1) -> void:
	decks[BoardModelScript.SIDE_LEFT] = left_deck_ids.duplicate()
	decks[BoardModelScript.SIDE_RIGHT] = right_deck_ids.duplicate()
	_shuffle_deck(decks[BoardModelScript.SIDE_LEFT], shuffle_seed)
	_shuffle_deck(decks[BoardModelScript.SIDE_RIGHT], shuffle_seed + 1 if shuffle_seed >= 0 else -1)
	hands[BoardModelScript.SIDE_LEFT] = []
	hands[BoardModelScript.SIDE_RIGHT] = []
	discards[BoardModelScript.SIDE_LEFT] = []
	discards[BoardModelScript.SIDE_RIGHT] = []


func _shuffle_deck(deck: Array, shuffle_seed: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if shuffle_seed >= 0:
		rng.seed = shuffle_seed
	else:
		rng.randomize()
	for index in range(deck.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current = deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = current


func draw(side: String, count: int) -> Array:
	var drawn_cards: Array = []
	var deck := deck_for_side(side)
	var hand := hand_for_side(side)
	for _draw_index in range(maxi(0, count)):
		if deck.is_empty():
			_recycle_discard_into_deck(side)
			if deck.is_empty():
				break
		var hero_id := str(deck.pop_front())
		hand.append(hero_id)
		drawn_cards.append(hero_id)
	return drawn_cards


func can_recycle_discard(side: String) -> bool:
	return recycle_discard_on_empty and deck_for_side(side).is_empty() and not discard_for_side(side).is_empty()


func _recycle_discard_into_deck(side: String) -> bool:
	if not can_recycle_discard(side):
		return false
	var deck := deck_for_side(side)
	var discard := discard_for_side(side)
	for hero_id_value in discard:
		deck.append(str(hero_id_value))
	discard.clear()
	return true


func consume_from_hand(side: String, hero_id: String) -> bool:
	var hand := hand_for_side(side)
	if not hand.has(hero_id):
		return false
	hand.erase(hero_id)
	discard_for_side(side).append(hero_id)
	return true


func consume_hand_index(side: String, hand_index: int) -> String:
	var hand := hand_for_side(side)
	if hand_index < 0 or hand_index >= hand.size():
		return ""
	var hero_id := str(hand[hand_index])
	hand.remove_at(hand_index)
	discard_for_side(side).append(hero_id)
	return hero_id


func has_no_deck_hand(side: String) -> bool:
	return deck_for_side(side).is_empty() and hand_for_side(side).is_empty() and discard_for_side(side).is_empty()


func has_no_deck_hand_or_units(side: String, survivor_count: int) -> bool:
	return survivor_count <= 0 and has_no_deck_hand(side)


func get_deck(side: String) -> Array:
	return deck_for_side(side)


func get_hand(side: String) -> Array:
	return hand_for_side(side)


func get_discard(side: String) -> Array:
	return discard_for_side(side)


func deck_for_side(side: String) -> Array:
	if side == BoardModelScript.SIDE_RIGHT:
		return decks[BoardModelScript.SIDE_RIGHT]
	return decks[BoardModelScript.SIDE_LEFT]


func hand_for_side(side: String) -> Array:
	if side == BoardModelScript.SIDE_RIGHT:
		return hands[BoardModelScript.SIDE_RIGHT]
	return hands[BoardModelScript.SIDE_LEFT]


func discard_for_side(side: String) -> Array:
	if side == BoardModelScript.SIDE_RIGHT:
		return discards[BoardModelScript.SIDE_RIGHT]
	return discards[BoardModelScript.SIDE_LEFT]


func counts_for_side(side: String) -> Dictionary:
	return {
		"deck": deck_for_side(side).size(),
		"hand": hand_for_side(side).size(),
		"discard": discard_for_side(side).size(),
	}


func counts(side: String) -> Dictionary:
	return counts_for_side(side)


func snapshot() -> Dictionary:
	return {
		"left_deck": deck_for_side(BoardModelScript.SIDE_LEFT).size(),
		"right_deck": deck_for_side(BoardModelScript.SIDE_RIGHT).size(),
		"left_hand": hand_for_side(BoardModelScript.SIDE_LEFT).size(),
		"right_hand": hand_for_side(BoardModelScript.SIDE_RIGHT).size(),
		"left_discard": discard_for_side(BoardModelScript.SIDE_LEFT).size(),
		"right_discard": discard_for_side(BoardModelScript.SIDE_RIGHT).size(),
		"recycle_discard_on_empty": recycle_discard_on_empty,
	}
