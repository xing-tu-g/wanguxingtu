extends RefCounted
class_name StarTrackSystem

const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")
const HeroDataLoaderScript: GDScript = preload("res://scripts/data/HeroDataLoader.gd")

const MIN_VALUE := 0
const MAX_VALUE := 10000
const MAX_LEVEL := 100
const DEFAULT_WIN_GAIN := 30
const DEFAULT_LOSE_LOSS := 10
const WAIT_RANGE_EXPAND_SECONDS := 10.0
const WAIT_CROSS_DIVISION_SECONDS := 20.0
const WAIT_RANGE_MULTIPLIER := 1.2
const WIN_STREAK_THRESHOLD := 5
const WIN_STREAK_RANGE_MULTIPLIER := 1.15
const SMURF_GAP_THRESHOLD := 1000
const SMURF_HIGH_REWARD_MULTIPLIER := 0.5

const DIVISIONS := [
	{
		"id": "awakening",
		"name": "初星 · Awakening",
		"short_name": "初星",
		"min": 0,
		"max": 500,
		"base_range": 200,
		"match_min": 0,
		"match_max": 800,
		"protected_loss": true,
	},
	{
		"id": "formation",
		"name": "星轨 · Formation",
		"short_name": "星轨",
		"min": 500,
		"max": 1500,
		"base_range": 300,
		"protected_loss": false,
	},
	{
		"id": "flow",
		"name": "星流 · Flow State",
		"short_name": "星流",
		"min": 1500,
		"max": 3000,
		"base_range": 500,
		"protected_loss": false,
	},
	{
		"id": "domain",
		"name": "星域 · Domain",
		"short_name": "星域",
		"min": 3000,
		"max": 5000,
		"base_range": 700,
		"protected_loss": false,
	},
	{
		"id": "astral",
		"name": "星界 · Astral Realm",
		"short_name": "星界",
		"min": 5000,
		"max": 7500,
		"base_range": 800,
		"protected_loss": false,
	},
	{
		"id": "core",
		"name": "星核 · Core Collapse",
		"short_name": "星核",
		"min": 7500,
		"max": 10000,
		"base_range": 1000,
		"protected_loss": false,
	},
]

var current_star_track_value := 0
var current_star_track_level := 1
var win_gain_value := DEFAULT_WIN_GAIN
var lose_loss_value := DEFAULT_LOSE_LOSS
var level_threshold_table: Array[int] = []


func _init() -> void:
	level_threshold_table = build_level_threshold_table()
	var state := load_state()
	current_star_track_value = int(state.get("current_star_track_value", 0))
	current_star_track_level = int(state.get("current_star_track_level", 1))


static func build_level_threshold_table() -> Array[int]:
	var table: Array[int] = []
	for level in range(1, MAX_LEVEL + 1):
		table.append(int(round(float(MAX_VALUE) * float(level - 1) / float(MAX_LEVEL - 1))))
	return table


static func load_state() -> Dictionary:
	var save_data := _load_or_default_save()
	return _state_from_save(save_data)


static func save_state(value: int) -> Dictionary:
	var save_data := _load_or_default_save()
	var player: Dictionary = save_data.get("player", {})
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	player["star_track_value"] = clean_value
	player["star_track_level"] = level_for_value(clean_value)
	player["rank_points"] = clean_value
	save_data["player"] = player
	SaveServiceScript.save_game(save_data)
	return _state_from_save(save_data)


static func apply_battle_result(outcome: String) -> Dictionary:
	return apply_match_result(outcome)


static func apply_match_result(outcome: String, opponent_value: int = -1, win_streak: int = 0, lose_streak: int = 0) -> Dictionary:
	var before := load_state()
	var before_value := int(before.get("current_star_track_value", 0))
	var before_division: Dictionary = before.get("division", division_for_value(before_value))
	var delta_info := delta_for_match_result(outcome, before_value, opponent_value)
	var delta := int(delta_info.get("delta", 0))
	var after := save_state(before_value + delta)
	return {
		"outcome": outcome,
		"delta": delta,
		"base_delta": int(delta_info.get("base_delta", delta)),
		"before": before,
		"after": after,
		"before_division": before_division,
		"after_division": after.get("division", division_for_value(int(after.get("current_star_track_value", 0)))),
		"division_up": division_index_for_value(int(after.get("current_star_track_value", 0))) > division_index_for_value(before_value),
		"leveled_up": int(after.get("current_star_track_level", 1)) > int(before.get("current_star_track_level", 1)),
		"anti_smurf": delta_info.get("anti_smurf", {}),
		"win_streak": win_streak,
		"lose_streak": lose_streak,
	}


static func delta_for_outcome(outcome: String) -> int:
	return int(delta_for_match_result(outcome, int(load_state().get("current_star_track_value", 0))).get("delta", 0))


