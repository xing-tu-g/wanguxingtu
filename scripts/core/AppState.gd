extends Node
## Persistent player state singleton (Autoload).
## Holds player name, master level, and economy currencies.
## Reset between sessions via _reset_defaults().

var player_name: String = "玩家"
var master_level: int = 1

# ── Economy (MVP placeholder) ────────────────────────────────────────

## Gold earned from battles, used for upgrades (future feature).
var gold: int = 0

## Star stone — rare currency for premium unlocks (future feature).
var star_stone: int = 0

## Lifetime battles fought.
var battles_fought: int = 0


func _ready() -> void:
	_reset_defaults()


func _reset_defaults() -> void:
	player_name = "玩家"
	master_level = 1
	gold = 0
	star_stone = 0
	battles_fought = 0


func earn_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)


func earn_star_stone(amount: int) -> void:
	star_stone = maxi(0, star_stone + amount)


func record_battle() -> void:
	battles_fought += 1


func snapshot() -> Dictionary:
	return {
		"player_name": player_name,
		"master_level": master_level,
		"gold": gold,
		"star_stone": star_stone,
		"battles_fought": battles_fought,
	}
