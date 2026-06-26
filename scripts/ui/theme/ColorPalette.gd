## 万古星图集中色彩板 — 唯一色彩真源。
## 所有 UI 脚本应从 StarPalette 引用颜色常量，不再散落硬编码 Color()。
class_name StarPalette
extends RefCounted


# ── 全局底色 ──
const STAR_BG         := Color(0.016, 0.027, 0.075, 1.0)
const BG_WASH         := Color(0.025, 0.055, 0.110, 0.58)

# ── 阵营 ──
const FACTION_SHU := Color(0.16, 0.34, 0.22, 1.0)
const FACTION_WEI := Color(0.20, 0.28, 0.46, 1.0)
const FACTION_WU  := Color(0.36, 0.18, 0.18, 1.0)
const FACTION_QUN := Color(0.34, 0.28, 0.16, 1.0)
const FACTION_ANY := Color(0.24, 0.24, 0.28, 1.0)

# ── 三大区域 ──
const ZONE_PLAYER_BG     := Color(0.08, 0.28, 0.62, 1.0)
const ZONE_PUBLIC_BG     := Color(0.42, 0.32, 0.15, 1.0)
const ZONE_ENEMY_BG      := Color(0.46, 0.12, 0.38, 1.0)
const ZONE_PLAYER_BORDER := Color(0.38, 0.76, 1.00, 1.0)
const ZONE_PUBLIC_BORDER := Color(0.98, 0.76, 0.32, 1.0)
const ZONE_ENEMY_BORDER  := Color(1.00, 0.42, 0.76, 1.0)

# ── 单位棋子 ──
const PIECE_PLAYER   := Color(0.05, 0.26, 0.72, 1.0)
const PIECE_ENEMY    := Color(0.68, 0.11, 0.34, 1.0)
const PIECE_NEUTRAL   := Color(0.36, 0.36, 0.36, 1.0)

# ── 棋盘格 ──
const CELL_BORDER      := Color(0.35, 0.35, 0.35, 0.60)
const CELL_OCCUPIED_BG := Color(0.08, 0.08, 0.12, 0.92)
const CELL_DEFAULT_BG  := Color(0.22, 0.22, 0.22, 1.00)

# ── 部署区半透明底 ──
const DEPLOY_ZONE_PLAYER_OVERLAY := Color(0.15, 0.25, 0.55, 0.50)
const DEPLOY_ZONE_ENEMY_OVERLAY  := Color(0.55, 0.15, 0.15, 0.50)
const PUBLIC_ZONE_OVERLAY        := Color(0.18, 0.18, 0.18, 0.45)

# ── 交互高亮 ──
const HIGHLIGHT_SELECTED     := Color(0.42, 1.00, 0.92, 1.0)
const HIGHLIGHT_ACTION       := Color(1.00, 0.78, 0.20, 1.0)
const HIGHLIGHT_DEPLOY       := Color(1.00, 0.82, 0.24, 1.0)
const HIGHLIGHT_EDGE_ROW     := Color(0.44, 0.84, 1.00, 1.0)

# ── 行动方反馈 ──
const ACTIVE_PLAYER_BORDER   := Color(0.58, 0.95, 1.00, 1.0)
const ACTIVE_ENEMY_BORDER    := Color(1.00, 0.58, 0.86, 1.0)
const ACTIVE_PLAYER_BG       := Color(0.028, 0.105, 0.235, 0.97)
const ACTIVE_ENEMY_BG        := Color(0.155, 0.035, 0.135, 0.97)
const ACTIVE_NEUTRAL_BG      := Color(0.060, 0.070, 0.120, 0.97)
const INACTIVE_PLAYER_BORDER := Color(0.46, 0.82, 1.00, 0.98)
const INACTIVE_ENEMY_BORDER  := Color(1.00, 0.56, 0.84, 0.98)
const INACTIVE_PLAYER_BG     := Color(0.028, 0.105, 0.235, 0.97)
const INACTIVE_ENEMY_BG      := Color(0.155, 0.035, 0.135, 0.97)

# ── 兵种边框 ──
const CLASS_WARRIOR  := Color(0.94, 0.68, 0.34, 1.0)
const CLASS_MAGE     := Color(0.62, 0.72, 1.00, 1.0)
const CLASS_TANK     := Color(0.70, 0.92, 0.72, 1.0)
const CLASS_ARCHER   := Color(0.90, 0.86, 0.42, 1.0)
const CLASS_GUARD    := Color(0.78, 0.82, 0.88, 1.0)
const CLASS_ASSASSIN := Color(0.88, 0.56, 0.94, 1.0)
const CLASS_ANY      := Color(0.86, 0.82, 0.70, 1.0)