static func delta_for_match_result(outcome: String, player_value: int, opponent_value: int = -1) -> Dictionary:
	var clean_value := clampi(player_value, MIN_VALUE, MAX_VALUE)
	var base_delta := 0
	match outcome:
		"left_wins", "win", "victory":
			base_delta = DEFAULT_WIN_GAIN
		"right_wins", "both_failed", "loss", "defeat":
			base_delta = 0 if is_loss_protected(clean_value) else -DEFAULT_LOSE_LOSS
		_:
			base_delta = 0
	var adjusted := anti_smurf_adjustment(clean_value, opponent_value, base_delta)
	return {
		"delta": int(adjusted.get("delta", base_delta)),
		"base_delta": base_delta,
		"anti_smurf": adjusted,
	}


static func anti_smurf_adjustment(player_value: int, opponent_value: int, base_delta: int) -> Dictionary:
	if opponent_value < 0 or base_delta == 0:
		return {
			"triggered": false,
			"delta": base_delta,
			"reason": "none",
		}
	var gap := player_value - opponent_value
	if gap >= SMURF_GAP_THRESHOLD and base_delta > 0:
		return {
			"triggered": true,
			"delta": maxi(1, int(round(float(base_delta) * SMURF_HIGH_REWARD_MULTIPLIER))),
			"reason": "high_player_reward_reduced",
			"gap": gap,
		}
	if gap <= -SMURF_GAP_THRESHOLD and base_delta < 0:
		return {
			"triggered": true,
			"delta": 0,
			"reason": "low_player_loss_reduced",
			"gap": gap,
		}
	return {
		"triggered": false,
		"delta": base_delta,
		"reason": "none",
		"gap": gap,
	}


static func is_loss_protected(value: int) -> bool:
	return clampi(value, MIN_VALUE, MAX_VALUE) < 500


static func division_index_for_value(value: int) -> int:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	for index in range(DIVISIONS.size()):
		var division: Dictionary = DIVISIONS[index]
		var min_value := int(division.get("min", 0))
		var max_value := int(division.get("max", MAX_VALUE))
		if index == DIVISIONS.size() - 1:
			if clean_value >= min_value and clean_value <= max_value:
				return index
		elif clean_value >= min_value and clean_value < max_value:
			return index
	return DIVISIONS.size() - 1


static func division_for_value(value: int) -> Dictionary:
	var index := division_index_for_value(value)
	var division: Dictionary = DIVISIONS[index].duplicate(true)
	division["index"] = index
	return division


static func distance_to_next_division(value: int) -> int:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	var division := division_for_value(clean_value)
	var next_value := int(division.get("max", MAX_VALUE))
	if clean_value >= MAX_VALUE:
		return 0
	return maxi(0, next_value - clean_value)


static func division_progress_for_value(value: int) -> Dictionary:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	var division := division_for_value(clean_value)
	var min_value := int(division.get("min", MIN_VALUE))
	var max_value := int(division.get("max", MAX_VALUE))
	var span := maxi(1, max_value - min_value)
	var progress_value := clampi(clean_value - min_value, 0, span)
	return {
		"value": clean_value,
		"division": division,
		"current_threshold": min_value,
		"next_threshold": max_value,
		"progress_value": progress_value,
		"progress_max": span,
		"to_next": distance_to_next_division(clean_value),
		"ratio": float(progress_value) / float(span),
	}


static func match_range_for_value(value: int, wait_seconds: float = 0.0, win_streak: int = 0) -> Dictionary:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	var division := division_for_value(clean_value)
	var division_index := int(division.get("index", 0))
	var base_range := int(division.get("base_range", 200))
	var range_multiplier := 1.0
	if wait_seconds > WAIT_RANGE_EXPAND_SECONDS:
		range_multiplier *= WAIT_RANGE_MULTIPLIER
	if win_streak >= WIN_STREAK_THRESHOLD:
		range_multiplier *= WIN_STREAK_RANGE_MULTIPLIER
	var effective_range := int(round(float(base_range) * range_multiplier))
	var min_value := clampi(clean_value - effective_range, MIN_VALUE, MAX_VALUE)
	var max_value := clampi(clean_value + effective_range, MIN_VALUE, MAX_VALUE)
	var can_cross_division := wait_seconds > WAIT_CROSS_DIVISION_SECONDS

	if division.has("match_min"):
		min_value = int(division.get("match_min", min_value))
	if division.has("match_max"):
		max_value = int(division.get("match_max", max_value))
	elif can_cross_division:
		var low_index := maxi(0, division_index - 1)
		var high_index := mini(DIVISIONS.size() - 1, division_index + 1)
		min_value = mini(min_value, int(DIVISIONS[low_index].get("min", MIN_VALUE)))
		max_value = maxi(max_value, int(DIVISIONS[high_index].get("max", MAX_VALUE)))

	return {
		"value": clean_value,
		"division": division,
		"base_range": base_range,
		"effective_range": effective_range,
		"min": clampi(min_value, MIN_VALUE, MAX_VALUE),
		"max": clampi(max_value, MIN_VALUE, MAX_VALUE),
		"wait_seconds": wait_seconds,
		"wait_expanded": wait_seconds > WAIT_RANGE_EXPAND_SECONDS,
		"can_cross_division": can_cross_division,
		"win_streak_expanded": win_streak >= WIN_STREAK_THRESHOLD,
	}


