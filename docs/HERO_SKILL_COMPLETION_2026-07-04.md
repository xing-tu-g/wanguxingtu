# Hero Skill Completion Sprint v1 完成报告（2026-07-04）

## 摘要

- 审计口径：读取 `data/heroes.json`，排除召唤单位 `yellow_turban`。
- 可玩武将：55。
- 技能配置：55。
- 本阶段补齐原 `skill_ids` 为空的 34 名武将。
- 所有可玩武将现在至少拥有 1 个可运行技能。
- 所有技能采用固定数值、短文案、配置驱动，并使用 `AttackShapeSystem` 中的合法 `attack_shape`。
- 本阶段未新增 UI、美术、职业、阵营、英雄、商城、登录、PVP 或复杂 AI。

## 34 名补技能武将

| Hero ID | 武将 | 阵营 | 职业 | 新技能 ID | 技能名 | 一句话说明 |
|---|---|---|---|---|---|---|
| `machao` | 马超 | shu | warrior | `machao_silver_charge` | 银枪突阵 | 攻击命中后：追加 1 点物理伤害。 |
| `pangtong` | 庞统 | shu | mage | `pangtong_chain_fire` | 连环火计 | 攻击命中后：对目标十字范围造成 2 点法术伤害。 |
| `weiyan` | 魏延 | shu | warrior | `weiyan_rebel_blade` | 狂骨 | 攻击命中后：追加 1 点物理伤害。 |
| `jiangwei` | 姜维 | shu | warrior | `jiangwei_counterplan` | 继志 | 部署时：敌方全军攻击 -1，持续 1 回合。 |
| `guanping` | 关平 | shu | warrior | `guanping_guard_blade` | 承义 | 攻击命中后：追加 1 点物理伤害。 |
| `zhangbao` | 张苞 | shu | warrior | `zhangbao_tiger_sweep` | 虎咆 | 攻击命中后：追加 1 点物理伤害。 |
| `mifuren` | 糜夫人 | shu | mage | `mifuren_silk_aid` | 慈护 | 回合开始时：恢复生命最低友军 3 点生命。 |
| `madai` | 马岱 | shu | warrior | `madai_frontier_cut` | 边袭 | 攻击命中后：追加 1 点物理伤害。 |
| `xuchu` | 许褚 | wei | tank | `xuchu_tiger_guard` | 虎痴护体 | 部署时：自身获得 3 点护盾。 |
| `zhenji` | 甄姬 | wei | mage | `zhenji_luoshen_freeze` | 洛神凝霜 | 攻击命中后：目标眩晕 1 回合。 |
| `caoren` | 曹仁 | wei | tank | `caoren_fortress_guard` | 固守 | 回合开始时：自身获得 2 点护盾。 |
| `caopi` | 曹丕 | wei | mage | `caopi_edict` | 文帝令 | 部署时：敌方全军攻击 -1，持续 1 回合。 |
| `lejin` | 乐进 | wei | assassin | `lejin_breakthrough` | 先登 | 攻击命中后：追加 2 点物理伤害。 |
| `xiahoudun` | 夏侯惇 | wei | warrior | `xiahoudun_blood_eye` | 刚烈 | 回合开始时：自身攻击 +1。 |
| `ganning` | 甘宁 | wu | assassin | `ganning_jinfan_raid` | 锦帆袭 | 攻击命中后：追加 2 点物理伤害。 |
| `sunjian` | 孙坚 | wu | warrior | `sunjian_tiger_roar` | 江东虎啸 | 回合开始时：自身攻击 +1，并回复 1 点生命。 |
| `lumeng` | 吕蒙 | wu | warrior | `lumeng_study_strike` | 士别三日 | 部署时：敌方全军攻击 -1，持续 1 回合。 |
| `xiaoqiao` | 小乔 | wu | mage | `xiaoqiao_flower_heal` | 花月 | 回合开始时：恢复生命最低友军 3 点生命。 |
| `taishici` | 太史慈 | wu | archer | `taishici_piercing_arrow` | 贯矢 | 攻击命中后：追加 1 点真实伤害。 |
| `huanggai` | 黄盖 | wu | tank | `huanggai_bitter_guard` | 苦肉护阵 | 部署时：自身获得 3 点护盾。 |
| `zhoutai` | 周泰 | wu | tank | `zhoutai_scar_guard` | 不屈 | 回合开始时：自身获得 2 点护盾。 |
| `lingtong` | 凌统 | wu | warrior | `lingtong_swift_cut` | 急袭 | 攻击命中后：追加 1 点物理伤害。 |
| `lusu` | 鲁肃 | wu | mage | `lusu_alliance_aid` | 结盟 | 回合开始时：生命最低友军攻击 +1，持续 1 回合。 |
| `chengpu` | 程普 | wu | warrior | `chengpu_veteran_aid` | 老将扶持 | 回合开始时：相邻友军回复 1 点生命。 |
| `sunquan` | 孙权 | wu | warrior | `sunquan_command` | 制衡令 | 部署时：生命最低友军攻击 +1，持续 1 回合。 |
| `daqiao` | 大乔 | wu | mage | `daqiao_lotus_heal` | 流离莲护 | 回合开始时：我方全体回复 1 点生命。 |
| `xusheng` | 徐盛 | wu | tank | `xusheng_fortified_line` | 疑城 | 部署时：自身获得 3 点护盾。 |
| `yuanshao` | 袁绍 | qun | warrior | `yuanshao_coalition_order` | 盟主令 | 回合开始时：自身攻击 +1，持续 1 回合。 |
| `yuanshu` | 袁术 | qun | mage | `yuanshu_false_edict` | 伪诏 | 攻击命中后：追加 1 点法术伤害。 |
| `jiaxu` | 贾诩 | qun | mage | `jiaxu_poison_plan` | 毒策 | 攻击命中后：目标获得 2 回合燃烧。 |
| `chengong` | 陈宫 | qun | mage | `chengong_righteous_plan` | 明策 | 攻击命中后：目标眩晕 1 回合。 |
| `gaoshun` | 高顺 | qun | tank | `gaoshun_camp_guard` | 陷阵 | 回合开始时：自身获得 2 点护盾。 |
| `yanliang` | 颜良 | qun | warrior | `yanliang_vanguard_cut` | 猛进 | 攻击命中后：追加 1 点物理伤害。 |
| `wenchou` | 文丑 | qun | warrior | `wenchou_hook_spear` | 钩骑 | 攻击命中后：追加 1 点物理伤害。 |

