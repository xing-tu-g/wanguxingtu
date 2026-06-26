# 万古星图续接入口

只保留最近状态，避免长会话反复读取完整 `docs/HANDOFF.md`。

## 当前状态

- 当前阶段：M85 战斗界面可视化升级完成。
- 当前主线 manifest：`tests/test_manifest_mvp.txt`，共 76 项测试。
- 当前可试玩 APK：`builds/wanguxingtu-debug.apk`（M85，含武将立绘）。
- 当前模拟器：AVD `wanguxingtu_phone`，需 `-gpu host` 启动（SwiftShader 不支持 Godot 4.7 gl_compatibility）。

## P0 架构清理（已完成）

- `project.godot` 注册 EventBus / AppState / SaveService / SoundManager 四个 Autoload。
- `EventBus.gd` 从 1 个信号扩展到 14 个类型化信号，覆盖战斗全流程。
- 删除空文件死代码：`BattleController.gd`、`BattleRules.gd`、`CardPiles.gd`（含 .uid）。
- 静态类型加固：`TurnController`、`BattleState`、`BattleDeck`、`BattleScreen`、`BattleStats`、`AppState` 全部零未类型化成员变量。

## P1 功能补全（已完成）

- EventBus 信号接入战斗流程：`TurnController` emit `side_turn_started`/`side_turn_ended`/`turn_completed`；`BattleState` emit `unit_deployed`/`unit_attacked`/`unit_damaged`/`unit_died`/`master_damaged`/`star_power_changed`；`MovementSystem` emit `unit_moved`；`BattleScreen` emit `battle_started`/`battle_ended`。
- `SaveService.gd` 完整实现：7 个方法（`create_default_save`/`has_save`/`load_game`/`save_game`/`delete_save`/`build_save_from_appState`/`apply_save_to_appState`）。
- `HomeScreen.gd` 新增"继续游戏"按钮（仅存档存在时显示）。
- `BattleScreen.gd` 战斗结束时自动存档 + emit `battle_ended`。

## P2 内容扩展（已完成）

- 新增 8 位武将（黄忠/郭嘉/典韦/荀彧/董卓/貂蝉/公孙瓒/华雄），武将池 13→21。
- `skills.json` 新增 8 个技能定义，`SkillSystem` 扩展 `adjacent_modify` 效果类型。
- `strategy_cards.json` 全中文化。
- `BattleAnimator.gd` 信号驱动战斗动画（攻击闪红/移动闪蓝/部署闪绿/死亡深红 Tween）。
- `tests/m79_batch2_heroes_check.gd` 覆盖 8 武将 + 3 策略卡验证。

## P3 体验打磨（已完成）

- `SoundManager.gd` 信号驱动程序化音效，零 `_process()` 轮询，8 池 AudioStreamPlayer。
- `AppState.gd` 添加经济系统（gold/star_stone/battles_fought + earn/record/snapshot）。
- `HomeScreen.gd` 首页显示奕星师等级/星石/金币/战斗次数。
- `ResultScreen.gd` 结算显示战利品，胜利获 50+ 金币和 1 星石，失败获保底。
- `SaveService` 存档/读档同步 economy 数据。
- 数值平衡微调：黄忠 ATK 5→4，貂蝉 cost 5→4，公孙瓒 cost 3→4。

## 常用命令

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check_test_manifest.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_mvp_manifest_tests.ps1
powershell -ExecutionPolicy Bypass -File scripts/android_smoke_capture.ps1
```

## M83-M85: Android 调试 + 战斗界面可视化（已完成）

- **M83**: 定位模拟器黑屏根因（SwiftShader GLES 3.0 uniform 向量不足），修复为 `-gpu host` 模式。
- **M84**: 修复 EventBus Autoload 访问——`Engine.get_singleton()` 在 Android 运行时失效，全部改为 `get_node("/root/EventBus")`。SaveService 静态方法改用 `Engine.get_main_loop().root.get_node_or_null()`。修复 SoundManager `play()` 时序。
- **M85**: `BattleBoardView.gd` 重构——每格增加 TextureRect 武将立绘 + HP overlay Label + 部署区/公共区域三色着色。21 武将中 19 位有对应立绘。

## 最近验证

- Manifest 同步：当前 `MANIFEST_TEST_COUNT=76` / `TEST_FILE_COUNT=76`。
- UI 优化验证：**8/8 测试全部通过**（headless --script），headless 启动零错误。
- APK 导出：成功（183MB，`builds/wanguxingtu-debug.apk`）。
- 模拟器烟测：启动正常、进入战斗正常、零 ERROR、立绘显示正确。
- 模拟器启动命令：`emulator -avd wanguxingtu_phone -gpu host -no-audio`

## UI 优化验证 + 遗留修复（已完成 M86）

- **3 个遗留问题全部修复**：
  1. `status_label`/`turn_info_label` 同节点 → 移除冗余 `turn_info_label`
  2. `unit_detail_body` 路径缺 `DetailLayout` → 补全 `DetailLayout/` 中间层
  3. `M6c` 测试 `Script.new()` 无场景树 → 重写为 `.tscn` 实例化
  4. `M41` 测试文本断言未适配 M85 → 改为背景色 + 子节点检查
- 涉及文件：`BattleScreen.gd`（2 处修复）、`tests/m6c_result_flow_check.gd`（重写）、`tests/m41_board_visual_refinement_check.gd`（重写）
- 完整报告：`docs/ui_optimization_verification_report.md`

## 下一步建议

1. 为郭嘉制作立绘，补全 21 武将全部有图。
2. 替换 SoundManager 程序化音效为真实音频素材。
3. 增强敌方 AI：增加第二名对手的部署策略差异。
4. Q版美术全面接入（tupian/ 中还有大量 UI 素材未使用）。
5. 在 Godot Editor 中做完整交互测试。
