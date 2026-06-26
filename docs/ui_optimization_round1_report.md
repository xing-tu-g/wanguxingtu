# UI 优化第一轮完成报告

日期：2026-06-26 | 版本：v0.1-M88 | 验证：godot --headless --quit 零错误

---

## 完成项目：T1-1 + T1-2 + T2-1

| 编号 | 项目 | 状态 |
|------|------|------|
| T1-1 | StyleBoxFlat 缓存池 | ✅ |
| T1-2 | 集中色彩板 ColorPalette | ✅ |
| T2-1 | 发光脉冲 Shader | ✅ |

---

## T1-2: 集中色彩板

**新建文件**：`scripts/ui/theme/ColorPalette.gd`

- 70+ 颜色常量，分 13 个语义组
- 6 个静态方法：`faction_color()` / `class_border()` / `active_border()` / `active_bg()` / `inactive_border()` / `inactive_bg()`
- BattleScreen.gd 约 80 处内联 Color 替换为 ColorPalette 引用
- BattleBoardView.gd 8 个常量移除，引用 ColorPalette

---

## T2-1: 发光脉冲 Shader

**新建文件**：`assets/shaders/glow_pulse.gdshader`

- `shader_type canvas_item` + `render_mode blend_premul_alpha`
- 亮度驱动呼吸脉冲：`lum * sin(TIME * speed) * intensity`
- 3 个 uniform（全部带 hint）：pulse_speed / glow_intensity / glow_color

**ShaderMaterial 应用**：
- 活跃方 MasterPanel（玩家蓝呼吸 / 敌方粉呼吸）
- `_refresh_master_panel_styles()` 中动态切换：活跃方挂 shader，非活跃方移除
- 视觉反馈：当前行动方的盔甲框持续脉冲发光，回合切换瞬间感知

---

## T1-1: StyleBoxFlat 缓存池

| 方法 | 优化前 | 优化后 |
|------|--------|--------|
| `_update_advance_turn_button()` | 每帧 `StyleBoxFlat.new()` ×1 | 复用 `_advance_style`，只改 bg/border |
| `_apply_hand_piece_button_style()` | 每帧 `StyleBoxFlat.new()` ×N（N=手牌数） | `_build_hero_buttons()` 预创建 per-hero 缓存，运行时 mutate |
| `_apply_master_panel_style()` | 每帧 `StyleBoxFlat.new()` ×2 | 预创建 4 变体直接赋值 |
| `_apply_panel_style()` | `_ready()` 中 `new()` ×11 | lazy-create per-node-path 缓存，后续复用 |
| `_apply_button_overlay_style()` | `StyleBoxFlat.new()` ×1 | 复用 `_overlay_button_style` |

**热路径 StyleBoxFlat.new() 调用**：每帧 ~8+ → **0**

---

## 附带修复

- **EventBus 导航统一**：BattleScreen `_return_home()` / `_route_to_result()` 改用 `EventBus.screen_changed.emit()`
- **信号扩展**：`screen_changed` 新增 `screen_data: Dictionary = {}` 参数，支持导航传参
- **ScreenRouter**：`_on_screen_changed` 适配双参数

---

## 修改清单

| 文件 | 操作 |
|------|------|
| `scripts/ui/theme/ColorPalette.gd` | 新增 |
| `assets/shaders/glow_pulse.gdshader` | 新增 |
| `scripts/ui/BattleScreen.gd` | 修改（~90 处） |
| `scripts/ui/BattleBoardView.gd` | 修改（8 处） |
| `scripts/core/EventBus.gd` | 修改（1 信号签名） |
| `scripts/ui/ScreenRouter.gd` | 修改（1 回调签名） |

---

## 下一步：第二轮（T1-3 + T2-2 + T2-3）

1. T1-3: 标题/大字自适应字号（FontScale 类）
2. T2-2: 背景图像景深 Shader（depth_fade.gdshader）
3. T2-3: 屏幕转场 0.2s 淡入淡出（ScreenRouter Tween）
