extends RefCounted
class_name TurnController

const MovementSystemScript: GDScript = preload("res://scripts/battle/MovementSystem.gd")

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const BASE_STAR_RESTORE := 2
const STAR_TIDE_RESTORE_ROUND_INTERVAL := 3
const MASTER_DAMAGE_BONUS_START_ROUND := 8
const MASTER_DAMAGE_BONUS_ROUND_INTERVAL := 4

var state: BattleState
var first_side: String = SIDE_LEFT
var second_side: String = SIDE_RIGHT
var current_side: String = SIDE_LEFT
var turn_number: int = 1
var side_turns: int = 0
var side_turns_by_side: Dictionary = {
	SIDE_LEFT: 0,
	SIDE_RIGHT: 0,
}
var side_turn_active: bool = false
var last_action_results: Array = []

func _init(battle_state: BattleState = null, initial_first_side: String = SIDE_LEFT) -> void:
	if battle_state != null:
		setup(battle_state, initial_first_side)

func setup(battle_state: BattleState, initial_first_side: String = SIDE_LEFT) -> void:
	state = battle_state
	first_side = initial_first_side
	second_side = _opposite_side(first_side)
	current_side = first_side
	turn_number = 1
	side_turns = 0
	side_turns_by_side = {
		SIDE_LEFT: 0,
		SIDE_RIGHT: 0,
	}
	side_turn_active = false
	last_action_results.clear()
	if state != null:
		state.current_side = current_side
		state.star_tide_master_damage_bonus = get_star_tide_master_damage_bonus()

func start_side_turn() -> Dictionary:
	_require_state()
	state.current_side = current_side
	var restore_amount := get_star_restore_amount()
	var star_power_before: int = state.get_star_power(current_side)
	var star_power_after: int = state.restore_star_power(current_side, restore_amount)
	side_turns += 1
	side_turns_by_side[current_side] = int(side_turns_by_side.get(current_side, 0)) + 1
	side_turn_active = true
	var skill_results: Array = state.trigger_skill_event("turn_start", {"side": current_side})
	var result := {
		"side": current_side,
		"turn_number": turn_number,
		"side_turns": side_turns,
		"star_restore": restore_amount,
		"star_power_before": star_power_before,
		"star_power_after": star_power_after,
		"skill_results": skill_results,
	}
	pass  # EventBus emit moved to BattleScreen
	return result

func act_current_side() -> Array:
	_require_state()
	state.current_side = current_side
	state.star_tide_master_damage_bonus = get_star_tide_master_damage_bonus()
	last_action_results = MovementSystemScript.act_side(state, current_side)
	return last_action_results

func end_side_turn() -> Dictionary:
	_require_state()
	var ended_side := current_side
	var status_results: Array = state.process_end_turn_statuses()
	state.clear_side_turn_effects(ended_side)
	var completed_round := false
	if current_side == first_side:
		current_side = second_side
	else:
		current_side = first_side
		turn_number += 1
		completed_round = true
	side_turn_active = false
	state.current_side = current_side
	state.star_tide_master_damage_bonus = get_star_tide_master_damage_bonus()
	var result := {
		"ended_side": ended_side,
		"next_side": current_side,
		"turn_number": turn_number,
		"completed_round": completed_round,
		"status_results": status_results,
	}
	pass  # EventBus emit moved to BattleScreen
	if completed_round:
		pass  # EventBus emit moved to BattleScreen
	return result

func run_current_side_turn() -> Dictionary:
	var start_result := start_side_turn()
	var action_results := act_current_side()
	var end_result := end_side_turn()
	return {
		"start": start_result,
		"actions": action_results,
		"end": end_result,
	}

func get_completed_rounds() -> int:
	return maxi(0, turn_number - 1)

func get_star_tide_restore_bonus() -> int:
	return get_completed_rounds() / STAR_TIDE_RESTORE_ROUND_INTERVAL

func get_star_restore_amount() -> int:
	return BASE_STAR_RESTORE + get_star_tide_restore_bonus()

func get_star_tide_master_damage_bonus() -> int:
	if turn_number < MASTER_DAMAGE_BONUS_START_ROUND:
		return 0
	return ((turn_number - MASTER_DAMAGE_BONUS_START_ROUND) / MASTER_DAMAGE_BONUS_ROUND_INTERVAL) + 1

func _opposite_side(side: String) -> String:
	if side == SIDE_LEFT:
		return SIDE_RIGHT
	return SIDE_LEFT

func _require_state() -> void:
	assert(state != null, "TurnController requires a BattleState instance.")
