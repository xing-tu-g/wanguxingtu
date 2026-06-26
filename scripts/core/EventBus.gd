extends Node
## Global event bus for cross-scene, decoupled communication.
## Registered as Autoload — available in all scenes.
##
## Convention: All signals use snake_case with typed parameters.
## Dictionary parameters MUST document expected keys in doc comments.
## Add signals here ONLY for events that genuinely span multiple scenes
## or need to notify unknown listeners (animation, audio, UI, stats).

# ── Screen / Route ────────────────────────────────────────────────────

## Emitted when the active screen changes via ScreenRouter.
## [param screen_data] is optional data passed to the target screen (e.g. battle_result).
signal screen_changed(scene_path: String, screen_data: Dictionary)


# ── Battle Lifecycle ──────────────────────────────────────────────────

## Emitted when a new battle starts. [param config] contains
## { "enemy_config": Dictionary, "terrain_pool": Array, ... }.
signal battle_started(config: Dictionary)

## Emitted when the current battle ends.
## [param victory_side] is "left" (player) or "right" (enemy).
## [param stats] is a BattleStats snapshot.
signal battle_ended(victory_side: String, stats: Dictionary)


# ── Turn / Round ──────────────────────────────────────────────────────

## Emitted at the start of each side-turn.
## [param side] is "left" or "right".
## [param turn_info] contains { "turn_number": int, "star_restore": int, ... }.
signal side_turn_started(side: String, turn_info: Dictionary)

## Emitted at the end of each side-turn.
## [param side] is "left" or "right".
## [param end_info] contains { "completed_round": bool, "next_side": String, ... }.
signal side_turn_ended(side: String, end_info: Dictionary)

## Emitted when a full round (both sides) completes.
signal turn_completed(turn_number: int)


# ── Unit Events ───────────────────────────────────────────────────────

## Emitted when a hero is deployed to the board.
signal unit_deployed(unit: Dictionary, side: String, cost: int)

## Emitted after a unit moves. [param unit] is the updated unit dict.
signal unit_moved(unit: Dictionary, target_column: int, target_row: int)

## Emitted when a unit deals damage to another unit.
signal unit_attacked(attacker: Dictionary, target: Dictionary, damage: int)

## Emitted when a unit receives damage (before death check).
signal unit_damaged(unit: Dictionary, damage: int)

## Emitted when a unit's hp reaches 0 and is removed.
signal unit_died(unit: Dictionary)


# ── 奕星师 (Master) ──────────────────────────────────────────────────

## Emitted when the 奕星师 takes damage.
## [param remaining_hp] is current hp after damage.
signal master_damaged(side: String, damage: int, remaining_hp: int)


# ── Resources ─────────────────────────────────────────────────────────

## Emitted whenever star power changes on either side.
signal star_power_changed(side: String, amount: int)


# ── Save / Load ───────────────────────────────────────────────────────

## Emitted after a save is written to disk.
signal game_saved()

## Emitted after a save is loaded from disk.
signal game_loaded()
