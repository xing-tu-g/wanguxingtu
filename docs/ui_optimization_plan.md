# 万古星图 UI 优化计划

版本：v0.1-M87  
创建时间：2026-06-26  
当前状态：M86 战斗界面可视化已完成（立绘 + HP 显示），现规划视觉优化。

---

## 基线评估

### 当前优势

| 项目 | 状态 |
|---|---|
| 核心布局 | 单屏双栏三区 (TopBar / DuelArea / BottomHand)，结构清晰 |
| 分区着色 | 玩家蓝 / 敌方粉 / 公共金，视觉辨识度高 |
| 武将立绘 | TextureRect 加载 portrait 资源，19/21 有图 |
| 交互反馈 | 选卡高亮、部署失败 Toast、可部署格金边推荐 |
| 风格统一 | 全部 StyleBoxFlat 代码驱动，零外部主题依赖（可控性好） |

### 当前薄弱点

| 问题 | 严重度 | 说明 |
|---|---|---|
| 零 Shader 效果 | 高 | 背景图无后期处理，HUD 元素无发光/脉冲/呼吸，整体偏"原型感" |
| StyleBoxFlat 热路径重建 | 中 | `_update_advance_turn_button()`、`refresh()` 每帧 new StyleBoxFlat |
| 无主题系统 | 中 | 30+ 硬编码 Color 常量，色彩体系无法切换 |
| 无过渡动画 | 中 | ScreenRouter 直接 remove/add_child，瞬间切换 |
| CardZone/Log View 是 RefCounted | 中 | 无法在场景树实例化、无法使用 @onready/信号，通信靠 callback dict |
| 手动代码布局 | 低 | Hero button、cell container 全部 `Vector2()` 硬编码尺寸 |
| 字体无统一梯级 | 低 | font_size 分散在节点 override 和代码 push 中 |

---

## 分层优化计划

### Tier 1 — 低投入高回报（1-3 天）

#### T1-1: StyleBoxFlat 缓存池
**目标**：消除 per-frame GC 分配。

当前 `_update_advance_turn_button()` 每次调用都 `StyleBoxFlat.new()`。改为 `_ready()` 中预创建 2-3 个 StyleBoxFlat 缓存，运行时只改属性：

```gdscript
# _ready() 中预创建
var _advance_style: StyleBoxFlat = StyleBoxFlat.new()
var _advance_style_hover: StyleBoxFlat = StyleBoxFlat.new()

func _update_advance_turn_button() -> void:
    _advance_style.bg_color = _side_feedback_bg_color(current_side).lightened(0.16)
    _advance_style.border_color = _active_side_feedback_color(current_side)
    # ... 不 new，只 mutate 已有对象
```

同理 `_apply_hand_piece_button_style()` — 为 hero_button 缓存每种状态 style（selected/enabled_affordable/enabled_poor/disabled）。

**涉及文件**：`BattleScreen.gd`

---

#### T1-2: 集中色彩板
**目标**：减少魔法颜色散落，为后续主题切换打基础。

创建 `scripts/ui/theme/ColorPalette.gd`（Autoload 或 static 类）：

```gdscript
class_name ColorPalette
extends RefCounted

# 阵营色
const FACTION_SHU := Color(0.16, 0.34, 0.22, 1.0)
const FACTION_WEI := Color(0.20, 0.28, 0.46, 1.0)
const FACTION_WU  := Color(0.36, 0.18, 0.18, 1.0)
const FACTION_QUN := Color(0.34, 0.28, 0.16, 1.0)

# 区域色
const ZONE_PLAYER_BG := Color(0.08, 0.28, 0.62, 1.0)
const ZONE_PUBLIC_BG := Color(0.42, 0.32, 0.15, 1.0)
const ZONE_ENEMY_BG  := Color(0.46, 0.12, 0.38, 1.0)

# 交互反馈
const HIGHLIGHT_SELECTED := Color(0.42, 1.0, 0.92, 1.0)
const HIGHLIGHT_ACTION   := Color(1.0, 0.78, 0.20, 1.0)

# 文字
const TEXT_PRIMARY   := Color(0.92, 0.95, 1.0, 1.0)
const TEXT_SECONDARY := Color(0.62, 0.66, 0.74, 0.8)
```

BattleScreen 和 BattleBoardView 中的 30+ Color 常量全部迁移引用 ColorPalette。

**涉及文件**：新增 `ColorPalette.gd`，修改 `BattleScreen.gd`、`BattleBoardView.gd`

---

#### T1-3: 标题/大字自适应字号
**目标**：修复固定 pixel 字号在不同分辨率下过大/过小。

新增 `scripts/ui/theme/FontScale.gd`：

