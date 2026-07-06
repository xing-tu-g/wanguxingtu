# Combat Design Audit 2026-07-04

依据：`docs/COMBAT_DESIGN_BIBLE.md`  
范围：当前 `data/heroes.json`、`data/skills.json`、`scripts/battle/*`  
结论：数据层职业数量符合五职业规范，但普攻范围、AI 移动、刺客职业特色、部分英雄技能设计仍需调整。

## 1. 当前数据概览

- `heroes.json` 共 56 条。
- 可玩武将 55 名。
- `yellow_turban` 是召唤单位，不计入武将。
- 职业只使用五类：`tank`、`warrior`、`archer`、`mage`、`assassin`。
- 未发现新增职业。

职业分布：

| 职业 | 数量 | 评价 |
|---|---:|---|
| Warrior | 21 | 偏多，但符合当前三国武将池结构 |
| Mage | 19 | 偏多，后续技能必须避免全部变成泛用 Debuff |
| Tank | 9 | 合理 |
| Archer | 4 | 偏少，但不需要为补职业新增系统 |
| Assassin | 2 | 偏少，且当前实现未符合背刺定位 |

阵营分布：

| 阵营 | 数量 |
|---|---:|
| Shu | 13 |
| Wei | 12 |
| Wu | 17 |
| Qun | 13 |

## 2. 当前实现与 Bible 冲突点

### 2.1 AI 移动过复杂

涉及文件：

- `scripts/battle/BattleAI.gd`
- `scripts/battle/MovementSystem.gd`

当前行为：

- `BattleAI.move_toward_target()` 会根据最近敌人移动。
- `_movement_priority()` 会尝试横向、纵向、反向候选格。
- `_best_next_cell()` 会挑选更接近目标的下一格。

与 Bible 冲突：

- Bible 要求普通移动只能向前推进。
- 禁止上下移动、绕路、寻找最佳路径、复杂职业 AI。
- 当前 AI 虽不是 A*，但已经具备“朝最近敌人寻路”的行为倾向。

建议修改：

1. `MovementSystem.act_unit()` 不再调用 `BattleAI.move_toward_target()`。
2. 无可攻击目标时统一调用 `move_unit_forward()`。
3. 保留 `BattleAI.select_nearest_enemy()` 只用于目标选择，不用于移动路线。
4. 删除或停用 `_movement_priority()`、`_best_next_cell()` 这类路径选择逻辑。

### 2.2 普通攻击范围不符合职业规则

涉及文件：

- `scripts/battle/TargetingSystem.gd`

当前行为：

- `select_target()` 使用曼哈顿距离 `manhattan_distance(attacker, enemy) <= attack_range`。
- 所有职业共用同一距离规则。

与 Bible 冲突：

- 近战职业普通攻击只能攻击自己所在行。
- 远程职业只能攻击自己所在行和上下相邻一行。
- 当前曼哈顿距离会允许：
  - 近战攻击上下相邻格。
  - 高射程远程跨越超过相邻行的目标。

建议修改：

1. 新增 `is_in_basic_attack_lanes(attacker, enemy)`。
2. `tank`、`warrior`、`assassin` 只允许 `enemy.row == attacker.row`。
3. `archer`、`mage` 允许 `abs(enemy.row - attacker.row) <= 1`。
4. 射程只计算横向距离，不计算纵向距离。
5. 保持最近目标优先，但优先级基于前方横向距离。

### 2.3 刺客职业特色未对齐

当前行为：

- `MovementSystem._can_pass_blockers()` 和 `BattleAI._can_pass_blockers()` 让 `assassin` 可以穿过阻挡。

Bible 要求：

- Assassin 定位是爆发。
- 职业特色是背刺。
- 允许攻击自己身后的敌人。
- 攻击身后敌人时造成固定额外伤害。
- 不要求穿阻挡、绕后或智能切后排。

建议修改：

1. 移除 `assassin` 自动穿阻挡。
2. 新增背刺判定：
   - 我方单位身后：目标列 `< attacker.column`。
   - 敌方单位身后：目标列 `> attacker.column`。
3. 背刺只在目标处于合法攻击范围时生效。
4. 背刺伤害使用固定值，例如 `+2`。
5. 不实现潜行、绕后、切后排。

### 2.4 Terrain 部分规则有潜在复杂化风险

涉及文件：

- `data/terrains.json`
- `scripts/battle/TerrainSystem.gd`

观察：

- 泥沼移动额外消耗，并允许 `assassin`、`warrior` 忽略。
- 高地给 `archer`、`mage` 攻击距离 +1。
- 河流同时有攻击、受伤、主将伤害修正。

