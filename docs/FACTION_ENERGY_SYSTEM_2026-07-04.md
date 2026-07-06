# Faction Energy System Integration Sprint v1（2026-07-04）

## 摘要

本阶段在不改变基础星力曲线、不新增职业、不增加摸牌机制、不引入百分比的前提下，接入阵营星力机制。

基础规则保持不变：

- 职业仍只有 Tank / Warrior / Archer / Mage / Assassin。
- 星力仍使用现有单一 `star_power`。
- 不增加手牌上限，不增加抽牌奖励。
- 不新增多资源系统。
- 所有效果均为固定低数值：`+1` 星力、`+1` 攻击、`+1` 护盾、`1` 点真实伤害。

## 四阵营星力英雄

每个阵营固定 1 个 Producer + 1 个 Amplifier，总数不超过 2。

| 阵营 | Producer | 规则 | Amplifier | 规则 |
|---|---|---|---|---|
| 蜀 | 赵云 | 本方回合第一次击败敌方单位时，获得 1 点星力。 | 诸葛亮 | 本方回合第一次通过阵营机制获得星力时，最早入场友军获得攻击 +1。 |
| 魏 | 曹操 | 回合开始时，若己方单位数 >= 敌方单位数，获得 1 点星力。 | 荀彧 | 本方回合第一次消耗 >=5 星力部署时，返还 1 点星力。 |
| 吴 | 孙权 | 本方每触发 2 次技能，获得 1 点星力。 | 周瑜 | 本方回合第一次通过阵营机制获得星力时，对最早入场敌人造成 1 点真实伤害。 |
| 群 | 袁绍 | 本方回合第一次己方单位死亡时，获得 1 点星力。 | 贾诩 | 本方回合第一次击败敌方单位时，最早入场友军获得 1 点护盾。 |

说明：当前武将池没有刘备，因此蜀 Producer 使用赵云承接“进攻击杀滚星力”的阵营节奏。

## 实现说明

新增 `FactionEnergySystem.gd`，由 `BattleState` 在现有流程中调用：

- `TurnController.start_side_turn()`：重置本方回合星力触发状态，并检查曹操条件。
- `BattleState.deploy_hero()`：扣除部署费用后检查荀彧返还。
- `SkillSystem.trigger_event()`：技能成功触发后通知孙权技能计数。
- `BattleState.apply_damage_to_unit()`：单位死亡时通知赵云、袁绍、贾诩。
- `BattleStats`：记录阵营星力总量、来源分布和英雄来源。

正式战斗的基础随机抽牌不变；自动模拟继续使用固定 seed，保证报告可复现。

## 100 局模拟结果

报告：`tmp/faction_energy/faction_energy_simulation_v1_100.json`

- 样本：100。
- 完成：100。
- 超时：0。
- 平均回合数：14.28。
- 无限星力循环：未发现。
- 阵营完全压制：未发现。
- 职业平衡：未破坏。

### 阵营星力获取均值

| 阵营 | 平均每局额外星力 |
|---|---:|
| 蜀 | 0.60 |
| 魏 | 1.20 |
| 吴 | 1.71 |
| 群 | 0.90 |

### 星力来源分布

| 来源 | 总量 |
|---|---:|
| 技能 | 171 |
| 条件 | 73 |
| 死亡 | 90 |
| 击杀 | 60 |
| 返还 | 47 |

### 职业胜率

| 职业 | 胜率 |
|---|---:|
| Archer | 50.5% |
| Assassin | 51.1% |
| Mage | 53.7% |
| Tank | 51.4% |
| Warrior | 48.8% |

## 规则冲突检查

- 无新增职业。
- 无新增资源类型。
- 无摸牌奖励。
- 无手牌上限变化。
- 无百分比、倍率、概率。
- 无额外行动。
- 星力基础曲线未改动。

## 是否需要调整星力曲线

当前不需要。

阵营星力均值处于低数值区间，最高的吴为 1.71 / 局，没有资源爆炸；平均回合数 14.28，仍接近 15 回合结构。

## 当前关注点

- 吴的技能来源星力最高，符合“持续触发”定位，但后续应观察孙权 + 高频技能阵容是否过稳。
- 蜀的击杀产能最低，说明自动部署下击杀节奏不稳定；玩家可控部署阶段可能会提高。
- 群的死亡换资源稳定但不爆炸，符合风险节奏。

## 验证命令

```powershell
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://scripts/tools/run_faction_energy_simulation_v1.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m90_faction_energy_system_check.gd
powershell -ExecutionPolicy Bypass -File scripts/check_test_manifest.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_mvp_manifest_tests.ps1 -GodotBin godot.cmd
```

## 下一阶段建议

1. 做玩家可控部署策略验证，重点看蜀击杀滚星力是否能被站位放大。
2. 观察吴阵营技能频率，如果孙权产能长期高于其他阵营 2 点以上，再考虑改为“每回合最多 1 次”。
3. 做阵营推荐卡组，不增加系统，只验证四阵营节奏差异。