```gdscript
class_name FontScale
extends RefCounted

## 根据窗口宽度返回缩放后字号
static func title_size() -> int:
    return clampi(int(get_viewport().size.x / 18.0), 36, 62)

static func body_size() -> int:
    return clampi(int(get_viewport().size.x / 48.0), 18, 28)
```

在 `_refresh()` 中替换硬编码的 `theme_override_font_sizes/font_size`。

**涉及文件**：新增 `FontScale.gd`，修改 `HomeScreen.tscn`、`BattleScreen.gd`、`ResultScreen.gd`

---

### Tier 2 — 视觉质感提升（3-5 天）

#### T2-1: CanvasItem Shader 发光边框
**目标**：关键 HUD 元素（当前行动方面板、选中的手牌）添加呼吸发光。

实现一个 `glow_pulse.gdshader`：

```glsl
shader_type canvas_item;

uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.6;
uniform vec4 glow_color : source_color = vec4(0.44, 0.84, 1.0, 1.0);

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

    // 内发光：颜色越浅的区域发光越强
    float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
    float glow = lum * pulse * glow_intensity;

    COLOR = base + glow_color * glow * base.a;
}
```

应用到：
- 当前行动方 MasterPanel → 蓝色/粉色呼吸
- 选中的英雄手牌 → 绿色脉冲
- 可部署推荐格 → 金色呼吸

**涉及文件**：新增 `assets/shaders/glow_pulse.gdshader`，修改 `BattleScreen.gd`

---

#### T2-2: 背景图像景深 + 色阶
**目标**：首页背景和战斗背景不再"平"，增加层次感。

实现一个 `depth_fade.gdshader`（CanvasItem）：

```glsl
shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 4.0) = 1.5;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 tint_color : source_color = vec4(0.05, 0.08, 0.18, 0.3);

void fragment() {
    vec4 base = texture(TEXTURE, UV);

    // 简单高斯模糊（4 采样 + 中心）
    vec2 texel = TEXTURE_PIXEL_SIZE * blur_amount;
    vec4 blurred = base * 0.4;
    blurred += texture(TEXTURE, UV + vec2( texel.x, 0.0)) * 0.15;
    blurred += texture(TEXTURE, UV + vec2(-texel.x, 0.0)) * 0.15;
    blurred += texture(TEXTURE, UV + vec2(0.0,  texel.y)) * 0.15;
    blurred += texture(TEXTURE, UV + vec2(0.0, -texel.y)) * 0.15;

    // 暗角
    vec2 uv_centered = UV - 0.5;
    float vignette = 1.0 - dot(uv_centered, uv_centered) * vignette_strength * 2.0;
    vignette = clamp(vignette, 0.0, 1.0);

    // 合成
    vec4 result = blurred * vignette;
    result = mix(result, tint_color, tint_color.a);
    result.a = base.a;

    COLOR = result;
}
```

应用到 `BattleBackgroundImage` 和 `HomeBackgroundImage`。可以通过 uniform 控制是否启用，在低端设备上关闭。

**涉及文件**：新增 `assets/shaders/depth_fade.gdshader`，修改 `HomeScreen.tscn`、`BattleScreen.tscn`

---

#### T2-3: 屏幕转场动画
**目标**：ScreenRouter 切换页面添加 0.3s 淡入淡出。

```gdscript
func show_screen(scene_path: String, screen_data: Dictionary = {}) -> void:
    if current_screen != null:
        var old := current_screen
        var tween := create_tween()
        tween.tween_property(old, "modulate:a", 0.0, 0.15)
        tween.tween_callback(func():
            remove_child(old)
            old.queue_free()
        )

    # ... instantiate new screen
    current_screen.modulate.a = 0.0
    add_child(current_screen)
    var tween_in := create_tween()
    tween_in.tween_property(current_screen, "modulate:a", 1.0, 0.2)
```

**涉及文件**：`ScreenRouter.gd`

---

#### T2-4: 手牌展开/收起动画
**目标**：CardZone drawer 展开时不是瞬间显示，而是向下滑入。

在 CardZoneView 中使用 Tween：

```gdscript
func update_visibility() -> void:
    if drawer_panel == null:
        return
    if not collapsed:
        drawer_panel.visible = true
        var tween := drawer_panel.create_tween()
        drawer_panel.modulate.a = 0.0
        drawer_panel.position.y -= 20.0
        tween.parallel().tween_property(drawer_panel, "modulate:a", 1.0, 0.2)
        tween.parallel().tween_property(drawer_panel, "position:y", drawer_panel.position.y + 20.0, 0.2)
    # (collapsed 时反向)
```

但 CardZoneView 目前是 RefCounted，无法调 create_tween()。需要给它传入一个 Node 引用用于 tween 创建。

**涉及文件**：`CardZoneView.gd`（需改为 Node 或传入 Tween 宿主引用）

---

### Tier 3 — 架构重构（5-8 天）

