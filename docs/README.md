# 万古星图：开发文档索引

本目录用于承接原始 GDD，并拆成 Codex + Godot 可执行的开发输入。

## 最高规范

1. `COMBAT_DESIGN_BIBLE.md`
   - 当前战斗系统最高规范。
   - 以后所有玩法、英雄、技能、AI、数值设计均以此文档为准。
   - 如果旧规则文档、测试样例或临时实现与它冲突，以它为准。

2. `ART_BIBLE.md`
   - 当前美术最高规范。
   - 以后所有武将、武器、Battle、UI、FX 资源均以此文档为准。

3. `SKILL_DESIGN_BIBLE.md`
   - 当前技能设计与技能配置最高规范。
   - 明确固定数值、配置驱动、AttackShapeSystem 范围、禁止百分比/倍率/英雄专属硬编码。

## 当前审计文档

1. `COMBAT_DESIGN_AUDIT_2026-07-04.md`
   - 根据 `COMBAT_DESIGN_BIBLE.md` 审计当前 55 名武将、技能、AI、普通攻击范围。
   - 列出需要修改的英雄、技能、职业设计和代码规则。

2. `CURRENT.md`
   - 当前续接入口，只保留最近状态、最新 APK、测试数量、下一步任务。

3. `ENGINE_ARCHITECTURE.md`
   - Combat Core 模块边界文档，明确 Grid、BattleAI、Targeting、AttackShape、Skill、Buff、Damage、BattleUnit 的职责。

4. `HERO_COMBAT_AUDIT_2026-07-04.md`
   - 55 名可玩武将战斗审计，包含空技能清单、五职业检查、百分比文案检查和修正方向。

5. `HERO_SKILL_COMPLETION_2026-07-04.md`
   - Hero Skill Completion Sprint v1 完成报告，列出 34 名补技能武将、100 局模拟结果、偏强/偏弱观察。

6. `BALANCE_GAMEPLAY_CONSOLIDATION_2026-07-04.md`
   - Balance & Gameplay Consolidation Sprint v1 完成报告，包含职业平衡前后对比、200 局模拟结果、Top/Bottom 英雄和后续建议。

7. `HANDOFF.md`
   - 长会话阶段交接记录。每完成一个阶段后写入真实验证结果、产物路径、阻塞项和下一步。

## 历史 / 参考文档

以下文档仍可作为历史背景或实现参考，但不再高于 `COMBAT_DESIGN_BIBLE.md`：

1. `01_rules_spec.md`
   - 早期核心规则规格书。

2. `02_values_and_content.md`
   - 早期数值与内容表。

3. `03_godot_mvp_plan.md`
   - Godot MVP 开发清单。

4. `04_battle_details_data_tests.md`
   - 早期战斗细则、数据结构与测试清单。

5. `05_battle_ui_layout_spec.md`
   - 战斗 UI 布局草案。

6. `06_art_asset_spec.md`
   - 早期美术资产规格。

7. `07_manual_art_prompts.md`
   - 早期手动美术提示词。

8. `ui_optimization_*.md`
   - UI 优化阶段报告。

## 当前设计决议

- 战斗设计最高原则：简单规则、深度策略、低数值、高博弈。
- 策略来自玩家站位、阵容、抽牌、星力和部署时机，不来自复杂 AI。
- 全项目永久只保留五职业：Tank、Warrior、Archer、Mage、Assassin。
- 普通移动只能向前推进；禁止上下移动、绕路、A*、复杂目标路径。
- 近战普通攻击只能攻击所在行。
- 远程普通攻击只能攻击所在行和上下相邻一行，最多覆盖三行。
- 射程只决定横向距离，不允许因为射程高而跨越更多行。
- Assassin 职业特色应为背刺固定额外伤害，不是穿阻挡或智能绕后。
- 所有数值优先使用固定值，禁止复杂百分比和复杂倍率。
- 不新增职业、不新增复杂 AI、不新增新资源类型。
- 当前 Combat Refactor 已完成第一轮核心代码对齐：普通攻击范围统一进入 `AttackShapeSystem`，普通移动只前向推进，Assassin 改为固定数值背刺。
- 当前 Battle Polish v3 APK：`builds/wanguxingtu-battle-polish-v3-debug.apk`。
- 当前主线 manifest：87 项。

## 后续建议

1. 基于 `BALANCE_GAMEPLAY_CONSOLIDATION_2026-07-04.md` 做玩家可控部署策略验证。
2. 继续观察 Mage Top 10 和弱侧英雄，不急于改系统。
3. 后续技能扩展继续遵守 `SKILL_DESIGN_BIBLE.md`。
