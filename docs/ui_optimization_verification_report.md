# UI 优化验证报告

**日期**: 2026-06-26 | **项目**: 万古星图 | **引擎**: Godot 4.7 (gl_compatibility)

---

## 完整启动验证

```
$ godot --headless --quit
→ 万古星图启动：ScreenRouter ready，初始页面=res://scenes/ui/HomeScreen.tscn
→ 万古星图首页 ready
→ Exit 0 ✅  零错误
```

---

## 测试矩阵

| 测试编号 | 名称 | 结果 | 说明 |
|---------|------|------|------|
| **M43** | master HUD glow check | ✅ PASS | Shader 发光 + 回合切换 + 边框样式全验证 |
| **M75** | battle log view split | ✅ PASS | Node 重构 + class_name + signal 连接 |
| **M76** | card zone view split | ✅ PASS | Node 重构 + class_name + signal 连接 |
| **M6a** | battle screen smoke | ✅ PASS | BattleScreen 完整实例化 + 战斗逻辑 |
| **M42** | hand bar hierarchy | ✅ PASS | 手牌选中/视觉切换/布局层级 |
| **M6b** | turn button smoke | ✅ PASS | ~~status_label/turn_info_label 同节点~~ → 已修复（移除冗余 turn_info_label） |
| **M6c** | result flow | ✅ PASS | ~~Script.new() 无场景树~~ → 重写为 .tscn 实例化模式 |
| **M41** | board visual refinement | ✅ PASS | ~~UnitDetailPanel 路径缺 DetailLayout + 文本断言未适配 M85~~ → 两处修复 |

---
## 第二轮修复：遗留问题修复（2026-06-26 晚）

### 修复 1: status_label/turn_info_label 同节点冲突
- **根因**: `status_label` (line 85) 和 `turn_info_label` (line 92) 都指向 `$TopBar/.../TurnLabel`
- _ `_update_status()` 中 status_label.text 写入后被 turn_info_label.text 立即覆盖
- **修复**: 移除 `turn_info_label` 变量及其赋值——`star_label` 已提供回合/行动方信息
- **文件**: `BattleScreen.gd`

### 修复 2: UnitDetailPanel → DetailBody 路径缺 DetailLayout
- **根因**: line 116 路径跳过了 DetailLayout 中间层 (`DetailMargin/DetailScroll` → 应为 `DetailMargin/DetailLayout/DetailScroll`)
- **影响**: BattleScreen 场景实例化时报 `Node not found`，导致 M41 测试完全崩溃
- **修复**: 补全路径 `$UnitDetailPanel/DetailMargin/DetailLayout/DetailScroll/DetailBody`
- **文件**: `BattleScreen.gd` line 116

### 修复 3: M6c 测试 Script.new() → .tscn 实例化
- **根因**: `BattleScreenScript.new()` 不包含场景子节点，所有 @onready 报错
- **修复**: 重写为 `BattleScreenScene.instantiate()` / `ResultScreenScene.instantiate()` 模式
- **额外适配**: 移除对 EventBus 的隐式依赖（直接测试 `_check_battle_end()` 返回值 + ResultScreen 渲染）
- **文件**: `tests/m6c_result_flow_check.gd`

### 修复 4: M41 测试适配 M85 BoardView 重构
- **根因**: M85 将区的文字标签（"蓝区"/"中域"/"红区"）改为背景色，空格的 `cell_buttons[key].text` 变为 `""`
- **修复**: 断言改为检查 `StyleBoxFlat.bg_color` 色调 + `HpLabel` 子节点 + 占位格的 hero_id
- **文件**: `tests/m41_board_visual_refinement_check.gd`

---

## 本轮修复的 3 个回退问题

### 1. UTF-8 BOM 导致 lexer 错误 `□`
- **文件**: `BattleScreen.gd`
- **原因**: Write 工具写入时附带了 UTF-8 BOM (0xEF 0xBB 0xBF)
- **修复**: PowerShell 剥离 BOM 头部
- **影响**: 所有 `--script` 测试无法解析 BattleScreen.gd

### 2. Autoload 命名冲突 `class_name AppState`
- **文件**: `AppState.gd`
- **原因**: Godot 4.7 不允许 `class_name` 与 Autoload 同名
- **修复**: 移除 `class_name`，改用 `@onready var _app_state = get_node("/root/AppState")`（Android 安全模式）
- **影响文件**: `BattleScreen.gd`, `HomeScreen.gd`, `ResultScreen.gd`

### 3. `--script` 模式下 `SaveService` 无法解析
- **文件**: `BattleScreen.gd`, `HomeScreen.gd`
- **原因**: Godot 4.7 `--script` 模式不解析 Autoload 名
- **修复**: 添加 `const SaveServiceScript = preload("res://scripts/core/SaveService.gd")` 替代裸引用

---

## 已知遗留问题

**本轮 3 个遗留问题已全部修复。** 无新增问题。

---

## 结论

**三项 UI 优化轮次 (T1-1 ~ T3-3) 全部完成。8/8 测试通过，headless 启动零错误。** 3 个预先存在的遗留问题已在第二轮修复中全部解决。
