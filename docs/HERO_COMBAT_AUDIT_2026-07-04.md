# 55 名武将战斗审计（2026-07-04）

状态：Combat Refactor Sprint v1 审计表

审计口径：读取 `data/heroes.json`，排除召唤单位 `yellow_turban`，共 55 名可玩武将。

## 摘要

- 可玩武将：55
- `skill_ids` 为空：34
- 五职业范围：Mage / Warrior / Tank / Assassin / Archer
- 当前未发现五职业之外的武将职业。
- 本阶段不一次性补齐 34 个空技能，只建立待补清单和修正方向。

## skill_ids 为空待补清单

- `machao` / 马超 / shu / warrior
- `pangtong` / 庞统 / shu / mage
- `weiyan` / 魏延 / shu / warrior
- `jiangwei` / 姜维 / shu / warrior
- `guanping` / 关平 / shu / warrior
- `zhangbao` / 张苞 / shu / warrior
- `mifuren` / 糜夫人 / shu / mage
- `madai` / 马岱 / shu / warrior
- `xuchu` / 许褚 / wei / tank
- `zhenji` / 甄姬 / wei / mage
- `caoren` / 曹仁 / wei / tank
- `caopi` / 曹丕 / wei / mage
- `lejin` / 乐进 / wei / assassin
- `xiahoudun` / 夏侯惇 / wei / warrior
- `ganning` / 甘宁 / wu / assassin
- `sunjian` / 孙坚 / wu / warrior
- `lumeng` / 吕蒙 / wu / warrior
- `xiaoqiao` / 小乔 / wu / mage
- `taishici` / 太史慈 / wu / archer
- `huanggai` / 黄盖 / wu / tank
- `zhoutai` / 周泰 / wu / tank
- `lingtong` / 凌统 / wu / warrior
- `lusu` / 鲁肃 / wu / mage
- `chengpu` / 程普 / wu / warrior
- `sunquan` / 孙权 / wu / warrior
- `daqiao` / 大乔 / wu / mage
- `xusheng` / 徐盛 / wu / tank
- `yuanshao` / 袁绍 / qun / warrior
- `yuanshu` / 袁术 / qun / mage
- `jiaxu` / 贾诩 / qun / mage
- `chengong` / 陈宫 / qun / mage
- `gaoshun` / 高顺 / qun / tank
- `yanliang` / 颜良 / qun / warrior
- `wenchou` / 文丑 / qun / warrior

## 明细

| Hero ID | 武将 | 阵营 | 职业 | 当前 skill_ids | 缺技能? | 违反五职业? | 使用百分比? | 技能描述过长? | 一句话能说明? | 建议修正方向 |
|---|---|---|---|---|---|---|---|---|---|---|
| `guanyu` | 关羽 | shu | warrior | `guanyu_growth` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `zhouyu` | 周瑜 | wu | mage | `zhouyu_burn` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `zhangjiao` | 张角 | qun | mage | `zhangjiao_summon` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `zhaoyun` | 赵云 | shu | warrior | `zhaoyun_dash` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `zhangfei` | 张飞 | shu | tank | `zhangfei_guard` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `machao` | 马超 | shu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `sunshangxiang` | 孙尚香 | wu | archer | `sunshangxiang_combo` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `zhugeliang` | 诸葛亮 | shu | mage | `zhugeliang_growth` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `pangtong` | 庞统 | shu | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `caocao` | 曹操 | wei | mage | `caocao_march` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `simayi` | 司马懿 | wei | mage | `simayi_silence` | 否 | 否 | 否 | 是 | 否 | 压缩为一句话技能说明 |
| `zhangliao` | 张辽 | wei | warrior | `zhangliao_assault` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `luxun` | 陆逊 | wu | mage | `luxun_burn_link` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `lvbu` | 吕布 | qun | warrior | `lvbu_rage` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `huangzhong` | 黄忠 | shu | archer | `huangzhong_snipe` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `weiyan` | 魏延 | shu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `jiangwei` | 姜维 | shu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `guojia` | 郭嘉 | wei | mage | `guojia_strategy` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `dianwei` | 典韦 | wei | tank | `dianwei_rage` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `xunyu` | 荀彧 | wei | mage | `xunyu_aid` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `dongzhuo` | 董卓 | qun | tank | `dongzhuo_feast` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `diaochan` | 貂蝉 | qun | mage | `diaochan_charm` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `gongsunzan` | 公孙瓒 | qun | archer | `gongsunzan_cavalry` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `huaxiong` | 华雄 | qun | warrior | `huaxiong_execute` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `guanping` | 关平 | shu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `zhangbao` | 张苞 | shu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `mifuren` | 糜夫人 | shu | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `madai` | 马岱 | shu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `xuchu` | 许褚 | wei | tank | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `zhenji` | 甄姬 | wei | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `caoren` | 曹仁 | wei | tank | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `caopi` | 曹丕 | wei | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `lejin` | 乐进 | wei | assassin | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `xiahoudun` | 夏侯惇 | wei | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `ganning` | 甘宁 | wu | assassin | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `sunjian` | 孙坚 | wu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `lumeng` | 吕蒙 | wu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `xiaoqiao` | 小乔 | wu | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `taishici` | 太史慈 | wu | archer | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `huanggai` | 黄盖 | wu | tank | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `zhoutai` | 周泰 | wu | tank | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `lingtong` | 凌统 | wu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `lusu` | 鲁肃 | wu | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `chengpu` | 程普 | wu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `sunquan` | 孙权 | wu | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `daqiao` | 大乔 | wu | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `sunce` | 孙策 | wu | warrior | `sunce_assault` | 否 | 否 | 否 | 否 | 是 | 保留当前方向，后续做数值微调 |
| `xusheng` | 徐盛 | wu | tank | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `yuanshao` | 袁绍 | qun | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `yuanshu` | 袁术 | qun | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `jiaxu` | 贾诩 | qun | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `chengong` | 陈宫 | qun | mage | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `gaoshun` | 高顺 | qun | tank | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `yanliang` | 颜良 | qun | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |
| `wenchou` | 文丑 | qun | warrior | 空 | 是 | 否 | 否 | 否 | 否 | 补一句话定位与固定数值技能草案 |

## 结论

- 55 名可玩武将均属于五职业范围。
- 34 名武将缺少 `skill_ids`，后续应按固定数值、一句话定位逐步补齐。
- 本阶段已先处理赵云旧“穿阻挡”定位，改为普通攻击命中后固定追加 1 点伤害。
