# Manual Battle Validation 2026-07-04

## Summary

- Sprint: Manual Battle Validation Sprint v1
- Scope: 只验证手动部署存在感，不新增英雄、职业、系统、AI、UI、美术或经济系统。
- Focus heroes: 赵云、华雄、马超、徐盛、张飞。
- Method: 每名英雄 3 个固定站位微场景，使用正式 BattleState / MovementSystem / BattleStats 记录结果。
- Screenshots: 游戏内 Manual Battle Test Mode 可复现；批量结果先记录截图路径字段，实际视觉截图由后续人工或模拟器补采。

## Manual Battle Test Mode

- `BattleScreen.set_screen_data()` 支持 `manual_battle_test_mode=true`。
- 可传入 `player_deck` 和 `enemy_deck` 选择指定测试卡组。
- Manual 模式显示 `ManualValidationPanel`，包含回合、星力、已部署武将、技能触发、伤害、承伤、治疗、击杀、阵营星力。
- Manual 模式显示右下 `重开` 按钮；正式模式仍隐藏该按钮。

## Scenario Results

| Hero | Scenario | Focus Cell | Allies | Enemies | Skill Triggers | Damage | Tanking | Healing | Kills | Energy | Guard Prevented | Score | Rating | Pass | Screenshot |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |
| 赵云 | normal | (2,3) | - | 曹仁(4,3) | 3 | 6 | 0 | 0 | 0 | 0 | 0 | 93 | 强 | Yes | `tmp/manual_validation/zhaoyun_normal.png` |
| 赵云 | favorable | (2,3) | - | 曹仁(3,3) | 1 | 4 | 0 | 0 | 1 | 1 | 0 | 72 | 中 | Yes | `tmp/manual_validation/zhaoyun_favorable.png` |
| 赵云 | unfavorable | (2,3) | - | 曹仁(4,4) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 低 | No | `tmp/manual_validation/zhaoyun_unfavorable.png` |
| 华雄 | normal | (2,3) | - | 许褚(4,3) | 2 | 10 | 0 | 0 | 1 | 0 | 0 | 100 | 强 | Yes | `tmp/manual_validation/huaxiong_normal.png` |
| 华雄 | favorable | (2,3) | - | 许褚(3,3) | 1 | 5 | 0 | 0 | 1 | 0 | 0 | 60 | 中 | Yes | `tmp/manual_validation/huaxiong_favorable.png` |
| 华雄 | unfavorable | (2,3) | - | 许褚(4,4) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 低 | No | `tmp/manual_validation/huaxiong_unfavorable.png` |
| 马超 | normal | (2,3) | - | 典韦(4,3) | 3 | 6 | 0 | 0 | 0 | 0 | 0 | 93 | 强 | Yes | `tmp/manual_validation/machao_normal.png` |
| 马超 | favorable | (2,3) | - | 典韦(3,3) | 2 | 5 | 0 | 0 | 1 | 0 | 0 | 85 | 强 | Yes | `tmp/manual_validation/machao_favorable.png` |
| 马超 | unfavorable | (2,3) | - | 典韦(4,4) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 低 | No | `tmp/manual_validation/machao_unfavorable.png` |
| 徐盛 | normal | (2,3) | - | 黄忠(3,3) | 1 | 4 | 0 | 0 | 0 | 0 | 0 | 37 | 弱但可感知 | Yes | `tmp/manual_validation/xusheng_normal.png` |
| 徐盛 | favorable | (2,3) | - | 黄忠(3,3)、太史慈(4,3) | 1 | 4 | 0 | 0 | 0 | 0 | 0 | 37 | 弱但可感知 | Yes | `tmp/manual_validation/xusheng_favorable.png` |
| 徐盛 | unfavorable | (2,3) | - | 黄忠(4,4) | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 25 | 弱但可感知 | Yes | `tmp/manual_validation/xusheng_unfavorable.png` |
| 张飞 | normal | (2,3) | 关平(3,3) | 颜良(4,3) | 1 | 0 | 0 | 0 | 0 | 0 | 2 | 41 | 弱但可感知 | Yes | `tmp/manual_validation/zhangfei_normal.png` |
| 张飞 | favorable | (2,3) | 关平(3,3)、马岱(2,4) | 颜良(4,3) | 1 | 0 | 0 | 0 | 0 | 0 | 2 | 41 | 弱但可感知 | Yes | `tmp/manual_validation/zhangfei_favorable.png` |
| 张飞 | unfavorable | (2,3) | 关平(5,3) | 颜良(6,3) | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 25 | 弱但可感知 | Yes | `tmp/manual_validation/zhangfei_unfavorable.png` |

## Hero Judgement

| Hero | Scenarios | Passed | Average Score | Description Update | Number Tuning | Judgement |
| --- | ---: | ---: | ---: | --- | --- | --- |
| 赵云 | 3 | 2 | 55.0 | Yes | No | 自动模拟低估；手动同排找残血时身份成立 |
| 华雄 | 3 | 2 | 53.3 | Yes | No | 自动模拟低估；近身硬目标时真伤强压成立 |
| 马超 | 3 | 2 | 59.3 | Yes | No | 自动模拟低估；同排突破和真伤价值成立 |
| 徐盛 | 3 | 3 | 33.0 | No | No | 不是数值失败，但需要更清晰的站位提示 |
| 张飞 | 3 | 3 | 35.7 | No | No | 不是数值失败，但需要更清晰的站位提示 |

## Recommendations

- 赵云、华雄、马超：优先改技能描述和教程提示，强调同排、近身、残血/硬目标价值；暂不改数值。
- 徐盛：防守验证通过，但输出存在感弱；暂不加强，后续在敌方远程压力更高的场景复核。
- 张飞：邻接守护验证通过，但强依赖站位；需要在详情描述中明确“邻接友军减伤”。
- 当前没有英雄进入立即重做清单；下一阶段建议做玩家可控部署策略验证。
