# UI 优化第二轮完成报告

日期：2026-06-26 | 版本：v0.1-M89 | 验证：godot --headless --quit 零错误

---

## 完成项目：T1-3 + T2-2 + T2-3

| 编号 | 项目 | 状态 |
|------|------|------|
| T1-3 | 自适应字号 FontScale | ✅ |
| T2-2 | 背景景深 Shader depth_fade | ✅ |
| T2-3 | 屏幕转场 0.2s 淡入淡出 | ✅ |

---

## T1-3: 自适应字号

**新建文件**：`scripts/ui/theme/FontScale.gd`

- `title_size(vw)` — 标题范围 36-62
- `body_size(vw)` — 正文范围 18-28
- `label_size(vw)` — 小字范围 12-22
- `hand_card_size(vw)` — 手牌范围 20-30

**集成**：
- **HomeScreen**: 标题、副标题、版本号、4 个货币标签
- **BattleScreen**: 顶部标题、回合标签、星力标签
- **ResultScreen**: 标题、正文

**技术细节**：`class_name FontScale` 因 Godot 4.7 解析顺序不注册，改用 `const FontScaleScript = preload(...)` 显式加载后调用静态方法。

---

## T2-2: 背景景深 Shader

**新建文件**：`assets/shaders/depth_fade.gdshader`

- `shader_type canvas_item` + `render_mode blend_mix`
- 3 个 uniform：`blur_amount` / `vignette_strength` / `tint_color`（全部带 hint）
- 5-tap 十字高斯模糊（4 方向 + 中心，总 5 次采样 — 移动端安全）
- 径向暗角：`1.0 - dot(UV_centered, UV_centered) * strength * 2.0`
- 色调叠加：背景色与 tint 插值，alpha 控制强度

**应用**：
- **HomeBackgroundImage**：blur=1.2, vignette=0.40, tint=(0.04,0.08,0.18,0.32)
- **BattleBackgroundImage**：blur=1.0, vignette=0.28, tint=(0.03,0.06,0.14,0.28)

首页背景更模糊更有"场景入口"感，战斗背景轻度模糊保持可读性。

---

## T2-3: 屏幕转场动画

**修改文件**：`ScreenRouter.gd`

- 新增 `FADE_OUT_DURATION = 0.15`, `FADE_IN_DURATION = 0.20`
- 新增 `_transitioning` 防重入标志
- `show_screen()` 拆分为：
  1. 旧页面 Tween `modulate:a` → 0（0.15s），期间 `mouse_filter = IGNORE`
  2. `_swap_screens()` → remove_child + queue_free 旧页面
  3. `_add_and_fade_in()` → 新页面 modulate.a=0 入树 → Tween → 1.0（0.20s）
  4. `_on_transition_done()` → 释放 `_transitioning` 锁
- 无旧页面时（初始加载）直接 fade-in，无等待

**安全特性**：
- 转场进行中重复调用 show_screen → 直接 return + push_warning
- 旧页面在淡出期间禁用鼠标交互，防止误触

---

## 修改清单

| 文件 | 操作 |
|------|------|
| `scripts/ui/theme/FontScale.gd` | 新增 |
| `assets/shaders/depth_fade.gdshader` | 新增 |
| `scripts/ui/HomeScreen.gd` | 修改（+预加载、+深度模糊、+字体缩放） |
| `scripts/ui/BattleScreen.gd` | 修改（+预加载、+深度模糊、+字体缩放） |
| `scripts/ui/ResultScreen.gd` | 修改（+预加载、+字体缩放） |
| `scripts/ui/ScreenRouter.gd` | 重写 show_screen（Tween 转场） |

---

## 下一步：第三轮（T2-4 + T3 系列）

1. T2-4: 手牌展开动画（CardZone drawer 滑入/滑出）
2. T3-1: CardZoneView / BattleLogView 重构为 Node
3. T3-2: 统一 Theme 资源系统
4. T3-3: ShaderMaterial .tres 资源库