评价：

- 都是固定数值，符合低数值原则。
- 但地形例外会增加理解成本。

建议：

- MVP 阶段保留地形时，每种地形只保留一个核心效果。
- 高地可保留 `range +1`。
- 泥沼可保留 `移动消耗 +1`，但避免职业例外过多。
- 河流建议拆简：只保留一个方向的固定效果，不要同时修改攻击、受伤和主将伤害。

## 3. 55 名英雄职业定位审计

### 3.1 职业字段合法性

所有 55 名可玩武将的 `class` 均属于五职业之一。

无需新增职业。

### 3.2 需要补正式技能的英雄

以下 34 名武将当前 `skill_ids` 为空，需要补一句话定位和正式技能草案。

Shu：

- `machao`：Warrior，高速冲锋武将，建议固定突进/首击伤害。
- `pangtong`：Mage，连环控制/连锁伤害。
- `weiyan`：Warrior，狂战或反骨突击。
- `jiangwei`：Warrior，攻守兼备成长。
- `guanping`：Warrior，稳定成长或继承关家刀法。
- `zhangbao`：Warrior，短蛇矛连击。
- `mifuren`：Mage，保护/治疗。
- `madai`：Warrior，伏击或侧翼突刺，但不能依赖复杂绕后 AI。

Wei：

- `xuchu`：Tank，虎卫援护。
- `zhenji`：Mage，控制或减速。
- `caoren`：Tank，守城护盾。
- `caopi`：Mage，压制或单体削弱。
- `lejin`：Assassin，背刺爆发。
- `xiahoudun`：Warrior，受伤后成长。

Wu：

- `ganning`：Assassin，背刺爆发。
- `sunjian`：Warrior，先登攻击。
- `lumeng`：Warrior，成长型指挥。
- `xiaoqiao`：Mage，治疗或轻控制。
- `taishici`：Archer，稳定连射。
- `huanggai`：Tank，自损/护卫，但使用固定值。
- `zhoutai`：Tank，替伤或濒死坚守。
- `lingtong`：Warrior，突击连击。
- `lusu`：Mage，补给或星力支持。
- `chengpu`：Warrior，老将稳固。
- `sunquan`：Warrior，主君指挥但不要新增统帅职业。
- `daqiao`：Mage，保护或治疗。
- `xusheng`：Tank，防线/屏障。

Qun：

- `yuanshao`：Warrior，号令型强化。
- `yuanshu`：Mage，资源/星力或短期压制。
- `jiaxu`：Mage，毒/延迟伤害。
- `chengong`：Mage，策略伤害或支援。
- `gaoshun`：Tank，陷阵护卫。
- `yanliang`：Warrior，重击。
- `wenchou`：Warrior，突击。

## 4. 已有技能审计

### 4.1 基本符合 Bible 的技能

| 技能 | 评价 |
|---|---|
| `zhouyu_burn` | 固定燃烧伤害，符合 Mage 持续伤害 |
| `zhangfei_guard` | 固定减伤，符合 Tank 援护 |
| `sunshangxiang_combo` | 固定追伤，符合 Archer 连射 |
| `huangzhong_snipe` | 固定真伤，符合 Archer 狙击 |
| `xunyu_aid` | 固定治疗，符合 Mage 支援 |
| `dongzhuo_feast` | 固定恢复，符合 Tank 生存 |
| `diaochan_charm` | 固定攻击降低，符合 Mage Debuff |

### 4.2 需要重写描述或收敛的技能