#### T3-1: CardZoneView / BattleLogView 重构为 Node
**当前问题**：这两个 View 是 RefCounted，所有 node 引用通过 setup() 手动传入，信号通过 callback dict 模拟。无法使用：
- `@onready` 缓存
- 原生信号声明
- Tween 动画（create_tween 是 Node 方法）
- `_process()` 生命周期

**方案**：将它们改为 `extends Node`，BattleScreen 通过 `@onready` 获取，子节点用 `$` 路径：

```gdscript
class_name CardZoneView
extends Node

signal changed

@onready var card_zone_label: Label = $"../CardZonePanel/CardZoneLabel"
@onready var toggle_button: Button = $"../CardZonePanel/.../CardZoneToggleButton"
# ... 自动注入全部子节点

func _ready() -> void:
    toggle_button.pressed.connect(toggle)
    close_button.pressed.connect(close)
```

**影响范围**：`CardZoneView.gd`、`BattleLogView.gd`、`BattleScreen.gd`、`BattleScreen.tscn`。
**风险**：View 现在是 BattleScreen 的代码子节点，需要通过 add_child 动态添加，tscn 结构需要调整。

**替代方案**（低风险）：保持 RefCounted，但在 setup() 时额外传入一个 `tween_host: Node`（即 BattleScreen），View 内部通过 `tween_host.create_tween()` 创建动画。

---

#### T3-2: 统一主题系统
**目标**：一个 Theme 资源文件 (`res://assets/theme/default_theme.tres`) 承载全部 UI 样式，不再零散覆盖。

```ini
# default_theme.tres (Godot Theme Resource)
[resource]
Button/colors/font_color = Color(0.92, 0.95, 1.0, 1.0)
Button/font_sizes/font_size = 24
Panel/colors/font_color = Color(0.92, 0.95, 1.0, 1.0)
Panel/styles/panel = SubResource("StyleBoxFlat_panel_default")
Label/colors/font_color = Color(0.92, 0.95, 1.0, 1.0)
Label/font_sizes/font_size = 22
```

BattleScreen._ready() 中 `theme = preload("res://assets/theme/default_theme.tres")`。

然后删除 `_apply_visual_placeholder_theme()` 和 `_apply_label_colors()` 中 90% 的代码，只保留节点特有的 StyleBox 差异。

**涉及文件**：新增 `default_theme.tres`，缩减 `BattleScreen.gd` 约 80 行

---

#### T3-3: 独立 ShaderMaterial 库
**目标**：可复用 ShaderMaterial 作为 .tres 资源，节点上直接 `material = preload(...)`。

| 资源 | 用途 |
|---|---|
| `glow_pulse_active.tres` | 当前行动方面板呼吸光 |
| `glow_pulse_selected.tres` | 选中手牌/选中格 |
| `glow_pulse_highlight.tres` | 可部署推荐格 |
| `depth_fade_battle.tres` | 战斗背景景深 |
| `depth_fade_home.tres` | 首页背景景深 |
| `card_border_glow.tres` | CardZone 卡片选中态 |

每个 .tres 内封好 uniform 默认值，代码中直接 `material.set_shader_parameter("pulse_speed", 3.0)`。

**涉及文件**：新增 6 个 `.tres`，修改 `BattleScreen.gd`

---

### 实施优先级总览

```
T1-1: StyleBoxFlat 缓存池     ████████░░  P0 (性能)
T1-2: 集中色彩板              ████████░░  P0 (可维护性)
T1-3: 自适应字号              ██████░░░░  P1 (多分辨率)

T2-1: 发光边框 Shader          ██████░░░░  P1 (视觉)
T2-2: 背景景深 Shader          █████░░░░░  P1 (视觉)
T2-3: 屏幕转场动画              █████░░░░░  P2 (体验)
T2-4: 手牌展开动画              ████░░░░░░  P2 (体验)

T3-1: View 重构为 Node          ███░░░░░░░  P3 (架构)
T3-2: 统一主题系统              ██░░░░░░░░  P3 (架构)
T3-3: ShaderMaterial 库         ██░░░░░░░░  P3 (可维护)
```

---

### 推荐开工顺序

**第一轮（本周，2 天）**：T1-1 + T1-2 + T2-1
- StyleBoxFlat 缓存消除每帧 GC
- 集中色彩板清理魔法颜色
- 发光 Shader 给关键反馈加"质感"——这是从"原型"到"产品"最有感知价值的单步改动

**第二轮（下周，2 天）**：T1-3 + T2-2 + T2-3
- 字号自适应解决多分辨率
- 背景景深增加层次感
- 转场淡入消除"闪切"感

**第三轮（后续，按需）**：T2-4 + T3 系列
- 架构重构在功能稳定后再做，避免影响战斗逻辑调试
