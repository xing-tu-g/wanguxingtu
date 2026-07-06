# Balance & Gameplay Consolidation Sprint v1（2026-07-04）

## 摘要

本阶段只做轻量平衡与玩法体验收敛：

- 未新增职业，仍为 Tank / Warrior / Archer / Mage / Assassin。
- 未修改核心移动规则，仍只向前推进。
- 未修改攻击范围体系，仍通过 `AttackShapeSystem`。
- 未引入百分比、倍率、概率或复杂新系统。
- 调整集中在数值、技能效果、技能标签、少量通用条件判断和模拟工具。

## 调整前问题

200 局基线报告：`tmp/skill_balance/baseline_200.json`

| 职业 | 调整前胜率 |
|---|---:|
| Archer | 60.3% |
| Assassin | 51.8% |
| Mage | 52.6% |
| Tank | 51.4% |
| Warrior | 47.9% |

主要问题：

- Archer 依赖高攻击和即时 `bonus_damage`，爆发过强。
- Warrior 中 13 / 21 个技能仍是模板化“攻击命中后追加伤害”。
- Assassin 技能没有明确表达背刺收益。
- Mage 控制/范围比例不足，仍有个别纯伤害技能。

## 主要英雄调整

| 英雄 | 调整前 | 调整后 | 目的 |
|---|---|---|---|
| 孙尚香 | `bonus_damage`，攻击 4 | `apply_status/burn`，费用 5，攻击 2 | 从爆发改为持续输出，延后远程核心上场 |
| 黄忠 | `bonus_damage`，攻击 4 | `apply_status/burn`，攻击 2 | 降低远程爆发峰值 |
| 公孙瓒 | `bonus_damage`，攻击 4 | `apply_status/burn`，攻击 2 | 保留持续压制，降低远程滚雪球 |
| 太史慈 | `bonus_damage`，攻击 4 | `apply_status/burn`，攻击 2 | 从真实伤害爆发改为持续伤害 |
| 乐进 | 正面追加 2 | 命中追加 1，背刺追加 3，攻击 4，生命 7 | 强化刺客背刺收益 |
| 甘宁 | 正面追加 2 | 命中追加 1，背刺追加 3，攻击 5，生命 7 | 强化刺客切后价值 |
| 米夫人/小乔 | 每回合治疗 3 | 每回合治疗 2 | 降低治疗长盘和自动模拟超时风险 |
| 张辽/马超/魏延/关平/张苞/马岱/凌统/颜良/文丑/华雄 | 攻击命中追加 1 或 2 | 回合开始时本回合攻击 +1 | Warrior 转为稳定成长/叠加型输出 |
| 袁术 | 攻击命中追加法术伤害 | 部署时敌方全军攻击 -1，持续 1 回合 | Mage 从输出转为控制/Debuff |

## 技能调整列表

- Archer：
  - `sunshangxiang_combo`
  - `huangzhong_snipe`
  - `gongsunzan_cavalry`
  - `taishici_piercing_arrow`
  - 统一改为命中后挂 `burn`，回合结束造成 1 点真实伤害，标签为 `archer/sustain/pierce`。
- Assassin：
  - `lejin_breakthrough`
  - `ganning_jinfan_raid`
  - 改为命中追加 1 点物理伤害；若命中背刺目标，则追加 3 点物理伤害。
- Warrior：
  - `zhangliao_assault`
  - `huaxiong_execute`
  - `machao_silver_charge`
  - `weiyan_rebel_blade`
  - `guanping_guard_blade`
  - `zhangbao_tiger_sweep`
  - `madai_frontier_cut`
  - `lingtong_swift_cut`
  - `yanliang_vanguard_cut`
  - `wenchou_hook_spear`
  - 统一改为回合开始时本回合攻击 +1，标签为 `warrior/growth`。
- Mage：
  - `yuanshu_false_edict`
  - 改为部署时敌方全军攻击 -1，持续 1 回合，标签为 `mage/debuff/control`。

## 职业技能分布

| 职业 | 目标 | 当前达成 |
|---|---:|---:|
| Tank 保护/承伤/护盾 | >= 70% | 100.0% |
| Warrior 成长/叠加 | >= 70% | 71.4% |
| Archer 持续输出/破甲 | >= 70% | 100.0% |
| Mage 控制/范围 | >= 70% | 73.7% |
| Assassin 背刺/收割/爆发 | >= 70% | 100.0% |