## 职业定位检查

| 职业 | 本阶段落地方向 | 结论 |
|---|---|---|
| Tank | 护盾、援护、承伤 | 符合 MVP |
| Warrior | 固定追加伤害、攻击成长、短期压制 | 符合 MVP |
| Archer | 追加真实伤害、持续输出 | 符合 MVP |
| Mage | 法术伤害、治疗、控制、Debuff、召唤 | 符合 MVP |
| Assassin | 攻击命中后的固定爆发 | 符合 MVP |

## 低数值合规

- 没有百分比、倍率、概率或双倍伤害。
- 常见追加伤害控制在 `1` 到 `2`。
- 治疗控制在 `1` 到 `3`。
- 护盾控制在 `2` 到 `3`。
- 控制持续 `1` 回合。
- 仍需精品化：全部 34 个新增技能都是 MVP 技能，后续需要按武将个性做第二轮差异化，但不影响当前可玩闭环。

## 100 局模拟结果

报告路径：`tmp/skill_completion/simulation_100.json`

- 样本数：100。
- 完成局数：100。
- 超时：0。
- 左侧胜利：51。
- 右侧胜利：49。
- 双方同时失败：0。
- 异常数：0。

阵营胜率：

- 群：313 / 600，52.2%。
- 蜀：330 / 639，51.6%。
- 魏：324 / 628，51.6%。
- 吴：415 / 848，48.9%。

职业胜率：

- Archer：110 / 186，59.1%。
- Assassin：41 / 100，41.0%。
- Mage：488 / 940，51.9%。
- Tank：219 / 441，49.7%。
- Warrior：524 / 1048，50.0%。

模拟极值：

- 最高伤害：`huangzhong`，1217。
- 最高治疗：`xiaoqiao`，523。
- 最高承伤：`guanyu`，428。

明显偏强观察：

- `taishici`：69.8%。
- `huangzhong`：66.7%。
- `pangtong`：65.8%。
- `gongsunzan`：60.0%。
- `xiahoudun`：60.0%。

明显偏弱观察：

- `sunshangxiang`：38.6%。
- `ganning`：38.8%。
- `guanping`：42.0%。
- `lusu`：42.1%。
- `madai`：42.3%。

这些只是 100 局快速模拟信号，不作为最终平衡结论。

## 验证入口

```powershell
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m88_hero_skill_completion_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://scripts/tools/run_skill_completion_simulation.gd
powershell -ExecutionPolicy Bypass -File scripts/check_test_manifest.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_mvp_manifest_tests.ps1 -GodotBin godot.cmd
```

## 仍需后续精品化

- 部分 Warrior 仍共用“攻击命中后追加 1 点物理伤害”的 MVP 模板，后续应按人物特色拆分。
- Archer 数量少，100 局样本中胜率偏高，需要后续新增样本和调参。
- `zhangjiao` 召唤在当前自动模拟里偏强，后续需要专项看召唤单位价值。
- Tank 整体胜率略低，后续可检查护盾/承伤对胜负的实际贡献。