# ── 文字 ──
const TEXT_PRIMARY     := Color(0.92, 0.95, 1.00, 1.0)
const TEXT_SECONDARY   := Color(0.62, 0.66, 0.74, 0.8)
const TEXT_GOLD        := Color(1.00, 0.96, 0.78, 1.0)
const TEXT_GREEN_READY := Color(0.90, 1.00, 0.92, 1.0)
const TEXT_CREAM       := Color(0.96, 0.93, 0.84, 1.0)

# ── HP 条 ──
const HP_BAR_FULL := Color(0.15, 0.75, 0.15, 0.85)
const HP_BAR_MID  := Color(0.85, 0.75, 0.15, 0.85)
const HP_BAR_LOW  := Color(0.85, 0.20, 0.10, 0.85)
const HP_BAR_BG   := Color(0.10, 0.10, 0.10, 0.70)

# ── 面板样式 ──
const PANEL_TOP_BAR        := Color(0.025, 0.045, 0.105, 0.94)
const PANEL_TOP_BAR_BORDER := Color(0.340, 0.580, 0.880, 0.84)
const PANEL_STATUS         := Color(0.050, 0.090, 0.180, 0.94)
const PANEL_STATUS_BORDER  := Color(0.700, 0.860, 1.000, 0.82)
const PANEL_BOARD          := Color(0.018, 0.038, 0.090, 0.88)
const PANEL_BOARD_BORDER   := Color(0.960, 0.720, 0.300, 0.90)
const PANEL_CARD_ZONE       := Color(0.040, 0.070, 0.130, 0.88)
const PANEL_CARD_ZONE_BORDER := Color(0.800, 0.650, 0.340, 0.72)
const PANEL_DRAWER          := Color(0.030, 0.050, 0.110, 0.94)
const PANEL_DRAWER_BORDER   := Color(0.780, 0.620, 0.340, 0.82)
const PANEL_LOG             := Color(0.030, 0.050, 0.100, 0.94)
const PANEL_LOG_BORDER      := Color(0.460, 0.680, 0.920, 0.82)
const PANEL_TOAST           := Color(0.050, 0.080, 0.150, 0.96)
const PANEL_TOAST_BORDER    := Color(1.000, 0.820, 0.240, 0.94)
const PANEL_DETAIL          := Color(0.030, 0.050, 0.100, 0.95)
const PANEL_DETAIL_BORDER   := Color(0.440, 1.000, 0.900, 0.82)
const PANEL_HINT            := Color(0.035, 0.060, 0.130, 0.95)
const PANEL_HINT_BORDER     := Color(1.000, 0.780, 0.220, 0.88)
const PANEL_OVERLAY_DIM     := Color(0.000, 0.000, 0.000, 0.34)

# ── 地形 ──
const TERRAIN_SWAMP_BG    := Color(0.21, 0.27, 0.14, 1.0)
const TERRAIN_RIVER_BG    := Color(0.08, 0.28, 0.46, 1.0)
const TERRAIN_HIGHLAND_BG := Color(0.48, 0.34, 0.14, 1.0)

# ── 辅助 ──
## 根据阵营 id 返回颜色
static func faction_color(faction_id: String) -> Color:
	match faction_id:
		"shu": return FACTION_SHU
		"wei": return FACTION_WEI
		"wu":  return FACTION_WU
		"qun": return FACTION_QUN
		_:     return FACTION_ANY

## 根据兵种 id 返回边框色
static func class_border(class_id: String) -> Color:
	match class_id:
		"warrior":  return CLASS_WARRIOR
		"mage":     return CLASS_MAGE
		"tank":     return CLASS_TANK
		"archer":   return CLASS_ARCHER
		"guard":    return CLASS_GUARD
		"assassin": return CLASS_ASSASSIN
		_:          return CLASS_ANY

## 根据行动方返回活跃边框色
static func active_border(side: String) -> Color:
	return ACTIVE_PLAYER_BORDER if side == "left" else ACTIVE_ENEMY_BORDER

## 根据行动方返活跃背景色
static func active_bg(side: String) -> Color:
	return ACTIVE_PLAYER_BG if side == "left" else ACTIVE_ENEMY_BG

## 根据行动方返回非活跃边框色
static func inactive_border(side: String) -> Color:
	return INACTIVE_PLAYER_BORDER if side == "left" else INACTIVE_ENEMY_BORDER

## 根据行动方返回非活跃背景色
static func inactive_bg(side: String) -> Color:
	return INACTIVE_PLAYER_BG if side == "left" else INACTIVE_ENEMY_BG