## 200 局 v2 模拟结果

正式报告：`tmp/skill_balance/balance_simulation_v2_200.json`

- 样本：200。
- 完成：200。
- 超时：0。
- 异常：0。
- 左侧胜利：108。
- 右侧胜利：92。
- 平均回合数：15.24。
- 10 回合内主将血差 >= 25 的早期一边倒：5 / 200。
- 无单一英雄胜率 > 65%。
- 无单一英雄胜率 < 35%。

### 职业胜率

| 职业 | 胜率 |
|---|---:|
| Archer | 50.7% |
| Assassin | 50.7% |
| Mage | 52.7% |
| Tank | 51.3% |
| Warrior | 49.6% |

### 阵营胜率

| 阵营 | 胜率 |
|---|---:|
| 群 | 51.5% |
| 蜀 | 49.6% |
| 魏 | 51.2% |
| 吴 | 51.9% |

### 英雄 Top 10

| 英雄 | 胜率 |
|---|---:|
| 颜良 | 60.4% |
| 周瑜 | 59.4% |
| 小乔 | 59.1% |
| 公孙瓒 | 59.0% |
| 张苞 | 56.6% |
| 荀彧 | 56.5% |
| 马超 | 56.0% |
| 袁术 | 55.7% |
| 貂蝉 | 55.3% |
| 鲁肃 | 54.8% |

### 英雄 Bottom 10

| 英雄 | 胜率 |
|---|---:|
| 姜维 | 40.6% |
| 孙尚香 | 44.1% |
| 程普 | 44.1% |
| 文丑 | 44.7% |
| 袁绍 | 44.7% |
| 曹操 | 44.8% |
| 庞统 | 44.9% |
| 孙权 | 45.8% |
| 张飞 | 46.4% |
| 张辽 | 46.7% |

## 系统性设计判断

当前没有系统性规则问题：

- 五职业胜率全部进入 45% 到 55%。
- 阵营胜率全部接近 50%。
- 没有无解英雄。
- 没有低于 35% 的不可用英雄。
- 平均 15.24 回合，不拖沓。

仍需关注：

- 颜良是当前最高胜率英雄（60.4%），但未超过 65% 无解阈值。
- Mage 仍有周瑜、小乔、荀彧、袁术、貂蝉、鲁肃进入 Top 10，说明控制/治疗/Debuff 在自动模拟里收益较高。
- 姜维、孙尚香、程普偏低，后续适合做小幅数值观察，不急于改系统。

## 策略来源判断

当前策略来源更接近目标顺序：

1. 站位：背刺、相邻援护、三行远程和范围技能都依赖位置。
2. 阵容：职业技能分工更清晰。
3. 抽牌顺序：仍影响部署节奏。
4. 数值：不再由 Archer 爆发单独主导。

## 新增验证

- `scripts/tools/BalanceSimulationV2.gd`
- `scripts/tools/run_skill_balance_simulation_v2.gd`
- `tests/m89_balance_gameplay_consolidation_check.gd`
- `SkillCompletionSimulator.gd` 在模拟场景使用固定 seed，正式 `BattleDeck` 默认随机逻辑不变。

验证命令：

```powershell
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://scripts/tools/run_skill_balance_simulation_v2.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m89_balance_gameplay_consolidation_check.gd
powershell -ExecutionPolicy Bypass -File scripts/check_test_manifest.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_mvp_manifest_tests.ps1 -GodotBin godot.cmd
```

当前验证结果：

- `SKILL_BALANCE_SIMULATION_V2_CLEAN`
- `M89 balance gameplay consolidation checks passed`
- `MANIFEST_TEST_COUNT=87`
- `TEST_FILE_COUNT=87`
- `TEST_MANIFEST_SYNC_CLEAN`
- `RUNNING_TEST_COUNT=87`
- `MVP_MANIFEST_CLEAN`

## 下一阶段建议

1. 做“玩家可控部署策略”验证，而不是继续只看自动部署。
2. 对 Mage Top 10 做二次观察，重点是陈宫、袁术、张角、贾诩、小乔。
3. 对弱侧英雄做微调候选，不急着改系统：大乔、貂蝉、乐进、典韦、孙策。
4. 后续平衡模拟建议固定多组卡组策略，而不是只用全武将轮转。
