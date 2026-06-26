extends RefCounted
class_name StrategyCardSystem

const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")

const CARD_FIRE_ARROW := "fire_arrow"
const CARD_INSPIRE := "inspire"
const CARD_ROCKFALL := "rockfall"
const CARD_SUPPLY := "supply"
const CARD_MARCH := "march"
const CARD_EARTHQUAKE := "earthquake"

const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"


static func play_card(state, side: String, card_id: String, options: Dictionary = {}) -> Dictionary:
	match card_id:
		CARD_FIRE_ARROW:
			state.add_side_turn_effect(side, CARD_FIRE_ARROW, {
				"attack_delta": 2,
				"class": "archer",
				"duration_turns": 1,
			})
			return {"ok": true, "card_id": card_id, "side": side, "attack_delta": 2, "class": "archer"}
		CARD_INSPIRE:
			state.add_side_turn_effect(side, CARD_INSPIRE, {"attack_delta": 2, "duration_turns": 1})
			return {"ok": true, "card_id": card_id, "side": side, "attack_delta": 2}
		CARD_ROCKFALL:
			return _play_rockfall(state, side, options)
		CARD_SUPPLY:
			var healed: int = state.heal_master(side, 10)
			return {"ok": true, "card_id": card_id, "side": side, "healed": healed}
		CARD_MARCH:
			state.add_side_turn_effect(side, CARD_MARCH, {"move_delta": 1, "duration_turns": 1})
			return {"ok": true, "card_id": card_id, "side": side, "move_delta": 1}
		CARD_EARTHQUAKE:
			var left_damage: int = state.apply_master_damage(SIDE_LEFT, 10, 0)
			var right_damage: int = state.apply_master_damage(SIDE_RIGHT, 10, 0)
			return {
				"ok": true,
				"card_id": card_id,
				"left_damage": left_damage,
				"right_damage": right_damage,
			}
		_:
			return {"ok": false, "reason": "unknown_strategy_card"}


static func _play_rockfall(state, side: String, options: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if options.has("seed"):
		rng.seed = int(options.get("seed", 0))
	else:
		rng.randomize()

	var cells := _enemy_half_cells(side)
	_shuffle_with_rng(cells, rng)
	var selected_cells: Array[Vector2i] = []
	var hits: Array = []
	var total_damage := 0
	for cell: Vector2i in cells:
		if selected_cells.size() >= 3:
			break
		selected_cells.append(cell)
		var target: Dictionary = state.board.get_unit_at(cell.x, cell.y)
		if target.is_empty() or int(target.get("hp", 0)) <= 0:
			continue
		var damage: int = state.apply_damage_to_unit(target, 5, "true")
		total_damage += damage
		hits.append({
			"target_id": str(target.get("instance_id", "")),
			"column": cell.x,
			"row": cell.y,
			"damage": damage,
		})

	return {
		"ok": true,
		"card_id": CARD_ROCKFALL,
		"side": side,
		"selected_cells": selected_cells,
		"hits": hits,
		"total_damage": total_damage,
	}


static func _enemy_half_cells(side: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in range(1, BoardModelScript.ROWS + 1):
		var row_cols: int = BoardModelScript.get_cols_for_row(row)
		var min_column := 1
		var max_column := row_cols
		if side == SIDE_LEFT:
			min_column = ceili(float(row_cols) * 0.5) + 1  # 后半场
		else:
			max_column = floori(float(row_cols) * 0.5)  # 前半场
		for column in range(min_column, max_column + 1):
			cells.append(Vector2i(column, row))
	return cells


static func _shuffle_with_rng(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var current_value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value
