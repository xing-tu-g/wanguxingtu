# 星图对弈 Engine Architecture

状态：Combat Refactor Sprint v1 基线  
最高战斗规范：`docs/COMBAT_DESIGN_BIBLE.md`

## 1. 模块边界

### GridSystem / BoardModel

职责：

- 维护棋盘尺寸、坐标、占用状态。
- 校验部署位置、移动目标是否在棋盘内。
- 提供单位放置、移动、查询。

限制：

- 不决定 AI 策略。
- 不计算伤害。
- 不定义职业攻击范围。

### BattleAI

职责：

- 只表达单位是否等待、前进、攻击的决策边界。
- 保留兼容入口时，也必须返回符合 Combat Bible 的行为。

限制：

- 不直接写伤害。
- 不做 A*、绕路、上下移动、后退、风筝、切后排。
- 不包含职业专属寻路。
- 不重复实现攻击范围。

当前规则：

- 我方向右。
- 敌方向左。
- 无目标时只尝试向前一格。
- 前方阻挡且无合法目标时停留。

### TargetingSystem

职责：

- 根据 `AttackShapeSystem` 给出的攻击形状筛选候选目标。
- 对候选目标做稳定排序。
- 判断是否可以攻击主将。

限制：

- 不写移动逻辑。
- 不写伤害逻辑。
- 不再使用曼哈顿距离作为普通攻击判定。
- 不自行复制近战/远程/刺客攻击范围规则。

### AttackShapeSystem

职责：

- 统一描述普通攻击和技能攻击范围。
- 提供基础攻击形状、射程、目标筛选、排序、背刺判断。
- 作为所有范围判断的唯一入口。

已支持形状：

- `same_row_forward`
- `same_row_plus_adjacent_forward`
- `front_1`
- `front_line`
- `row_line`
- `column_line`
- `cross`
- `rectangle`
- `fan`
- `self`
- `ally_nearest`
- `all_allies`
- `all_enemies`

硬规则：

- Tank / Warrior / Assassin 普通攻击使用同行前方。
- Archer / Mage 普通攻击使用同行和上下相邻一行，射程只计算横向距离。
- Assassin 额外允许检测身后 1 格敌人，背刺固定额外伤害为 3。

### MovementSystem

职责：

- 执行单位行动顺序。
- 调用 `TargetingSystem` 判断攻击目标。
- 无目标时调用前向移动。
- 调用 `BattleState` 应用伤害和单位移动。

限制：

- 不做复杂 AI 路线选择。
- 不允许职业绕路。
- 不允许刺客穿阻挡。
- 不重复实现目标范围。

### SkillSystem / SkillExecutor

职责：

- 执行技能触发、冷却、状态、治疗、召唤、固定伤害。
- 技能可以突破普通攻击限制，但范围必须通过 `AttackShapeSystem` 描述。

限制：

- 不复制普通攻击范围。
- 不使用百分比、倍率或复杂概率作为当前阶段数值。
- 不让技能逻辑反向写入 AI 决策。

### BuffSystem

职责：

- 维护 Buff / Debuff 生命周期。
- 处理持续回合、状态移除、回合结束结算。

限制：

- 不负责选择目标。
- 不负责移动。
- 不负责定义攻击范围。

当前项目内状态生命周期主要由 `SkillSystem` 承担，后续拆分 BuffSystem 时必须保持上述边界。

### DamageSystem

职责：

- 统一处理伤害、治疗、护盾、减伤。
- 保持固定数值、低数值、可心算。

限制：

- 不选择攻击目标。
- 不移动单位。
- 不执行 AI 决策。

### BattleUnit

职责：

- 保存单位状态。
- 包括生命、攻击、射程、移动、职业、阵营、状态、技能 ID。

限制：

- 不承载复杂规则。
- 不执行伤害公式。
- 不决定攻击范围。

## 2. 禁止重复实现

以下逻辑只能有一个权威入口：

- 普通攻击范围：`AttackShapeSystem`
- 普通攻击目标筛选：`TargetingSystem` 调用 `AttackShapeSystem`
- 普通移动方向：`MovementSystem.move_unit_forward`
- 固定伤害应用：`BattleState` / `DamageSystem`
- 技能范围：`SkillSystem` 调用 `AttackShapeSystem`

## 3. 当前 Combat Refactor 验证点

- `tests/m2_movement_attack_check.gd`
- `tests/m14_zhaoyun_dash_check.gd`
- `tests/m84_vertical_slice_core_check.gd`
- `tests/m87_combat_refactor_core_check.gd`

这些测试共同验证：

- 我方只向右。
- 敌方只向左。
- 不上下移动。
- 不绕路。
- 近战同行攻击。
- 远程三行攻击。
- 刺客固定数值背刺。
- 技能范围通过 `AttackShapeSystem`。
- 五职业限制。
- 技能文案不使用百分比。
