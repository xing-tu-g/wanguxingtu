class_name BattleUITheme
extends RefCounted

const BG_WASH := Color(0.018, 0.024, 0.065, 0.18)
const PANEL_BG := Color(0.018, 0.035, 0.086, 0.92)
const PANEL_BG_STRONG := Color(0.018, 0.035, 0.086, 0.98)
const GOLD := Color(1.0, 0.78, 0.36, 0.92)
const GOLD_SOFT := Color(1.0, 0.84, 0.50, 0.72)
const TEXT_MAIN := Color(0.94, 0.96, 1.0, 1.0)
const TEXT_MUTED := Color(0.70, 0.76, 0.86, 0.82)

const PLAYER_BG := Color(0.035, 0.145, 0.300, 0.98)
const PLAYER_BORDER := Color(0.30, 0.88, 1.00, 0.98)
const ENEMY_BG := Color(0.215, 0.045, 0.080, 0.98)
const ENEMY_BORDER := Color(0.92, 0.22, 0.25, 0.96)

const CELL_BASE := Color(0.055, 0.075, 0.175, 0.70)
const CELL_PLAYER := Color(0.035, 0.205, 0.365, 0.74)
const CELL_ENEMY := Color(0.285, 0.055, 0.090, 0.72)
const CELL_CENTER := Color(0.165, 0.135, 0.245, 0.62)
const CELL_TERRAIN := Color(0.235, 0.205, 0.325, 0.82)
const CELL_SELECTED := Color(0.76, 0.97, 1.00, 1.00)

const CARD_BG := Color(0.040, 0.070, 0.140, 0.96)
const CARD_DISABLED := Color(0.060, 0.065, 0.085, 0.88)
const CARD_READY_BORDER := Color(0.36, 0.94, 1.00, 0.96)
const CARD_SELECTED_BORDER := Color(1.00, 0.82, 0.36, 1.00)
const CARD_DISABLED_BORDER := Color(0.42, 0.43, 0.50, 0.78)
const CARD_RARE_TINT := Color(0.38, 0.58, 0.86, 0.96)
const CARD_EPIC_TINT := Color(0.54, 0.34, 0.78, 0.96)
const CARD_LEGEND_TINT := Color(0.58, 0.44, 0.22, 0.95)
const CARD_RARE_GLOW := Color(0.52, 0.82, 1.00, 1.00)
const CARD_EPIC_GLOW := Color(0.78, 0.50, 1.00, 1.00)
const CARD_LEGEND_GLOW := Color(1.00, 0.78, 0.30, 1.00)

static func panel_style(bg: Color, border: Color, width: int = 3, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_top = 9
	style.content_margin_right = 12
	style.content_margin_bottom = 9
	return style
