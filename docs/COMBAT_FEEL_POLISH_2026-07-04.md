# Combat Feel & Polish Sprint v1

## Scope

本阶段只做表现层强化，不修改战斗规则、星力模型、AttackShape、职业、英雄数据或资源。

## Changes

- 战斗节奏提示：
  - 顶部状态补充“下次星力”“星潮倒计时/主将伤害加成”“当前阶段决策提示”。
  - 回合摘要追加当前节奏提示，避免玩家只看到纯结算文本。
- 战斗反馈强化：
  - 所有技能成功触发都会显示技能名横幅和轻量占位 FX，不再只覆盖核心英雄。
  - 部署时显示消耗星力浮层。
  - 星力增加/消耗显示全局浮层。
  - 主将受伤显示全局浮层。
  - 单位死亡显示“破阵”反馈并触发轻微震动。
- 英雄身份表现：
  - 技能触发统一走 `unit_skill_triggered`，不同 `effect_type` 使用不同颜色占位 FX。
  - 核心英雄仍保留更强震动反馈，普通英雄获得轻量技能反馈。
- 信息可读性：
  - 当前星力继续保留。
  - 下一回合星力预测通过 `turn_controller.get_star_restore_amount()` 展示。
  - 星潮倒计时通过 `TurnController.STAR_TIDE_RESTORE_ROUND_INTERVAL` 展示。
  - 后期主将伤害加成通过 `get_star_tide_master_damage_bonus()` 展示。

## Validation

- 不修改：
  - `BattleState.gd`
  - `TurnController.gd`
  - `AttackShapeSystem.gd`
  - `FactionEnergySystem.gd`
  - `data/heroes.json`
  - `data/skills.json`
- 新增测试：
  - `tests/m93_combat_feel_polish_check.gd`

## Remaining

- 当前 FX 仍是 Godot 运行时占位色块/文字，后续可替换为正式 FX 资源。
- “每回合决策点”目前通过信息提示和可部署/推进反馈表达，后续应在实机试玩中观察玩家是否仍会误判节奏。
