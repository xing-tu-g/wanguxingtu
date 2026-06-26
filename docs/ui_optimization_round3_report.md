# 万古星图 UI 优化 第三轮报告

版本：v0.1-M87 → M88  
日期：2026-06-26  
状态：✅ 全部完成，headless 零错误

---

## 完成项

### T3-1: CardZoneView / BattleLogView RefCounted → Node

| 变更 | 说明 |
|------|------|
| `extends RefCounted` → `extends Node` | 解锁 `create_tween()`、原生信号、`@onready` |
| `card_zone_view` / `battle_log_view` | BattleScreen 中 `add_child()` 添加到场景树 |
| 回调 dict → 原生信号 | `visibility_changed(collapsed)` / `card_selected(hero_id)` / `changed` |
| `_create_view_nodes()` | 新方法，集中创建 View 子节点 |

**消减**：
- CardZoneView: 移除 `"_changed"` 回调 dict key，改为 `.changed.connect()`
- BattleLogView: 移除 `changed_callback: Callable` 参数，改为 `.visibility_changed.connect()`
- BattleScreen: `_on_battle_log_view_changed` → `_on_battle_log_visibility_changed(_collapsed: bool)` 信号驱动
- BattleScreen: 新增 `_on_card_zone_card_selected(hero_id: String)` 信号回调

### T2-4: 手牌 Drawer 展开/收起动画

CardZoneView 新增 `_animate_drawer_open()` / `_animate_drawer_close()`：

- **展开**：淡入 0.22s (EASE_OUT) + 向下滑入 18px (TRANS_CUBIC)
- **收起**：淡出 0.15s (EASE_IN) + 向上移 18px → callback 中 `visible = false` 并复位坐标
- 动画期间自动 kill 上一个 tween 防止重叠

### T3-3: ShaderMaterial 独立 .tres 库

新建 `assets/shaders/materials/` 目录，4 个资源文件：

| 文件 | 用途 | 关键参数 |
|------|------|---------|
| `glow_pulse_player.tres` | 玩家 MasterPanel 呼吸蓝光 | pulse=1.5, intensity=0.7, color=蓝 |
| `glow_pulse_enemy.tres` | 敌方 MasterPanel 呼吸粉光 | pulse=1.5, intensity=0.7, color=粉 |
| `depth_fade_battle.tres` | 战斗背景景深 | blur=1.0, vignette=0.28 |
| `depth_fade_home.tres` | 首页背景景深 | blur=2.0, vignette=0.45 |

BattleScreen/HomeScreen 移除 `ShaderMaterial.new()` + `set_shader()` 热路径，改为 `preload()` 常量。

### T3-2: 统一 Theme .tres 资源

新建 `assets/theme/default_theme.tres`：

- Button/Label/Panel/RichTextLabel 默认 `font_color` 设为 `TEXT_PRIMARY`
- 默认 `font_size` 设为 22（Button/Label/Panel）/ 22（RichTextLabel normal_font_size）
- BattleScreen: `theme = THEME_DEFAULT` → 移除 `_apply_label_colors()` 和递归方法（约 15 行）
- HomeScreen: `theme = THEME_DEFAULT` → 同样受益

### ColorPalette → StarPalette 重命名

Godot 4.7 内置 `ColorPalette` 类，导致 parse error。class_name 改为 `StarPalette`，文件名保持 `ColorPalette.gd`（避免破坏所有 preload 路径）。

---

## 文件变更清单

| 操作 | 文件 |
|------|------|
| 🔄 重写 | `scripts/ui/CardZoneView.gd` |
| 🔄 重写 | `scripts/ui/BattleLogView.gd` |
| 🔄 修改 | `scripts/ui/BattleScreen.gd`（≈30 处编辑） |
| 🔄 修改 | `scripts/ui/BattleBoardView.gd` |
| 🔄 修改 | `scripts/ui/HomeScreen.gd` |
| 🔄 修改 | `scripts/ui/theme/ColorPalette.gd`（class_name 改名） |
| ✨ 新增 | `assets/shaders/materials/glow_pulse_player.tres` |
| ✨ 新增 | `assets/shaders/materials/glow_pulse_enemy.tres` |
| ✨ 新增 | `assets/shaders/materials/depth_fade_battle.tres` |
| ✨ 新增 | `assets/shaders/materials/depth_fade_home.tres` |
| ✨ 新增 | `assets/theme/default_theme.tres` |

---

## 验证

`godot --headless --quit`：**零错误** ✅
