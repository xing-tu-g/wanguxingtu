# 星图对弈 Skill Design Bible v1.0

状态：正式规范  
适用范围：MVP 战斗技能、后续英雄技能扩展、技能测试与模拟  
上位规范：`COMBAT_DESIGN_BIBLE.md`、`ENGINE_ARCHITECTURE.md`

## 1. 核心原则

- 所有技能必须配置化，战斗代码只解释配置。
- 所有技能使用固定数值，不使用百分比、倍率、概率、暴击率。
- 技能说明尽量一句话，玩家可以心算。
- 技能范围必须使用 `AttackShapeSystem` 已定义 shape。
- 禁止按 `hero_id` 在技能执行层写英雄专属分支。
- 少数特殊机制必须先沉淀为 `effect_type`、`target`、`attack_shape` 或 `tag`，再由通用执行器解释。

## 2. 标准字段

每个技能至少保持以下字段：

| 字段 | 说明 |
|---|---|
| `id` | 技能唯一 ID |
| `name` | 技能显示名 |
| `owner_hero_id` | 归属武将 ID |
| `skill_type` | 设计分类，如 `growth`、`burst`、`guard` |
| `trigger` | 触发时机 |
| `effect_type` | 通用效果类型 |
| `target` | 目标规则 |
| `attack_shape` | `AttackShapeSystem` 范围 |
| `target_filter` | 目标过滤说明 |
| `params` | 固定数值参数 |
| `duration_turns` | 持续回合 |
| `cooldown_turns` | 冷却回合 |
| `cost` | 技能消耗，MVP 默认为 0 |
| `stacking` | 叠加规则 |
| `tags` | 职业/机制标签 |
| `description` | 一句话说明 |

## 3. 允许触发

- `deploy`
- `turn_start`
- `attack_hit`
- `passive`

## 4. 当前支持的效果类型

- `damage`
- `area_damage`
- `heal`
- `shield`
- `stun`
- `attack_buff`
- `slow`
- `modify_stat`
- `apply_status`
- `summon`
- `bonus_damage`
- `adjacent_guard`
- `side_move`
- `enemy_attack_delta`
- `adjacent_modify`

新增效果类型前，必须先补测试和文档，再接入 `SkillSystem` / `SkillDataLoader`。

## 5. 允许范围

技能范围只能使用：

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

若需要新范围，先扩展 `AttackShapeSystem.gd`，再更新本文件和测试。

## 6. 职业技能方向

| 职业 | MVP 方向 |
|---|---|
| Tank | 援护、护盾、承伤、防守 |
| Warrior | 固定追加伤害、攻击成长、近战压制 |
| Archer | 稳定追加伤害、破甲、燃烧/毒伤、持续输出 |
| Mage | 法术伤害、控制、治疗、Buff、Debuff、召唤 |
| Assassin | 爆发、背刺、收割 |

## 7. 数值范围

- 普通追加伤害：`1` 到 `2`
- 普通主动/区域伤害：`2` 到 `4`
- 治疗：`1` 到 `3`
- 护盾：`2` 到 `3`
- 攻击成长：`+1`
- 生命成长：`+1` 到 `+3`
- 控制：`1` 回合
- 持续伤害：每回合 `1` 到 `3`，持续 `1` 到 `2` 回合

## 8. 禁止项

- 百分比：`+20%`
- 倍率：`150%`、`双倍`
- 概率：`30% 概率`
- 复杂连锁触发
- 长篇技能说明
- 技能执行器里写 `if hero_id == "xxx"`

## 9. 验证入口

```powershell
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m88_hero_skill_completion_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://scripts/tools/run_skill_completion_simulation.gd
```