static func candidate_priority(player_value: int, candidate_value: int, wait_seconds: float = 0.0) -> String:
	var player_index := division_index_for_value(player_value)
	var candidate_index := division_index_for_value(candidate_value)
	if player_index == candidate_index:
		return "same_division"
	if abs(candidate_index - player_index) == 1:
		return "adjacent_division" if wait_seconds > WAIT_CROSS_DIVISION_SECONDS else "adjacent_waiting"
	return "expanded_division" if wait_seconds > WAIT_CROSS_DIVISION_SECONDS else "out_of_range"


static func can_match(player_value: int, candidate_value: int, wait_seconds: float = 0.0, win_streak: int = 0) -> bool:
	var range_info := match_range_for_value(player_value, wait_seconds, win_streak)
	var clean_candidate := clampi(candidate_value, MIN_VALUE, MAX_VALUE)
	if clean_candidate < int(range_info.get("min", MIN_VALUE)):
		return false
	if clean_candidate > int(range_info.get("max", MAX_VALUE)):
		return false
	var division: Dictionary = range_info.get("division", {})
	if str(division.get("id", "")) == "awakening":
		return true
	var priority := candidate_priority(player_value, clean_candidate, wait_seconds)
	return priority != "out_of_range" and priority != "adjacent_waiting"


static func level_for_value(value: int) -> int:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	return clampi(int(floor(float(clean_value) / 100.0)) + 1, 1, MAX_LEVEL)


static func threshold_for_level(level: int) -> int:
	var index := clampi(level, 1, MAX_LEVEL) - 1
	return int(build_level_threshold_table()[index])


static func progress_for_value(value: int) -> Dictionary:
	var progress := division_progress_for_value(value)
	progress["level"] = level_for_value(value)
	return progress


static func unlocked_hero_ids(level: int = -1) -> Array:
	var value := int(load_state().get("current_star_track_value", 0))
	if level >= 0:
		value = threshold_for_level(level)
	var heroes: Array = HeroDataLoaderScript.all_heroes(false)
	var limit: int = _unlock_limit_for_value(value, heroes.size())
	var ids: Array = []
	for index in range(mini(limit, heroes.size())):
		ids.append(str(heroes[index].get("id", "")))
	return ids


static func is_hero_unlocked(hero_id: String, level: int = -1) -> bool:
	return unlocked_hero_ids(level).has(hero_id)


static func unlock_tier_text(level: int) -> String:
	var value := threshold_for_level(level)
	return unlock_tier_text_for_value(value)


static func unlock_tier_text_for_value(value: int) -> String:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	if clean_value >= 5000:
		return "完整英雄池"
	if clean_value >= 1500:
		return "高稀有英雄池"
	if clean_value >= 500:
		return "五职业核心池"
	return "基础阵营池"


static func _load_or_default_save() -> Dictionary:
	var save_data: Dictionary = SaveServiceScript.load_game()
	if save_data.is_empty():
		save_data = SaveServiceScript.create_default_save()
		SaveServiceScript.save_game(save_data)
	return save_data


static func _state_from_save(save_data: Dictionary) -> Dictionary:
	var player: Dictionary = save_data.get("player", {})
	var value: int = clampi(int(player.get("star_track_value", player.get("rank_points", 0))), MIN_VALUE, MAX_VALUE)
	var level: int = level_for_value(value)
	var division := division_for_value(value)
	return {
		"current_star_track_value": value,
		"current_star_track_level": level,
		"current_star_track_division": str(division.get("name", "")),
		"division": division,
		"win_gain_value": DEFAULT_WIN_GAIN,
		"lose_loss_value": DEFAULT_LOSE_LOSS,
		"level_threshold_table": build_level_threshold_table(),
		"progress": progress_for_value(value),
		"unlock_tier": unlock_tier_text_for_value(value),
		"match_range": match_range_for_value(value),
	}


static func _unlock_limit_for_value(value: int, hero_count: int) -> int:
	var clean_value := clampi(value, MIN_VALUE, MAX_VALUE)
	if clean_value >= 5000:
		return hero_count
	if clean_value >= 1500:
		return mini(hero_count, 48)
	if clean_value >= 500:
		return mini(hero_count, 35)
	return mini(hero_count, 20)