| 技能 | 问题 | 建议 |
|---|---|---|
| `guanyu_growth` | Turn start 自动成长，且 `max_hp +3` 偏强；更像持续 Buff，不像“重斩” | 改为攻击命中后固定重斩追伤或攻击 +1 |
| `zhaoyun_dash` | 当前是穿阻挡，与“禁止绕路/复杂移动”冲突 | 改为首次前进额外 +1 或命中固定追伤，不穿阻挡 |
| `zhangjiao_summon` | 召唤 3 个单位会显著增加场面复杂度 | 可保留为张角特色，但建议限制为 1 个或明确为少数例外 |
| `zhugeliang_growth` | 英文 Prototype 描述，不符合“AOE”定位 | 改为部署/命中时对最近目标及相邻敌人造成固定 1-2 点伤害 |
| `caocao_march` | 全军移动 +1 可能增加 AI 移动复杂度 | 可保留为固定推进，但必须只影响向前移动 |
| `simayi_silence` | 命名 Silence 但实际是攻击 -1 | 改名为“谋断”，描述为敌军攻击 -1 |
| `zhangliao_assault` | 英文 Prototype，需要中文化 | 保留固定追伤，命名为“突袭” |
| `luxun_burn_link` | 英文 Prototype，需要中文化 | 保留固定燃烧，命名为“连营” |
| `lvbu_rage` | 英文 Prototype，需要中文化；“rage”不如“决斗”清晰 | 改为对单体固定追伤或攻击最高目标追伤 |
| `guojia_strategy` | 敌方全军攻击 -2 偏强 | 建议改为 -1 或只影响最近敌人 |
| `dianwei_rage` | Tank 却是攻击成长，偏 Warrior | 改为替友军承伤或自身固定护甲 |
| `gongsunzan_cavalry` | 名称涉及 cavalry，Bible 禁止新增骑兵职业/资源类型 | 改名为“白马弓”，仍作为 Archer 固定追伤 |
| `huaxiong_execute` | 固定追伤可保留，但需要明确触发条件 | 建议对低生命目标追加固定伤害 |
| `sunce_assault` | 英文 Prototype，需要中文化 | 保留突击固定追伤 |

## 5. 普通攻击范围修改清单

必须修改：

- `TargetingSystem.select_target()`
- `TargetingSystem.can_attack_master()`
- 相关测试：
  - `tests/m2_movement_attack_check.gd`
  - `tests/m4_terrain_strategy_check.gd`
  - `tests/m84_vertical_slice_core_check.gd`
  - 任何依赖曼哈顿距离跨行攻击的测试

建议新增测试：

1. Warrior 不能攻击相邻行目标。
2. Tank 不能攻击相邻行目标。
3. Archer 能攻击上下相邻一行目标。
4. Archer 不能攻击相隔两行目标。
5. Mage 同 Archer。
6. Range 只影响横向距离。

## 6. AI 修改清单

必须修改：

- `MovementSystem.act_unit()`：无目标时只调用 `move_unit_forward()`。
- `BattleAI.gd`：保留最近敌人选择，移除或弃用寻路移动。

建议新增测试：

1. 单位无目标时只向前移动。
2. 单位不会为了最近敌人上下移动。
3. 单位不会后退。
4. 前方被堵时停留。
5. 进入攻击范围后停止并攻击最近目标。

## 7. 职业设计修改清单

### Tank

当前问题：

- 部分 Tank 用“自身高血量 + 护甲”能成立。
- `dianwei_rage` 偏 Warrior。

建议：

- Tank 技能优先改为援护、分担、固定减伤、固定恢复。

### Warrior

当前问题：

- Warrior 数量最多，但很多没有技能，容易同质化。

建议：

- 每个 Warrior 用一句话区分：
  - 重斩
  - 连击
  - 成长
  - 首击
  - 击杀强化

### Archer

当前问题：

- Archer 数量少。
- Range 数值差异很大，但当前 TargetingSystem 没有三行限制。

建议：

- 先修普通攻击范围。
- 技能围绕连射、破甲、毒箭、火箭、固定暴击。

### Mage

当前问题：

- Mage 数量多，多个技能都是全军 Debuff，容易同质化。

建议：

- 分成伤害、控制、治疗、召唤、Buff、Debuff 方向，但不新增职业。
- 避免所有 Mage 都是攻击 -1/-2。

### Assassin

当前问题：

- 当前“穿阻挡”不符合 Bible。
- `lejin`、`ganning` 没有技能。

建议：

- 重做为背刺固定追伤。
- 不实现潜行、绕后、切后排。

## 8. 优先级

P0：规则统一

1. 修 TargetingSystem 普攻行规则。
2. 修 MovementSystem/BattleAI，禁止上下移动和绕路。
3. 修 Assassin 职业特色。

P1：技能文本和原型清理

1. 所有英文 Prototype 技能改为正式中文。
2. 所有技能补一句话定位。
3. 过强的全军 Debuff 收敛。

P2：55 英雄技能补齐

1. 先补 34 个空技能的设计草案。
2. 每个技能只使用固定数值。
3. 不新增系统。

P3：测试

1. 新增普攻范围测试。
2. 新增 AI 前进测试。
3. 新增刺客背刺测试。
4. 更新旧测试中与 Bible 冲突的断言。

## 9. 本阶段不做

- 不新增职业。
- 不新增复杂 AI。
- 不新增新系统。
- 不新增新阵营。
- 不新增商业化系统。
- 不新增大量美术资源类型。

本阶段只统一设计规范，并列出后续实现需要修改的明确清单。
