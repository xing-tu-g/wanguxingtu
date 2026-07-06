# Wanguxingtu Art Review

This file is the running approval log for hero art assets. Art Bible is the source of truth.

Review rules:
- A resource is final only when score >= 98 and it passes Art Bible checks.
- Hero and Battle assets must have transparent background.
- Character art must not contain FX, text, UI, smoke, fire, slash trails, lightning, ground cracks, debris, or skill circles.
- HeroCard uses `hero_master` only.
- Battle board uses `battle_idle`, `battle_attack`, and `battle_skill` only.
- Enemy direction is handled by Godot `flip_h`; no separate left-facing asset is allowed.

## 2026-07-01 Baseline Review

Scope: completed baseline heroes `zhaoyun`, `guanyu`, `zhangfei`.

Common checks:
- Directory naming: passed. Assets live under `assets/heroes/{hero_id}/`.
- File naming: passed. Each hero has `hero_master.png`, `battle_idle.png`, `battle_attack.png`, `battle_skill.png`.
- Godot data hookup: passed. `data/heroes.json` points `portrait` and `icon` to `hero_master`, and battle fields to the three battle poses.
- Transparent background: passed after alpha cleanup. Original opaque versions are preserved as `.opaque_backup`.
- FX separation: passed. No obvious slash trails, smoke, fire, lightning, ground cracks, text, UI, or skill rings in adopted assets.
- Known technical issue: source PNG dimensions are still large, roughly 1254-1448 px wide/tall. This is acceptable for current alpha but should be compressed/cropped later for package size and runtime memory.

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 赵云 | `assets/heroes/zhaoyun/hero_master.png` | 98 | Yes | Original had opaque light background; file size large. | Converted to transparent alpha, kept body and Dragon Gall Silver Spear readable. | Current transparent PNG |
| 赵云 | `assets/heroes/zhaoyun/battle_idle.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Pose reads fast and forward-ready. | Current transparent PNG |
| 赵云 | `assets/heroes/zhaoyun/battle_attack.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Pose reads as quick thrust. | Current transparent PNG |
| 赵云 | `assets/heroes/zhaoyun/battle_skill.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Aerial charge is allowed for Zhao Yun's skill language. | Current transparent PNG |
| 关羽 | `assets/heroes/guanyu/hero_master.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Heavy Guan Dao silhouette preserved. | Current transparent PNG |
| 关羽 | `assets/heroes/guanyu/battle_idle.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Stable blade-holding idle matches Art Bible. | Current transparent PNG |
| 关羽 | `assets/heroes/guanyu/battle_attack.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Heavy slash pose, no FX. | Current transparent PNG |
| 关羽 | `assets/heroes/guanyu/battle_skill.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Raised blade charge matches skill pose direction. | Current transparent PNG |
| 张飞 | `assets/heroes/zhangfei/hero_master.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Broad body type and snake spear silhouette remain clear. | Current transparent PNG |
| 张飞 | `assets/heroes/zhangfei/battle_idle.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Heavy stance matches "standing like a mountain". | Current transparent PNG |
| 张飞 | `assets/heroes/zhangfei/battle_attack.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Horizontal sweep language is clear. | Current transparent PNG |
| 张飞 | `assets/heroes/zhangfei/battle_skill.png` | 98 | Yes | Original opaque background; large source size. | Converted to transparent alpha. Raised spear and roar-like posture match skill language. | Current transparent PNG |

## Next Hero Queue

Next hero: 马超.

Before generating 马超:
- Create or locate Weapon Master first.
- Define Ma Chao action language before prompt generation.
- Generate and approve in strict order: `hero_master` -> `battle_idle` -> `battle_attack` -> `battle_skill`.
- Do not move to `battle_idle` unless `hero_master` scores >= 98 and passes transparent/background/weapon checks.

## 2026-07-01 Weapon Master Review

| Weapon | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 虎头湛金枪 | `assets/weapons/weapon_hutou_master.png` | 99 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Spear silhouette is long, straight, gold/silver, with clear tiger-head ornament; does not read as guandao, axe, halberd, or fantasy polearm. | Current transparent PNG |
| 铁胎宝弓 | `assets/weapons/weapon_longbow_master.png` | 99 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Tall Chinese recurved war bow silhouette, dark lacquer, muted gold fittings, red cord; does not read as crossbow, spear, staff, or western fantasy bow. | `weapon_longbow_master.v1.png` promoted to final |
| 狂牙雁翎刀 | `assets/weapons/weapon_kuangya_yanling_master.png` | 99 | Yes | First draft rejected because it read too much like a giant fantasy monster blade. | Regenerated and removed chroma-key to alpha. Short-handled curved Chinese saber, distinct from Guan Yu's polearm and not a spear/axe/halberd. | `weapon_kuangya_yanling_master.v2.png` promoted to final |
| 辽锋突袭刀 | `assets/weapons/weapon_liaofeng_assault_dao_master.png` | 98 | Yes | Earlier draft risked reading too long, but v2 is compact enough for Zhang Liao's assault role. | Removed chroma-key to alpha. Short/medium Chinese curved dao with Wei blue-black grip, muted silver blade, gold fittings, and crimson tassel; does not read as guandao, spear, halberd, axe, or western sword. | `weapon_liaofeng_assault_dao_master.v2.png` promoted to final |
| 赤羽指挥扇 | `assets/weapons/weapon_chiyu_command_fan_master.png` | 98 | Yes | Large fan footprint, but it has safe padding and no FX. | Removed chroma-key to alpha. Red-gold Wu strategist fan with feather motifs, distinct from Zhuge Liang/Pang Tong/Sima Yi fans; no fire, glow, phoenix spirit, magic seal, text, UI, or background. | `weapon_chiyu_command_fan_master.v1.png` promoted to final |
| 方天画戟 | `assets/weapons/weapon_fangtian_huaji_master.png` | 98 | Yes | Halberd head is ornate but still reads as Fangtian Huaji. | Removed chroma-key to alpha. Central spear tip, crescent side blades, long pole, red wrapping, and silver-gold fittings are clear; no lightning, glow, smoke, blood, slash trail, text, UI, or background. | `weapon_fangtian_huaji_master.v1.png` promoted to final |
| 赤壁玉箫 | `assets/weapons/weapon_chibi_jade_flute_master.png` | 98 | Yes | Small low-threshold green residue appeared in the alpha audit, but no strict opaque green pixels remained. | Removed chroma-key to alpha. Jade flute with red lacquer ends, gold fittings, and tassel reads clearly as Zhou Yu's command prop; no notes, glow, fire, text, UI, or background. | `weapon_chibi_jade_flute_master.v1.png` promoted to final |
| 太平道符杖 | `assets/weapons/weapon_taiping_talisman_staff_master.v1.png` | 94 | No | Weapon quality and Yellow Turban read were good, but the hanging talisman had clear text-like characters. | Re-generated with abstract decorative talisman marks and stricter no-text constraints. | Rejected v1 |
| 太平道符杖 | `assets/weapons/weapon_taiping_talisman_staff_master.png` | 98 | Yes | The talisman still has abstract red line motifs, but no readable characters or pseudo text. | Removed chroma-key to alpha. Dark wood, yellow wrap, bronze cloud fittings, and Yellow Turban command-prop read are clear; no lightning, glow, smoke, fire, text, UI, or background. | `weapon_taiping_talisman_staff_master.v2.png` promoted to final |
| 吴姬双月弓 | `assets/weapons/weapon_wu_twin_crescent_bows_master.png` | 98 | Yes | Low-threshold green edge pixels remain around thin bowstrings, but no strict opaque green residue is visible. | Removed chroma-key to alpha. Twin compact red lacquer recurve bows with gold fittings, teal grips, and tassels read as agile Wu princess weapons, distinct from Huang Zhong's heavy longbow; no projectile/FX/text/UI/background. | `weapon_wu_twin_crescent_bows_master.v1.png` promoted to final |
| 黄巾短矛 | `assets/weapons/weapon_yellow_turban_short_spear_master.png` | 98 | Yes | Simple weapon has intentionally low-rank detail, but remains clean and readable. | Removed chroma-key to alpha. Short dark-wood militia spear with plain iron leaf head and yellow cloth tie is distinct from Zhao Yun/Ma Chao hero spears; no glow, trail, blood, text, UI, or background. | `weapon_yellow_turban_short_spear_master.v1.png` promoted to final |
| 奉孝竹简军令 | `assets/weapons/weapon_fengxiao_bamboo_scroll_master.png` | 98 | Yes | Right and bottom margins are usable but not generous due to the wide scroll and gourd charm. | Removed chroma-key to alpha. Blank bamboo strategy scroll, Wei-blue cord, silver/bronze end caps, jade bead, and wine gourd charm read clearly as Guo Jia's strategist prop; no readable writing, smoke, glow, text, UI, or background. | `weapon_fengxiao_bamboo_scroll_master.v1.png` promoted to final |

Ma Chao action language draft:
- Body type: Xiliang cavalry commander; compact Q-version body, broader and more armored than Zhao Yun, less bulky than Guan Yu/Zhang Fei.
- Historical identity: Jin Ma Chao / Xiliang; practical silver cavalry helm with horsehair plume, fur-trimmed cavalry cape, frontier textile panels, proud stern face.
- Important distinction: Ma Chao must not read as Zhao Yun with a swapped weapon. His identity comes from Xiliang cavalry armor, borderland textiles, heavier horseman stance, and a proud young warlord face.
- Weapon: `weapon_hutou_master.png` only; tiger-head bright golden spear.
- Hero Master: confident cavalry-general stance, facing right, weapon visible and readable, no FX.
- Battle Idle: mounted-charge tension without horse; spear angled forward, ready to lunge.
- Battle Attack: grounded heavy spear thrust, not a Zhao Yun-like light stab, not jumping, no trails.
- Battle Skill: low braced cavalry-charge pose, stronger forward drive, no FX.

## 2026-07-01 Ma Chao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 马超 | `assets/heroes/machao/hero_master.rejected_zhaoyun_like.png` | 86 | No | Rejected by user review: looked like Zhao Yun with a different weapon; historical Ma Chao identity was weak. | Kept only as rejected trace asset; do not use in Godot. | Rejected v1 |
| 马超 | `assets/heroes/machao/battle_idle.rejected_zhaoyun_like.png` | 86 | No | Same identity issue as v1 Hero Master; reads as Zhao Yun-like spear hero. | Replaced by Xiliang cavalry design. | Rejected v1 |
| 马超 | `assets/heroes/machao/battle_attack.rejected_zhaoyun_like.png` | 86 | No | Same identity issue as v1 Hero Master; action and face too close to Zhao Yun language. | Replaced by heavier low-center cavalry thrust. | Rejected v1 |
| 马超 | `assets/heroes/machao/battle_skill.rejected_zhaoyun_like.png` | 86 | No | Same identity issue as v1 Hero Master; not historically recognizable enough. | Replaced by Xiliang cavalry charge pose. | Rejected v1 |
| 马超 | `assets/heroes/machao/hero_master.v2.png` | 94 | No | Still read too much like a generic fantasy white/silver spear hero; historical Xiliang identity was present but not strong enough. | Replaced after user review. New standard: Ma Chao must be recognizable through Xiliang cavalry silhouette, beast helm, fur cape, heavier armor, and lower stance, not only the tiger-head spear. | Replaced v2 |
| 马超 | `assets/heroes/machao/battle_idle.v3.png` | 92 | No | Transparent extraction passed, but the spear touched the right canvas edge, creating crop risk for Godot board scaling. | Re-generated with larger padding. | Rejected v3 |
| 马超 | `assets/heroes/machao/hero_master.replaced_too_fantasy_v3.png` | 95 | No | User review correctly identified that the approved version still leaned too much on fantasy tiger armor and did not feel historically specific enough. | Preserved as trace asset only. Future Ma Chao prompts must avoid giant beast helm/shoulders and emphasize Xiliang cavalry identity. | Replaced v3 |
| 马超 | `assets/heroes/machao/battle_idle.replaced_too_fantasy_v4.png` | 95 | No | Technically usable, but it still belonged to the older fantasy tiger-armor direction and no longer matched the revised historically grounded Ma Chao Hero Master. | Preserved as trace asset only. Replaced to keep the full four-image set visually unified. | Replaced v4 |
| 马超 | `assets/heroes/machao/battle_attack.replaced_too_fantasy_v3.png` | 95 | No | Low attack motion was usable, but the armor/helmet still matched the older fantasy tiger-armor direction. | Preserved as trace asset only. Replaced with a practical Xiliang cavalry attack pose. | Replaced v3 |
| 马超 | `assets/heroes/machao/battle_skill.replaced_too_fantasy_v3.png` | 95 | No | Pose was usable, but the character identity still leaned toward the older fantasy tiger-armor version. | Preserved as trace asset only. Replaced with a historically grounded breakthrough skill pose. | Replaced v3 |
| 马超 | `assets/heroes/machao/hero_master.v4.png` | 96 | No | Stronger historical read, but the spear touched the right canvas edge, creating crop risk in HeroCard and Godot board scaling. | Re-generated with compact diagonal spear and safe padding. | Rejected v4 |
| 马超 | `assets/heroes/machao/hero_master.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Historical Ma Chao read improved: silver Xiliang cavalry lamellar armor, horsehair plume, fur cloak, red scarf, frontier textile panels, stern young warlord face, compact tiger-head spear, no FX/text/UI/background. | `hero_master.v5.png` promoted to `hero_master.png` |
| 马超 | `assets/heroes/machao/battle_idle.png` | 98 | Yes | Generated source used chroma-key background; right padding is acceptable but should be watched if later cropped. | Removed chroma-key to alpha. Unified with revised Ma Chao: practical Xiliang silver cavalry armor, horsehair plume, red scarf, fur cloak, compact ready stance, no FX/text/UI/background. | `battle_idle.v5.png` promoted to `battle_idle.png` |
| 马超 | `assets/heroes/machao/battle_attack.png` | 98 | Yes | Generated source used chroma-key background; spear tip padding is usable but not generous. | Removed chroma-key to alpha. Grounded heavy cavalry spear thrust, practical helm/shoulders, tiger motif limited to the spear socket, no Zhao Yun-like jump or spear trail/FX/text/UI/background. | `battle_attack.v4.png` promoted to `battle_attack.png` |
| 马超 | `assets/heroes/machao/battle_skill.png` | 98 | Yes | Generated source used chroma-key background; bottom margin is acceptable but tighter than master art. | Removed chroma-key to alpha. Stronger low braced cavalry-breakthrough skill pose, character-only frame, no smoke/fire/glow/spear trail/dust/ground crack/skill circle/text/UI/background. | `battle_skill.v4.png` promoted to `battle_skill.png` |

## 2026-07-01 Huang Zhong Plan

Huang Zhong action language draft:
- Body type: veteran Shu archer; compact Q-version body, slightly broad shoulders, lower energy than Zhao Yun/Ma Chao but sharper focus.
- Historical identity: old general, white eyebrows and beard, calm eyes, disciplined posture, veteran armor with Shu red-green and muted gold accents.
- Weapon: `weapon_longbow_master.png` only; iron-backed ornate Chinese longbow.
- Hero Master: proud old archer stance, facing right, bow visible and readable, no FX.
- Battle Idle: steady aiming-ready posture, bow held low or half-raised, no arrow release.
- Battle Attack: clean bow draw/release pose, no arrow trail or glow.
- Battle Skill: full-draw sniper focus pose, stronger concentration than attack, no FX.

## 2026-07-01 Huang Zhong Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 黄忠 | `assets/heroes/huangzhong/hero_master.png` | 98 | Yes | First generated draft was rejected before import because it was too adult-proportioned; accepted source is still large and bow occupies tall right-side space. | Removed chroma-key to alpha. Veteran Shu archer identity is clear: white eyebrows/beard, disciplined old-general face, Shu green/red armor, approved longbow, no FX/text/UI/background. | `hero_master.v1.png` promoted to `hero_master.png` |
| 黄忠 | `assets/heroes/huangzhong/battle_idle.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Steady old-archer ready stance, bow held without release, no arrow trail/FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| 黄忠 | `assets/heroes/huangzhong/battle_attack.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Clean normal bow attack pose with arrow held on string, no flying projectile/FX/text/UI/background. | `battle_attack.v1.png` promoted to `battle_attack.png` |
| 黄忠 | `assets/heroes/huangzhong/battle_skill.png` | 98 | Yes | First skill draft was rejected because it was too similar to the normal attack pose; accepted source is still large. | Removed chroma-key to alpha. Low braced veteran sniper charge pose, clearly stronger than normal attack, no flying projectile/FX/text/UI/background. | `battle_skill.v2.png` promoted to `battle_skill.png` |

## 2026-07-01 Wei Yan Plan

Wei Yan action language draft:
- Body type: wild Shu vanguard; compact Q-version body, leaner than Zhang Fei, rougher and more dangerous than Zhao Yun.
- Historical identity: fierce and controversial Shu general; sharp eyes, untamed hair or wolfish crest, dark green/black armor, red cords, fang/beast motifs.
- Weapon: `weapon_kuangya_yanling_master.png` only; short-handled curved yanling saber, never Guan Yu's polearm.
- Hero Master: crouched predatory stance, facing right, saber visible and readable, no FX.
- Battle Idle: low ambush-ready posture, blade angled across body.
- Battle Attack: fast diagonal saber slash, no slash trail.
- Battle Skill: feral breakthrough/lunge pose, stronger body twist than attack, no FX.

## 2026-07-01 Wei Yan Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 魏延 | `assets/heroes/weiyan/hero_master.png` | 98 | Yes | First two hero drafts were rejected because the saber drifted into monster/saw-tooth blade territory; accepted source is still large. | Removed chroma-key to alpha. Wild Shu vanguard identity, crouched predatory stance, smooth yanling saber, no FX/text/UI/background. | `hero_master.v3.png` promoted to `hero_master.png` |
| 魏延 | `assets/heroes/weiyan/battle_idle.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Low ambush-ready posture, smooth saber across body, no attack slash/FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| 魏延 | `assets/heroes/weiyan/battle_attack.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Fast diagonal saber slash, smooth blade, no slash trail/FX/text/UI/background. | `battle_attack.v1.png` promoted to `battle_attack.png` |
| 魏延 | `assets/heroes/weiyan/battle_skill.png` | 98 | Yes | Generated source used chroma-key background with mild variation; source file is still large. | Removed chroma-key to alpha. Low feral breakthrough pose, stronger than normal attack, smooth blade, no slash trail/FX/text/UI/background. | `battle_skill.v1.png` promoted to `battle_skill.png` |

## 2026-07-01 Jiang Wei Plan

Jiang Wei action language draft:
- Body type: young strategist-general; compact Q-version body, refined and upright, less airy than Zhao Yun and less armored than Ma Chao.
- Historical identity: scholar-warrior successor; calm eyes, clean face, blue-green Shu armor, jade scholar ornaments, disciplined commander silhouette.
- Weapon: `weapon_luchen_spear_master.png` only; refined green-sunk straight spear, never tiger-head, snake spear, guandao, or halberd.
- Hero Master: poised commander stance, facing right, spear readable, no FX.
- Battle Idle: guarded tactical ready pose, spear vertical/diagonal with measured balance.
- Battle Attack: precise spear thrust or controlled sweep, no spear trail.
- Battle Skill: tactical command-lunge pose, more focused and strategic than attack, no FX.

## 2026-07-01 Jiang Wei Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 姜维 | `assets/heroes/jiangwei/hero_master.png` | 98 | Yes | First hero draft was rejected because spearhead drifted into forked/halberd-like shape; accepted source is still large. | Removed chroma-key to alpha. Young Shu strategist-general identity, blue-green jade armor, refined green-sunk spear, no FX/text/UI/background. | `hero_master.v2.png` promoted to `hero_master.png` |
| 姜维 | `assets/heroes/jiangwei/battle_idle.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Guarded tactical ready pose, single leaf spearhead, no attack motion/FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| 姜维 | `assets/heroes/jiangwei/battle_attack.png` | 98 | Yes | Generated source used chroma-key background with gradient variation; source file is still large. | Removed chroma-key to alpha. Precise controlled spear thrust, single leaf spearhead, no spear trail/FX/text/UI/background. | `battle_attack.v1.png` promoted to `battle_attack.png` |
| 姜维 | `assets/heroes/jiangwei/battle_skill.png` | 98 | Yes | Generated source used chroma-key background; source file is still large. | Removed chroma-key to alpha. Low tactical command-lunge pose, more focused than normal attack, single leaf spearhead, no spear trail/FX/text/UI/background. | `battle_skill.v1.png` promoted to `battle_skill.png` |

## 2026-07-01 Zhuge Liang Plan

Zhuge Liang action language draft:
- Body type: refined Shu strategist; compact Q-version body, upright and calm, no warrior armor silhouette.
- Historical identity: Kongming strategist; scholar guan/headscarf, ivory and teal robes, composed eyes, feather fan.
- Weapon: `weapon_feather_fan_master.png` only; crane-feather fan with jade handle and muted gold fittings, never staff/sword/spear.
- Hero Master: calm tactical stance, facing right, fan visible, no FX.
- Battle Idle: quiet command-ready pose, fan held near chest/side, no magic circle.
- Battle Attack: sharp fan command gesture, normal attack only, no wind slash/projectile.
- Battle Skill: stronger fan-raised command pose, character-only, no bagua/lightning/wind/fire.

## 2026-07-01 Zhuge Liang Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Zhuge Liang | `assets/weapons/weapon_feather_fan_master.png` | 98 | Yes | Generated source used chroma-key background; ornament leans slightly yin-yang but remains a fan prop, not FX. | Removed chroma-key to alpha. Feather fan is readable, no staff/sword/magic effect/text/UI/background. | `weapon_feather_fan_master.v1.png` promoted to `weapon_feather_fan_master.png` |
| Zhuge Liang | generated Hero Master v1 | 92 | No | Proportion was too adult/tall for Art Bible 2.5-3 heads Q-version standard. | Re-generated with stronger chibi proportion requirement. | Rejected v1 |
| Zhuge Liang | `assets/heroes/zhugeliang/hero_master.png` | 98 | Yes | Tall guan makes vertical footprint large, but HeroCard readability is strong. | Removed chroma-key to alpha. Q-version Shu strategist identity, feather fan visible, no FX/text/UI/background. | `hero_master.v2.png` promoted to `hero_master.png` |
| Zhuge Liang | `assets/heroes/zhugeliang/battle_idle.png` | 98 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Compact command-ready pose, fan visible, no attack/skill FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| Zhuge Liang | generated Battle Attack v1 | 90 | No | Background came out black, making reliable transparency extraction unsafe. | Re-generated with strict magenta chroma-key background. | Rejected v1 |
| Zhuge Liang | `assets/heroes/zhugeliang/battle_attack.png` | 98 | Yes | Generated source used magenta chroma-key background. | Removed chroma-key to alpha. Normal fan-command attack pose, no wind/projectile/slash/FX/text/UI/background. | `battle_attack.v2.png` promoted to `battle_attack.png` |
| Zhuge Liang | `assets/heroes/zhugeliang/battle_skill.png` | 98 | Yes | Generated source used magenta chroma-key background. | Removed chroma-key to alpha. Stronger fan-raised skill pose, character-only frame, no bagua/lightning/wind/fire/FX/text/UI/background. | `battle_skill.v1.png` promoted to `battle_skill.png` |

## 2026-07-01 Pang Tong Plan

Pang Tong action language draft:
- Body type: eccentric Shu strategist; compact Q-version body, slightly hunched clever posture, less orderly and elegant than Zhuge Liang.
- Historical identity: Fengchu strategist; sharp sly eyes, loose scholar cap/headscarf, untidy hair, dark teal/deep brown robes with muted crimson and antique bronze accents.
- Weapon: `weapon_fengchu_fan_master.png` only; dark phoenix-feather strategist fan, never staff/sword/spear and never Zhuge Liang's white fan.
- Hero Master: sly tactical thinker pose, facing right, fan visible, no FX.
- Battle Idle: plotting-ready pose, compact board silhouette, no magic effect.
- Battle Attack: quick fan-command gesture, normal attack only, no fire/wind/projectile.
- Battle Skill: stronger fan-raised tactical reveal pose, character-only, no phoenix/fire/glow/formation.

## 2026-07-01 Pang Tong Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Pang Tong | `assets/weapons/weapon_fengchu_fan_master.png` | 98 | Yes | Generated source used chroma-key background; ornament is ornate but remains a prop, not FX. | Removed chroma-key to alpha. Dark phoenix-feather fan is distinct from Zhuge Liang's white fan and has no flame/phoenix spirit/glow/text/UI/background. | `weapon_fengchu_fan_master.v1.png` promoted to `weapon_fengchu_fan_master.png` |
| Pang Tong | `assets/heroes/pangtong/hero_master.png` | 98 | Yes | Large sleeve and fan make the master art wide, but HeroCard readability is strong. | Removed chroma-key to alpha. Fengchu identity is clear: sly expression, loose scholar cap, dark robes, dark fan, no FX/text/UI/background. | `hero_master.v1.png` promoted to `hero_master.png` |
| Pang Tong | `assets/heroes/pangtong/battle_idle.png` | 98 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Compact plotting-ready pose, fan held near body, no skill FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| Pang Tong | `assets/heroes/pangtong/battle_attack.png` | 98 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Quick fan-command normal attack pose, no phoenix fire/wind/projectile/FX/text/UI/background. | `battle_attack.v1.png` promoted to `battle_attack.png` |
| Pang Tong | `assets/heroes/pangtong/battle_skill.png` | 98 | Yes | Generated source used chroma-key background; a few green edge pixels were removed after extraction. | Removed chroma-key to alpha and cleaned residual green pixels. Stronger fan-raised tactical reveal pose, character-only frame, no phoenix/fire/glow/formation/FX/text/UI/background. | `battle_skill.v1.png` promoted to `battle_skill.png` |

## 2026-07-01 Cao Cao Plan

Cao Cao action language draft:
- Body type: Wei ruler-strategist; compact Q-version body, mature commander posture, stronger authority than Shu strategists but not a brute warrior.
- Historical identity: Cao Cao / Wei ruler; sharp commanding eyes, short moustache and beard, black/deep crimson Wei armor-robes, muted gold trim, dark cloak, regal commander crown.
- Weapon: `weapon_yitian_command_sword_master.png` only; Han-Wei straight command jian, never staff/spear/western broadsword.
- Hero Master: ruler command stance, facing right, sword visible, no FX.
- Battle Idle: stable command-ready pose, compact board silhouette, no aura.
- Battle Attack: decisive command-sword forward gesture, normal attack only, no sword beam/slash trail.
- Battle Skill: stronger imperial order pose for march command, character-only, no soldiers/flags/aura.

## 2026-07-01 Cao Cao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Cao Cao | `assets/weapons/weapon_yitian_command_sword_master.png` | 98 | Yes | Generated source used chroma-key background; guard is ornate but still reads as Han-Wei command jian. | Removed chroma-key to alpha. Straight sword silhouette is clear, no glow/slash/smoke/text/UI/background. | `weapon_yitian_command_sword_master.v1.png` promoted to `weapon_yitian_command_sword_master.png` |
| Cao Cao | generated Hero Master v1 | 93 | No | Cao Cao identity was good, but the sword tip was too close to the canvas edge, creating crop risk. | Re-generated with explicit padding requirement. | Rejected v1 |
| Cao Cao | `assets/heroes/caocao/hero_master.png` | 98 | Yes | Sword is slightly broad, but still reads as a Chinese straight command sword. | Removed chroma-key to alpha. Wei ruler-strategist identity is strong, no FX/text/UI/background. | `hero_master.v2.png` promoted to `hero_master.png` |
| Cao Cao | `assets/heroes/caocao/battle_idle.png` | 98 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Stable commander idle pose, sword and cloak compact enough for board use, no FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| Cao Cao | `assets/heroes/caocao/battle_attack.png` | 98 | Yes | Generated source used chroma-key background; sprite is wide but has safe sword padding. | Removed chroma-key to alpha. Decisive command-sword normal attack, no sword beam/slash trail/FX/text/UI/background. | `battle_attack.v1.png` promoted to `battle_attack.png` |
| Cao Cao | `assets/heroes/caocao/battle_skill.png` | 98 | Yes | Generated source used chroma-key background; sword is long but safely inside canvas. | Removed chroma-key to alpha. Strong imperial order skill pose, character-only frame, no soldiers/flags/aura/FX/text/UI/background. | `battle_skill.v1.png` promoted to `battle_skill.png` |

## 2026-07-01 Sima Yi Plan

Sima Yi action language draft:
- Body type: cold Wei strategist; compact Q-version body, guarded posture, quieter and more suspicious than Cao Cao.
- Historical identity: Sima Yi / eagle-eyed wolf-gaze strategist; narrow eyes, thin moustache and beard, black/silver/dark navy robes, high Wei official headgear.
- Weapon: `weapon_xuanmou_fan_master.png` only; black and silver-grey strategist fan, never staff/sword/spear and never Zhuge Liang/Pang Tong fan copy.
- Hero Master: guarded calculating stance, facing right, fan visible, no FX.
- Battle Idle: compact silent-pressure pose, fan close to body, no aura.
- Battle Attack: subtle fan-pressure/control gesture, normal attack only, no silence seal or shadow effect.
- Battle Skill: stronger sealing command pose, character-only, no black smoke/ghosts/silence circle.

## 2026-07-01 Sima Yi Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Sima Yi | `assets/weapons/weapon_xuanmou_fan_master.png` | 98 | Yes | Generated source used chroma-key background; ornament is ornate but still reads as a Wei command fan. | Removed chroma-key to alpha. Black-silver fan is distinct from Zhuge Liang and Pang Tong fans, no smoke/seal/glow/text/UI/background. | `weapon_xuanmou_fan_master.v1.png` promoted to `weapon_xuanmou_fan_master.png` |
| Sima Yi | `assets/heroes/simayi/hero_master.png` | 98 | Yes | Cape is slightly wide, but HeroCard readability is strong. | Removed chroma-key to alpha. Cold Wei strategist identity is clear, fan visible, no black smoke/silence seal/FX/text/UI/background. | `hero_master.v1.png` promoted to `hero_master.png` |
| Sima Yi | `assets/heroes/simayi/battle_idle.png` | 98 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Compact guarded idle pose, fan close to body, no aura/FX/text/UI/background. | `battle_idle.v1.png` promoted to `battle_idle.png` |
| Sima Yi | `assets/heroes/simayi/battle_attack.png` | 98 | Yes | Generated source used chroma-key background. | Removed chroma-key to alpha. Subtle fan-pressure normal attack, no silence icon/seal/projectile/FX/text/UI/background. | `battle_attack.v1.png` promoted to `battle_attack.png` |
| Sima Yi | `assets/heroes/simayi/battle_skill.png` | 98 | Yes | Generated source used chroma-key background; bottom margin is acceptable but tighter than idle. | Removed chroma-key to alpha. Stronger sealing-command skill pose, character-only frame, no black smoke/ghosts/silence circle/FX/text/UI/background. | `battle_skill.v1.png` promoted to `battle_skill.png` |

## 2026-07-01 Zhang Liao Plan

Zhang Liao action language draft:
- Body type: disciplined Wei assault commander; compact Q-version body, athletic and controlled, less wild than Wei Yan and less imperial than Cao Cao.
- Historical identity: Hefei raid general; dark blue-black Wei armor, practical Han-Wei lamellar plates, crimson sash, short commander cloak, stern focused face.
- Weapon: `weapon_liaofeng_assault_dao_master.png` only; compact curved assault dao, never guandao, spear, halberd, axe, or western sword.
- Hero Master: coiled assault stance, facing right, dao readable, no FX.
- Battle Idle: low alert posture, dao close to body, no attack motion.
- Battle Attack: disciplined forward dao cut, normal attack only, no blade trail.
- Battle Skill: stronger breakthrough pose, character-only, no soldiers/flags/aura/slash trail.

## 2026-07-01 Zhang Liao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 张辽 | generated Battle Idle v1 | 93 | No | Overall identity was close, but shoulder armor drifted into animal-head fantasy armor and the dao felt too large. | Re-generated with plain lamellar shoulders and a compact board-friendly dao. | Rejected v1 |
| 张辽 | `assets/heroes/zhangliao/hero_master.png` | 98 | Yes | Cloak is wide, but HeroCard readability and margins are acceptable. | Removed chroma-key to alpha. Wei assault commander identity is clear: dark blue-black armor, crimson sash, compact curved dao, no FX/text/UI/background. | `hero_master.v1.png` promoted to final |
| 张辽 | `assets/heroes/zhangliao/battle_idle.png` | 98 | Yes | Small belt beast ornament is present but does not define the armor silhouette. | Removed chroma-key to alpha. Plain lamellar shoulders, compact idle stance, dao close to body, no attack/skill FX/text/UI/background. | `battle_idle.v2.png` promoted to final |
| 张辽 | `assets/heroes/zhangliao/battle_attack.png` | 98 | Yes | Generated source had slightly varied green background; alpha cleanup left no strict green residue. | Removed chroma-key to alpha. Disciplined forward assault cut, no slash trail/blade glow/motion blur/FX/text/UI/background. | `battle_attack.v1.png` promoted to final |
| 张辽 | `assets/heroes/zhangliao/battle_skill.png` | 98 | Yes | Generated source had slightly varied green background; final has one low-threshold greenish pixel but no strict opaque green residue. | Removed chroma-key to alpha. Stronger low braced breakthrough pose, character-only frame, no soldiers/flags/slash trail/aura/FX/text/UI/background. | `battle_skill.v1.png` promoted to final |

## 2026-07-01 Lu Xun Plan

Lu Xun action language draft:
- Body type: refined young Eastern Wu strategist-mage; compact Q-version body, elegant and decisive, less flamboyant than Zhou Yu and less immortal-like than Zhuge Liang.
- Historical identity: young Wu commander-scholar; red, deep teal, warm ivory, muted gold, light lamellar commander armor, scholar sleeves, clean hair crown.
- Weapon: `weapon_chiyu_command_fan_master.png` only; red-gold Wu command fan with feather motifs, never staff/sword/spear.
- FX separation: Lu Xun may imply fire tactics through red-gold color, but hero and battle sprites must never contain fire, flames, glow, sparks, smoke, phoenix spirit, fire bird, magic circle, projectile, or wind trail.
- Hero Master: calm presentation stance, fan close to body, no attack/casting effect.
- Battle Idle: composed ready stance, fan near chest or side, no spell action.
- Battle Attack: restrained fan-command gesture, normal attack only, no projectile or fire.
- Battle Skill: stronger command order pose, character-only, no fire or magic FX.

## 2026-07-01 Lu Xun Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 陆逊 | `assets/heroes/luxun/hero_master.v1.png` | 94 | No | Technically clean, but the pose read too much like active spell-casting and the fan/right edge padding was tight. | Re-generated with a calmer presentation pose and the fan closer to the body. | Rejected v1 |
| 陆逊 | `assets/heroes/luxun/hero_master.png` | 98 | Yes | Top headpiece margin is tighter than ideal but not cropped. | Removed chroma-key to alpha. Young Wu strategist identity is clear, Chiyu Command Fan visible, no fire/glow/magic circle/text/UI/background. | `hero_master.v2.png` promoted to final |
| 陆逊 | `assets/heroes/luxun/battle_idle.png` | 98 | Yes | Generated source had mild green variation but final alpha is clean. | Removed chroma-key to alpha. Calm board idle stance, fan held close, no attack/skill/fire/FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| 陆逊 | `assets/heroes/luxun/battle_attack.png` | 98 | Yes | Bottom margin is usable but not generous. | Removed chroma-key to alpha. Controlled fan-command normal attack, no fire, projectile, fan slash, wind trail, glow, FX, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| 陆逊 | `assets/heroes/luxun/battle_skill.png` | 98 | Yes | Final has a few low-threshold greenish edge pixels but no strict opaque green residue. | Removed chroma-key to alpha. Stronger tactical command pose, character-only frame, no fire/flames/glow/sparks/phoenix/magic circle/projectile/FX/text/UI/background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Lu Bu Plan

Lu Bu action language draft:
- Body type: strongest battlefield warrior; compact Q-version body with broad practical armor and heavy pressure, not a demonic monster or western dark lord.
- Historical identity: Three Kingdoms Lu Bu; red-black-gold Han warrior armor, twin pheasant-feather lingzi headpiece, proud intimidating face, no horse in hero/battle sprites.
- Weapon: `weapon_fangtian_huaji_master.png` only; Fangtian Huaji with central spear tip and crescent side blades, never axe, simple spear, guandao, western halberd, scythe, or monster blade.
- FX separation: Lu Bu sprites must not include lightning, blood, black smoke, flame aura, weapon glow, slash trail, impact, rocks, ground cracks, or skill circle.
- Hero Master: dominant presentation stance, halberd readable, no attack FX.
- Battle Idle: heavy ready stance, halberd close enough for board use, no attack motion.
- Battle Attack: grounded heavy halberd strike, normal attack only, no trail.
- Battle Skill: stronger low braced breakthrough pose, character-only, no FX.

## 2026-07-02 Lu Bu Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 吕布 | `assets/heroes/lvbu/hero_master.v1.png` | 94 | No | Strong Lu Bu read, but armor leaned too much on beast-head fantasy decoration and right padding was tight. | Re-generated with plain lamellar armor and historical identity carried by lingzi plumes and Fangtian Huaji. | Rejected v1 |
| 吕布 | generated Battle Idle v1 | 93 | No | Idle motion was usable, but beast-face belt and fantasy armor risk returned. | Re-generated with geometric buckle, plain lamellar shoulders, and compact board stance. | Rejected v1 |
| 吕布 | generated Battle Attack v1 | 92 | No | Animal-head armor and monster-like halberd details returned. | Re-generated with strict no-beast-ornament constraints. | Rejected v1 |
| 吕布 | `assets/heroes/lvbu/battle_attack.v2.png` | 96 | No | Cleaner armor, but halberd head was too close to the right canvas edge. | Re-generated with compact pose and explicit safe padding. | Rejected v2 |
| 吕布 | generated Battle Skill v1 | 94 | No | Skill pose direction was good, but beast-face belt returned and halberd risked edge/crop issues. | Re-generated with cleaner armor and stronger safe-padding requirement. | Rejected v1 |
| 吕布 | `assets/heroes/lvbu/hero_master.png` | 98 | Yes | Top plume margin is tighter than ideal but not cropped. | Removed chroma-key to alpha. Lu Bu identity is clear through red-black-gold armor, twin pheasant plumes, Fangtian Huaji, no horse/FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| 吕布 | `assets/heroes/lvbu/battle_idle.png` | 98 | Yes | Tall plumes increase vertical footprint but margins are safe. | Removed chroma-key to alpha. Heavy idle pressure, halberd close to body, no attack/skill FX/text/UI/background. | `battle_idle.v2.png` promoted to final |
| 吕布 | `assets/heroes/lvbu/battle_attack.png` | 98 | Yes | Halberd head is ornate but still reads as Fangtian Huaji. | Removed chroma-key to alpha. Grounded heavy normal attack, no jump, slash trail, weapon glow, lightning, smoke, blood, FX, text, UI, or background. | `battle_attack.v3.png` promoted to final |
| 吕布 | `assets/heroes/lvbu/battle_skill.png` | 98 | Yes | Waist ornament has minor beast-like styling but does not dominate the silhouette; margins are safe. | Removed chroma-key to alpha. Stronger low braced skill pose, character-only frame, no lightning, black smoke, blood, slash trail, impact, ground crack, skill circle, text, UI, or background. | `battle_skill.v2.png` promoted to final |

## 2026-07-02 Zhou Yu Plan

Zhou Yu action language draft:
- Body type: elegant Eastern Wu grand commander; compact Q-version body, mature and calmer than Lu Xun, not a boyish scholar clone.
- Historical identity: Guqu Zhou Lang / Red Cliffs strategist; refined commander eyes, lower wide Wu commander crown, crimson and deep teal robes, light lamellar armor, jade ornaments.
- Weapon: `weapon_chibi_jade_flute_master.png` only; Chibi Jade Command Flute, never fan, sword, spear, staff, guqin, or FX prop.
- FX separation: Zhou Yu may imply Red Cliffs and burn tactics through color and command posture, but hero and battle sprites must never contain fire, smoke, music notes, sound waves, ships, magic circles, glow, or projectile effects.
- Hero Master: mature commander presentation stance, facing right, jade flute visible, no FX.
- Battle Idle: compact ready-command stance, flute close enough for board use, no attack motion.
- Battle Attack: normal flute command strike or point, no sound wave/slash trail.
- Battle Skill: stronger flute-command preparation pose, character-only, no fire or music FX.

## 2026-07-02 Zhou Yu Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 周瑜 | `assets/heroes/zhouyu/hero_master.v1.png` | 94 | No | Technically clean, but the face, high ponytail, crown, and robe language were too close to Lu Xun, making it read like a prop swap. | Re-generated with mature Eastern Wu grand commander direction, lower/wider crown, and stronger Zhou Yu identity. | Rejected v1 |
| 周瑜 | `assets/heroes/zhouyu/hero_master.v2.png` | 95 | No | Zhou Yu identity improved, but body proportion drifted into long realistic/anime proportions instead of Art Bible 2.5-3 heads Q-version. | Re-generated with strict compact Q-version proportions and HeroCard readability constraints. | Rejected v2 |
| 周瑜 | `assets/heroes/zhouyu/hero_master.png` | 98 | Yes | Large hair mass and cloak make the silhouette broad, but margins and HeroCard readability are safe. | Removed chroma-key to alpha. Mature Q-version Wu commander identity is clear: lower commander crown, jade flute, crimson/deep teal robes, no fire/music notes/FX/text/UI/background. | `hero_master.v3.png` promoted to final |
| 周瑜 | `assets/heroes/zhouyu/battle_idle.png` | 98 | Yes | Generated source used chroma-key background; two low-threshold greenish edge pixels remained but no strict opaque green residue. | Removed chroma-key to alpha. Stable board-ready command stance, jade flute close to body, compact enough for grid use, no attack/skill FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| 周瑜 | `assets/heroes/zhouyu/battle_attack.png` | 98 | Yes | Attack pose is wider than idle, but all edges have safe padding. | Removed chroma-key to alpha. Normal flute command strike/point, no sound wave, fire, slash trail, glow, projectile, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| 周瑜 | `assets/heroes/zhouyu/battle_skill.png` | 98 | Yes | Cloak and flute make the skill silhouette wide, but Godot board scaling keeps it usable. | Removed chroma-key to alpha. Stronger flute-command preparation pose, character-only frame, no fire, music notes, sound waves, ships, magic circle, glow, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Zhang Jiao Plan

Zhang Jiao action language draft:
- Body type: Yellow Turban Taiping Dao grand teacher; compact Q-version body, mature and charismatic, not a western wizard or undead mage.
- Historical identity: 大贤良师 / Taiping Dao rebel mystic; yellow headwrap, intense prophetic eyes, short beard, yellow/ochre robes, bronze Taoist ornaments.
- Weapon: `weapon_taiping_talisman_staff_master.png` only; Taiping Dao Talisman Staff with dark wood, yellow wrapping, and bronze cloud fittings. Battle poses remove hanging talisman when needed to avoid text-like marks.
- FX separation: Zhang Jiao may imply thunder/summon through posture, but hero and battle sprites must never contain lightning, glow, smoke, fire, flying paper charms, magic circles, aura, or readable talisman text.
- Hero Master: prophetic command stance, facing right, staff readable, no FX.
- Battle Idle: compact ready-command stance, staff close to body, no casting effect.
- Battle Attack: short close-range staff command strike, normal attack only, no projectile or lightning.
- Battle Skill: stronger staff-raised ritual command pose, character-only, no thunder or ritual FX.

## 2026-07-02 Zhang Jiao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 张角 | `assets/heroes/zhangjiao/hero_master.png` | 98 | Yes | Master silhouette is broad due to robes and staff, but margins are safe and HeroCard readability is strong. | Removed chroma-key to alpha. Yellow Turban grand-teacher identity is clear, Q-version proportion passes, staff and robe motifs are character-only with no lightning/fire/smoke/magic circle/text/UI/background. | `hero_master.v1.png` promoted to final |
| 张角 | `assets/heroes/zhangjiao/battle_idle.v1.png` | 94 | No | Idle stance was good, but the hanging talisman pattern again read too close to pseudo text. | Re-generated without a hanging paper talisman for board battle poses. | Rejected v1 |
| 张角 | `assets/heroes/zhangjiao/battle_idle.png` | 98 | Yes | Tassels and robe folds still make the sprite visually rich, but width is contained enough for board use. | Removed chroma-key to alpha. Stable command-ready pose, no paper talisman, no readable marks, no attack/skill FX/text/UI/background. | `battle_idle.v2.png` promoted to final |
| 张角 | `assets/heroes/zhangjiao/battle_attack.v1.png` | 94 | No | Normal attack action was clear, but the staff extended nearly to the canvas edge and created board-cell/crop risk. | Re-generated with a shorter diagonal staff strike close to the body. | Rejected v1 |
| 张角 | `assets/heroes/zhangjiao/battle_attack.png` | 98 | Yes | Diagonal staff still creates a wide silhouette, but margins are balanced and safe. | Removed chroma-key to alpha. Compact normal staff command strike, no lightning/projectile/aura/floating charms/slash trail/text/UI/background. | `battle_attack.v2.png` promoted to final |
| 张角 | generated Battle Skill v1 | 92 | No | Pose direction was useful, but the generated source came back on a black background instead of a clean chroma-key background, making transparency extraction unsafe. | Re-generated with strict magenta chroma-key background. | Rejected v1 |
| 张角 | `assets/heroes/zhangjiao/battle_skill.png` | 98 | Yes | Staff-raised silhouette is tall, but it has safe top/right margins and remains character-only. | Removed magenta chroma-key to alpha. Stronger ritual command preparation pose, no actual thunder, aura, magic circle, floating charms, smoke, fire, text, UI, or background. | `battle_skill.v2.png` promoted to final |

## 2026-07-02 Sun Shangxiang Plan

Sun Shangxiang action language draft:
- Body type: agile Eastern Wu princess archer; compact Q-version body, spirited and noble, lighter and faster than Huang Zhong.
- Historical identity: 孙尚香 / 弓腰姬; confident young adult heroine, practical ponytail, red and teal Wu light armor, gold trim, modest battle robe.
- Weapon: `weapon_wu_twin_crescent_bows_master.png` only; compact twin red lacquer recurve bows with gold fittings and teal grips, never crossbow, gun, western elf bow, or Huang Zhong's heavy longbow.
- FX separation: Sun Shangxiang may imply rapid combo shots through pose, but hero and battle sprites must never contain flying arrows, arrow trails, arrow rain, glow, smoke, fire, magic circles, or projectile FX.
- Hero Master: spirited presentation stance, facing right, twin bows visible but compact.
- Battle Idle: stable agile ready stance, one bow close to body, no release.
- Battle Attack: quick bow draw/release normal attack, no flying projectile.
- Battle Skill: stronger combo preparation pose, character-only, no arrow rain or trails.

## 2026-07-02 Sun Shangxiang Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 孙尚香 | `assets/heroes/sunshangxiang/hero_master.v1.png` | 94 | No | Art quality was strong, but the two bows spread too wide and the right bow dominated the silhouette; outfit also read closer to showcase card art than board-ready hero art. | Re-generated with more practical armor, compact bow placement, and tighter silhouette. | Rejected v1 |
| 孙尚香 | `assets/heroes/sunshangxiang/hero_master.png` | 98 | Yes | Legs remain partially visible due to agile archer outfit, but the design is modest enough for a practical battle robe and the silhouette is compact. | Removed chroma-key to alpha. Eastern Wu princess archer identity is clear, Q-version proportion passes, twin bows are visible but contained, no projectile/FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| 孙尚香 | generated Battle Idle v1 | 92 | No | The generated source used a non-uniform green background, making transparency extraction unreliable. | Re-generated with strict magenta chroma-key background. | Rejected v1 |
| 孙尚香 | `assets/heroes/sunshangxiang/battle_idle.png` | 98 | Yes | Twin bows remain visible, but bbox is compact and board margins are safe. | Removed magenta chroma-key to alpha. Stable agile ready stance, no release/projectile/arrow trail/FX/text/UI/background. | `battle_idle.v2.png` promoted to final |
| 孙尚香 | `assets/heroes/sunshangxiang/battle_attack.png` | 98 | Yes | Nocked arrow is visible as part of the bow-draw pose; no arrow has left the bow. | Removed magenta chroma-key to alpha. Quick normal bow attack pose, distinct from Huang Zhong's heavy sniper language, no flying arrow, arrow trail, glow, smoke, fire, magic circle, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| 孙尚香 | `assets/heroes/sunshangxiang/battle_skill.png` | 98 | Yes | Nocked arrow and second bow are visible, but no projectile or arrow-rain FX appears. | Removed magenta chroma-key to alpha. Stronger combo preparation pose, compact enough for board use, no flying arrow, arrow trail, arrow rain, glow, smoke, fire, magic circle, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Yellow Turban Plan

Yellow Turban soldier action language draft:
- Body type: low-rank summon/militia unit; compact Q-version body, brave but not commander-level, less ornate than all named heroes.
- Historical identity: Yellow Turban peasant rebel; yellow headscarf, tan/ochre cloth armor, leather belt and bracers, simple boots.
- Weapon: `weapon_yellow_turban_short_spear_master.png` only; short dark-wood militia spear with small iron leaf head and yellow cloth tie, never Zhao Yun/Ma Chao hero spear, guandao, halberd, axe, or sword.
- FX separation: no flags, banners, smoke, dust, spear trails, glows, debris, or magic effects. This summon should stay character-only.
- Hero Master: compact presentation stance, facing right, short spear close to body.
- Battle Idle: stable guard-ready stance, spear close, no attack motion.
- Battle Attack: short spear jab, normal attack only, no trail.
- Battle Skill: slightly stronger braced charge/guard preparation pose, character-only and still low-rank.

## 2026-07-02 Yellow Turban Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 黄巾兵 | `assets/heroes/yellow_turban/hero_master.v1.png` | 94 | No | Art quality was good, but the spear was held too horizontally and the spearhead had only 36px right padding, creating crop and board-width risk; the pose also felt too hero-like for a summon. | Re-generated with the spear held close/vertical and reduced symbolic decoration. | Rejected v1 |
| 黄巾兵 | `assets/heroes/yellow_turban/hero_master.png` | 98 | Yes | Low-rank cloth edges are intentionally rough, but the image stays clean and commercial. | Removed chroma-key to alpha. Basic Yellow Turban summon identity is clear, compact Q-version proportion passes, short spear stays close to body, no FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| 黄巾兵 | `assets/heroes/yellow_turban/battle_idle.png` | 98 | Yes | Small yin-yang badge remains as faction identity, but it does not overpower the low-rank soldier read. | Removed chroma-key to alpha. Stable guard-ready board pose, spear vertical/close, no attack/skill FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| 黄巾兵 | `assets/heroes/yellow_turban/battle_attack.v1.png` | 94 | No | The normal attack was readable, but the spear extended almost to the right canvas edge and the silhouette became too wide for board use. | Re-generated with a shorter diagonal jab and safer margins. | Rejected v1 |
| 黄巾兵 | `assets/heroes/yellow_turban/battle_attack.png` | 98 | Yes | Spear is still long enough to read clearly, but right padding and bbox are safe. | Removed chroma-key to alpha. Simple grounded spear jab, no jump, no trail, no smoke/fire/glow/debris/text/UI/background. | `battle_attack.v2.png` promoted to final |
| 黄巾兵 | `assets/heroes/yellow_turban/battle_skill.png` | 98 | Yes | Pose has stronger pressure than idle/attack, but remains low-rank and character-only. | Removed chroma-key to alpha. Braced spear preparation pose, no magic/hero FX, no spear trail, no flags, no dust, no text/UI/background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Guo Jia Plan

Guo Jia action language draft:
- Body type: Wei sickly genius strategist; compact Q-version body, refined and frail, less sinister than Sima Yi and less formal than Xun Yu.
- Historical identity: 郭嘉 / 奉孝; pale refined face, tired sharp eyes, slight faint smile, dark blue/white/silver Wei scholar robes, simple official hairpiece.
- Weapon: `weapon_fengxiao_bamboo_scroll_master.png` only; blank bamboo strategy scroll with Wei-blue cord and wine gourd charm, never fan, staff, sword, spear, spellbook, or crystal.
- FX separation: Guo Jia may imply heavy debuff strategy through posture, but hero and battle sprites must never contain written strategy glyphs, smoke, mist, glows, ghost effects, magic circles, floating symbols, or projectiles.
- Hero Master: refined presentation stance, facing right, scroll/gourd visible, no FX.
- Battle Idle: calm command-ready stance, scroll close to body, no casting effect.
- Battle Attack: subtle point or scroll flick, normal attack only.
- Battle Skill: stronger strategy-command preparation pose, scroll open/raised, character-only.

## 2026-07-02 Guo Jia Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 郭嘉 | `assets/heroes/guojia/hero_master.v1.png` | 94 | No | Art quality and identity were strong, but the body proportion was too long and close to 4 heads, violating the Art Bible 2.5-3 heads Q-version standard. | Re-generated with stricter Q-version proportions and reduced warrior armor. | Rejected v1 |
| 郭嘉 | `assets/heroes/guojia/hero_master.png` | 98 | Yes | Small low-threshold green edge residue appeared in the alpha audit, but no strict opaque green remained. | Removed chroma-key to alpha. Compact Q-version Wei strategist identity is clear, scroll/gourd prop is visible, no fan, no readable text, no FX/UI/background. | `hero_master.v2.png` promoted to final |
| 郭嘉 | `assets/heroes/guojia/battle_idle.png` | 98 | Yes | Bottom margin is usable but a little tighter than ideal. | Removed chroma-key to alpha. Calm board-ready thinking pose, scroll close to body, no attack/skill FX, no text/UI/background. | `battle_idle.v1.png` promoted to final |
| 郭嘉 | `assets/heroes/guojia/battle_attack.png` | 98 | Yes | Forward pointing arm widens the silhouette, but margins are safe. | Removed chroma-key to alpha. Subtle normal command attack, no glyphs, no projectile, no glow/smoke/mist, no text/UI/background. | `battle_attack.v1.png` promoted to final |
| 郭嘉 | `assets/heroes/guojia/battle_skill.png` | 98 | Yes | Skill pose has a larger open-scroll footprint, but bbox and margins are safe. | Removed chroma-key to alpha. Stronger debuff-strategy preparation pose, character-only frame, no written scroll text, no floating symbols, smoke, mist, glow, magic circle, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Dian Wei Plan

Dian Wei action language draft:
- Body type: Wei heavy bodyguard tank; compact Q-version body, broad shoulders, low center of gravity, shorter and denser than Zhang Fei.
- Historical identity: 典韦 / 古之恶来; stern square face, thick brows, short beard or stubble, loyal guard pressure, no Shu red-green styling.
- Weapon: `weapon_dianwei_twin_ji_master.png`; twin short heavy iron ji, dark iron, bronze rings, Wei-blue wraps, never spear, guandao, fangtian halberd, giant axe, or European polearm.
- FX separation: Dian Wei may imply rage and guard pressure through pose only; sprites must never contain slash trails, impact bursts, smoke, dust, aura, glow, ground cracks, or projectiles.
- Hero Master: powerful low stance, twin ji visible, facing right, card-ready silhouette.
- Battle Idle: defensive ready pose, weapons close to body for board footprint.
- Battle Attack: short close-range heavy strike, no jump and no trail.
- Battle Skill: guarded rage / protect-and-counter preparation pose, character-only.

## 2026-07-02 Dian Wei Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 典韦 Weapon | `assets/weapons/weapon_dianwei_twin_ji_master.png` | 98 | Yes | The silhouette leans slightly toward heavy hammer-ji, but the paired short iron ji identity is clear and not confused with guandao or fangtian halberd. | Removed chroma-key to alpha. Twin short heavy iron ji, Wei-blue wraps, dark iron and bronze details, no text/FX/UI/background. | `weapon_dianwei_twin_ji_master.v1.png` promoted to final |
| 典韦 | `assets/heroes/dianwei/hero_master.source.v1.png` | 94 | No | Strong armor and identity, but the body proportion was too realistic/tall for the Art Bible 2.5-3 heads Q-version standard. | Re-generated with stricter compact Q-version proportions and heavier guard silhouette. | Rejected v1 |
| 典韦 | `assets/heroes/dianwei/hero_master.png` | 98 | Yes | The twin ji makes the card silhouette wide, but padding is safe for HeroCard use. | Removed chroma-key to alpha. Wei heavy tank identity is distinct from Zhang Fei, compact Q-version proportion passes, no FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| 典韦 | `assets/heroes/dianwei/battle_idle.png` | 98 | Yes | Twin ji are still visually broad, but the board footprint is reduced versus Hero Master. | Removed chroma-key to alpha. Defensive idle pose, weapons held close, no attack/skill FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| 典韦 | `assets/heroes/dianwei/battle_attack.png` | 98 | Yes | Forward weapon extension creates a wider attack bbox and right margin is usable but not generous. | Removed chroma-key to alpha. Short grounded normal strike, no jump, no slash trail, no glow/smoke/fire/dust/text/UI/background. | `battle_attack.v1.png` promoted to final |
| 典韦 | `assets/heroes/dianwei/battle_skill.source.v1.png` | 90 | No | The action language was usable, but the generated background was black instead of flat chroma key, making transparency validation fail. | Re-generated with strict pure #00ff00 chroma-key background. | Rejected v1 |
| 典韦 | `assets/heroes/dianwei/battle_skill.png` | 98 | Yes | The rage pose is broad, but bbox margins are safe and no FX are embedded. | Removed chroma-key to alpha. Guarded rage preparation pose, character-only, no aura, smoke, glow, slash, dust, ground crack, text, UI, or background. | `battle_skill.v2.png` promoted to final |

## 2026-07-02 Xun Yu Plan

Xun Yu action language draft:
- Body type: Wei elegant support strategist; compact Q-version scholar-official, calmer and more orderly than Guo Jia, brighter and less sinister than Sima Yi.
- Historical identity: 荀彧 / 王佐之才; refined official crown, gentle authoritative eyes, navy/ivory Wei robes, clean courtly silhouette.
- Weapon: `weapon_xunyu_jade_hu_master.png`; blank jade court tablet with Wei-blue tassel, never fan, bamboo scroll, staff, sword, spear, spellbook, or crystal.
- FX separation: Xun Yu may imply aid/support through posture, but sprites must never contain healing light, symbols, magic circles, written text, particles, smoke, glow, or aura.
- Hero Master: composed court strategist presentation, jade tablet visible, facing right.
- Battle Idle: calm ready stance, prop close to body.
- Battle Attack: restrained order-giving normal attack, no projectile or spell.
- Battle Skill: formal support-strategy gesture, character-only.

## 2026-07-02 Xun Yu Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 荀彧 Weapon | `assets/weapons/weapon_xunyu_jade_hu_master.png` | 98 | Yes | Ornamentation is slightly rich, but the prop remains a blank jade hu and is distinct from fan/scroll/staff weapons. | Removed chroma-key to alpha. Pale jade, Wei-blue tassel, muted gold fittings, no readable writing, symbols, FX, text, UI, or background. | `weapon_xunyu_jade_hu_master.v1.png` promoted to final |
| 荀彧 | `assets/heroes/xunyu/hero_master.v1.png` | 94 | No | Identity and robe design were strong, but the body and crown pushed the figure too tall for the Art Bible Q-version standard. | Re-generated with stricter compact 2.5-3 head proportions and a smaller official crown. | Rejected v1 |
| 荀彧 | `assets/heroes/xunyu/hero_master.png` | 98 | Yes | Robe volume is ornate, but the silhouette remains compact and readable. | Removed chroma-key to alpha. Wei court strategist identity is clear, jade tablet is blank, no fan/scroll confusion, no FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| 荀彧 | `assets/heroes/xunyu/battle_idle.png` | 98 | Yes | Tall official crown still increases vertical footprint slightly, but margins are safe. | Removed chroma-key to alpha. Calm idle pose, jade tablet close to body, no spell/attack FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| 荀彧 | `assets/heroes/xunyu/battle_attack.png` | 98 | Yes | Pointing arm widens the pose, but board margins remain safe. | Removed chroma-key to alpha. Restrained normal command attack, no projectile, no glow, no magic circle, no written text/UI/background. | `battle_attack.v1.png` promoted to final |
| 荀彧 | `assets/heroes/xunyu/battle_skill.png` | 98 | Yes | Skill pose is ceremonial but intentionally effect-free. | Removed chroma-key to alpha. Support-strategy preparation gesture, character-only, no healing light, aura, particles, symbols, smoke, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Dong Zhuo Plan

Dong Zhuo action language draft:
- Body type: Qun tyrant tank; very broad, heavy, low center of gravity, rich and oppressive, not a generic bandit or demon.
- Historical identity: 董卓 / 暴相; black-red and dark purple tyrant armor-robes, bronze-gold ornaments, heavy beard, arrogant cruel expression.
- Weapon: `weapon_dongzhuo_golden_mace_master.png`; tyrant golden melon mace, short heavy ceremonial blunt weapon, never fangtian halberd, spear, guandao, sword, axe, or European fantasy hammer.
- FX separation: Dong Zhuo may imply greed, self-recovery, and tyranny through posture only; sprites must never contain fire, blood, smoke, aura, shockwave, coins, food props, ground cracks, or particles.
- Hero Master: domineering card pose with mace visible, facing right.
- Battle Idle: compact oppressive ready stance, mace upright close to body.
- Battle Attack: short close-range heavy mace strike, no jump and no impact effect.
- Battle Skill: tyrant feast / self-recovery / intimidation preparation pose, character-only.

## 2026-07-02 Dong Zhuo Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 董卓 Weapon | `assets/weapons/weapon_dongzhuo_golden_mace_master.png` | 98 | Yes | The gold ornamentation is strong, but it supports the tyrant-prime-minister read and remains distinct from Lu Bu's fangtian halberd. | Removed chroma-key to alpha. Short heavy golden melon mace, black-red grip, no text, blood, smoke, fire, FX, UI, or background. | `weapon_dongzhuo_golden_mace_master.v1.png` promoted to final |
| 董卓 | `assets/heroes/dongzhuo/hero_master.png` | 98 | Yes | Horizontal card silhouette is wide because of body, cape, and mace, but padding is safe for HeroCard use. | Removed chroma-key to alpha. Qun tyrant identity is clear, Q-version body passes, mace matches Weapon Master, no FX/text/UI/background. | `hero_master.v1.png` promoted to final |
| 董卓 | `assets/heroes/dongzhuo/battle_idle.png` | 98 | Yes | Large tank body keeps the footprint broad, but the mace is upright and margins are safe. | Removed chroma-key to alpha. Oppressive idle pose, weapon close to body, no attack/skill FX, no fire/blood/smoke/text/UI/background. | `battle_idle.v1.png` promoted to final |
| 董卓 | `assets/heroes/dongzhuo/battle_attack.source.v1.png` | 94 | No | Character identity was correct, but the mace extended too far toward the canvas edge and made the board footprint unsafe. | Re-generated with a compact close-range press strike and more side padding. | Rejected v1 |
| 董卓 | `assets/heroes/dongzhuo/battle_attack.png` | 98 | Yes | Mace remains visually large, but bbox margins are safe and the pose reads as a normal close-range strike. | Removed chroma-key to alpha. Grounded normal mace attack, no jump, impact burst, shockwave, fire, blood, dust, ground crack, text, UI, or background. | `battle_attack.v2.png` promoted to final |
| 董卓 | `assets/heroes/dongzhuo/battle_skill.png` | 98 | Yes | Raised hand is slightly exaggerated, but not malformed and the board footprint is safe. | Removed chroma-key to alpha. Tyrant feast/self-recovery preparation pose, character-only, no aura, fire, smoke, blood, coins, food props, particles, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Diaochan Plan

Diaochan action language draft:
- Body type: Qun charm mage; graceful compact Q-version dancer, elegant and strategic, never modern idol or sexualized fantasy.
- Historical identity: 貂蝉 / 离间; Han-style court dancer hair ornaments, modest layered crimson/ivory robes, intelligent calm smile.
- Weapon: `weapon_diaochan_moon_bell_silk_master.png`; moon bell dance silk with crescent jade bells and short ribbons, never fan, staff, sword, spear, whip, or magic wand.
- FX separation: Diaochan may imply charm through pose and prop only; sprites must never contain hearts, petals, glow, aura, magic circles, floating symbols, smoke, stage background, or particles.
- Hero Master: graceful card pose with moon bell silk visible, facing right.
- Battle Idle: compact ready dance stance, silk close to body.
- Battle Attack: light close-range bell-silk flick, no projectile or effect.
- Battle Skill: composed Lijian/charm preparation gesture, character-only.

## 2026-07-02 Diaochan Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 貂蝉 Weapon | `assets/weapons/weapon_diaochan_moon_bell_silk_master.png` | 98 | Yes | Ribbon silhouette is broad, so battle sprites must keep it closer to the body. | Removed chroma-key to alpha. Crescent jade bells and short silk ribbons read as a charm-control dance prop, no fan/staff/weapon confusion, no text, petals, glow, hearts, FX, UI, or background. | `weapon_diaochan_moon_bell_silk_master.v1.png` promoted to final |
| 貂蝉 | `assets/heroes/diaochan/hero_master.png` | 98 | Yes | The card pose is sweet and ribbon-rich, but remains Q-version guofeng and not modern/sexualized. | Removed chroma-key to alpha. Diaochan identity is clear, modest court dancer costume, moon bell silk visible, no FX/text/UI/background. | `hero_master.v1.png` promoted to final |
| 貂蝉 | `assets/heroes/diaochan/battle_idle.source.v1.png` | 94 | No | The pose was attractive but too close to a showcase Hero Master; ribbons spread too widely for board idle use. | Re-generated with quiet ready stance and silk held close to the body. | Rejected v1 |
| 貂蝉 | `assets/heroes/diaochan/battle_idle.png` | 98 | Yes | Very compact footprint sacrifices some ribbon drama, but improves board readability. | Removed chroma-key to alpha. Calm ready dance stance, moon bell silk close to body, no attack/skill FX, no petals/hearts/glow/text/UI/background. | `battle_idle.v2.png` promoted to final |
| 貂蝉 | `assets/heroes/diaochan/battle_attack.png` | 98 | Yes | Ribbon arc is wider than idle, but margins remain safe and it reads as a normal flick. | Removed chroma-key to alpha. Light close-range bell-silk attack, no projectile, glow, petals, hearts, magic circle, smoke, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| 貂蝉 | `assets/heroes/diaochan/battle_skill.png` | 98 | Yes | Left sleeve opens the silhouette slightly, but bbox is safe and no charm FX are embedded. | Removed chroma-key to alpha. Lijian/charm preparation pose, character-only, no hearts, petals, aura, glow, magic circle, particles, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Hua Xiong Plan

Hua Xiong action language draft:
- Body type: Qun epic frontline warrior; tall-stocky and intimidating, but not Dong Zhuo's ruler silhouette.
- Historical identity: Sishui Pass fierce general under Dong Zhuo; rough square face, thick brows, short black beard, black-red dark iron armor with tiger-tooth bronze ornaments.
- Weapon: `weapon_huaxiong_tigertooth_heavy_dao.png`; short-handled tiger-tooth heavy dao, never guandao, spear, fangtian halberd, axe, or giant sword.
- FX separation: Hua Xiong may imply execution pressure through pose only; sprites must never contain blood, slash trails, fire, smoke, aura, ground cracks, debris, shockwaves, or particles.
- Hero Master: aggressive card presentation, heavy dao visible, facing right.
- Battle Idle: grounded ready stance, weapon close to body for board footprint.
- Battle Attack: grounded heavy normal chop/cleave, no jump and no slash trail.
- Battle Skill: execute-style heavy chop preparation, character-only and no FX.

## 2026-07-02 Hua Xiong Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Hua Xiong Weapon | `assets/weapons/weapon_huaxiong_tigertooth_heavy_dao.source.v1.png` | 90 | No | Weapon silhouette was on direction, but the generated background was black instead of a removable chroma-key background. | Re-generated with strict pure green chroma-key background. | Rejected v1 |
| Hua Xiong Weapon | `assets/weapons/weapon_huaxiong_tigertooth_heavy_dao.png` | 98 | Yes | The blade is highly ornate, but the short-handled tiger-tooth heavy dao identity is clear and distinct from guandao, spear, halberd, and axe. | Removed chroma-key to alpha. No text, UI, FX, blood, smoke, fire, slash trail, or background. | `weapon_huaxiong_tigertooth_heavy_dao.v2.png` promoted to final |
| Hua Xiong | `assets/heroes/huaxiong/hero_master.png` | 98 | Yes | Broad card silhouette from armor and dao, but margins are safe and identity is distinct from Zhao Yun, Guan Yu, Lu Bu, and Dong Zhuo. | Removed chroma-key to alpha. Qun Sishui warrior read is strong, heavy dao matches Weapon Master, no FX/text/UI/background. | `hero_master.v1.png` promoted to final |
| Hua Xiong | `assets/heroes/huaxiong/battle_idle.png` | 98 | Yes | The body is bulky, so board display should rely on existing cell-relative scaling, but the weapon is held close and margins are safe. | Removed chroma-key to alpha. Stable idle pose, no attack/skill FX, no smoke/fire/glow/text/UI/background. | `battle_idle.v1.png` promoted to final |
| Hua Xiong | `assets/heroes/huaxiong/battle_attack.source.v1.rejected_black_bg.png` | 90 | No | Attack pose direction was usable, but the background was black and could not be cleanly removed around the dark armor and cloak. | Re-generated with strict pure green chroma-key background and no FX. | Rejected v1 |
| Hua Xiong | `assets/heroes/huaxiong/battle_attack.png` | 98 | Yes | The crouched chop pose is compact and grounded; no embedded slash or impact effect. | Removed chroma-key to alpha. Heavy normal attack frame, character-only, no jump, slash trail, glow, smoke, fire, blood, dust, text, UI, or background. | `battle_attack.v2.png` promoted to final |
| Hua Xiong | `assets/heroes/huaxiong/battle_skill.png` | 98 | Yes | Blade top margin is tighter than ideal, but there is no crop and it remains usable after Godot scaling. | Removed chroma-key to alpha. Execute-style skill preparation pose, character-only, no aura, slash trail, fire, smoke, ground crack, debris, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Gongsun Zan Plan

Gongsun Zan action language draft:
- Body type: Qun epic white-horse cavalry archer; compact agile commander, proud and clean, not an old heavy archer or spear cavalry hero.
- Historical identity: 公孙瓒 / 白马义从; white-blue cavalry armor, pale fur collar, white horsehair plume, northern frontier cavalry discipline.
- Weapon: `weapon_gongsunzan_white_horse_bow.png`; compact white cavalry bow as primary, short cavalry spear marker only secondary, never dominant spear, Huang Zhong heavy bow, Sun Shangxiang twin bows, crossbow, firearm, or mounted horse asset.
- FX separation: Gongsun Zan may imply cavalry speed and extra hit through posture only; sprites must never contain horse, dust, arrow trail, arrow rain, glow, smoke, aura, or projectiles.
- Hero Master: white-horse cavalry commander presentation stance, bow close to body, facing right.
- Battle Idle: compact ready stance, bow held close, cloak contained.
- Battle Attack: grounded bow draw, arrow nocked but not flying.
- Battle Skill: white-horse command/extra-hit preparation pose, character-only.

## 2026-07-02 Gongsun Zan Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| 公孙瓒 Weapon | `assets/weapons/weapon_gongsunzan_white_horse_bow.source.v1.png` | 94 | No | The white-horse cavalry style was strong, but the secondary spear read too long and risked making him a spear hero. | Re-generated with bow dominant and the short cavalry spear reduced to a secondary marker. | Rejected v1 |
| 公孙瓒 Weapon | `assets/weapons/weapon_gongsunzan_white_horse_bow.png` | 98 | Yes | Vertical footprint is tall due to bow and tassel, but side margins are safe and the archer identity is correct. | Removed chroma-key to alpha. White cavalry bow is primary, short spear marker is secondary, no horse, arrow trail, text, FX, UI, or background. | `weapon_gongsunzan_white_horse_bow.v2.png` promoted to final |
| 公孙瓒 | `assets/heroes/gongsunzan/hero_master.v1.png` | 94 | No | The image looked like an attack frame with a fully drawn bow, used a non-square canvas, and had tight side margins. | Re-generated as a square Hero Master presentation stance with bow held close and not drawn. | Rejected v1 |
| 公孙瓒 | `assets/heroes/gongsunzan/hero_master.png` | 98 | Yes | White plume and bow give a broad silhouette, but margins are safe and HeroCard identity is strong. | Removed chroma-key to alpha. White-horse cavalry archer identity is clear, Q-version proportion passes, bow is primary, no horse/projectile/FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| 公孙瓒 | `assets/heroes/gongsunzan/battle_idle.source.v1.png` | 94 | No | The pose was too close to Hero Master and the bow/cape footprint remained too wide for board idle. | Re-generated with bow tucked close to the body and a narrower cloak. | Rejected v1 |
| 公孙瓒 | `assets/heroes/gongsunzan/battle_idle.png` | 98 | Yes | White plume remains tall, but board footprint is compact and readable. | Removed chroma-key to alpha. Ready stance, bow close to body, no drawn arrow, horse, dust, smoke, glow, text, UI, or background. | `battle_idle.v2.png` promoted to final |
| 公孙瓒 | `assets/heroes/gongsunzan/battle_attack.png` | 98 | Yes | Bow draw widens the pose compared with idle, but margins remain safe. | Removed chroma-key to alpha. Grounded normal bow attack, arrow nocked but not flying, no projectile trail, dust, smoke, glow, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| 公孙瓒 | `assets/heroes/gongsunzan/battle_skill.png` | 98 | Yes | Command pose is taller because the short spear marker is raised, but margins and alpha are safe. | Removed chroma-key to alpha. White-horse command preparation pose, character-only, no horse, arrow rain, dust, aura, smoke, projectile, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Guan Ping Plan

Guan Ping action language draft:
- Body type: Shu epic young warrior; compact Q-version, lighter and younger than Guan Yu, more disciplined than a generic recruit.
- Historical identity: Guan-family second-generation general; youthful face, no long beard, green-gold Shu armor, loyal and steady expression.
- Weapon: `weapon_guanping_qinglin_yanyue_dao_master.png`; compact Qinglin Yanyue Dao, a lighter inherited Guan-family polearm, never Guan Yu's huge Qinglong Yanyue Dao, spear, halberd, axe, or giant sword.
- FX separation: Guan Ping may imply oath and blade discipline through pose only; sprites must never contain blue dragon spirit, slash trails, glow, smoke, fire, blood, ground cracks, debris, or particles.
- Hero Master: young Guan-family presentation stance, facing right, compact yanyue dao visible.
- Battle Idle: grounded ready stance, weapon held close for board footprint.
- Battle Attack: grounded trained blade cut, lighter and quicker than Guan Yu, no jump and no slash trail.
- Battle Skill: Guan-family oath / heavy blade preparation pose, character-only and no FX.

## 2026-07-02 Guan Ping Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Guan Ping Weapon | `assets/weapons/weapon_guanping_qinglin_yanyue_dao_master.png` | 98 | Yes | Dragon-head fitting is ornate, but the weapon remains a compact light yanyue dao and does not read as Guan Yu's oversized Qinglong blade. | Removed chroma-key to alpha. No character, text, UI, FX, smoke, fire, glow, slash trail, blood, or background. | `weapon_guanping_qinglin_yanyue_dao_master.source.v1.png` promoted to final |
| Guan Ping | `assets/heroes/guanping/hero_master.source.v1.rejected_too_tall.png` | 94 | No | Character identity was usable, but body proportion was too realistic and tall for the Art Bible 2.5-3 heads Q-version standard. | Re-generated with strict compact Q-version proportions and shorter body/legs. | Rejected v1 |
| Guan Ping | `assets/heroes/guanping/hero_master.png` | 98 | Yes | Dao head is visually rich, but the young Guan-family identity is clear and distinct from Guan Yu. | Removed chroma-key to alpha. Compact Q-version proportion passes, no long beard, no FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| Guan Ping | `assets/heroes/guanping/battle_idle.png` | 98 | Yes | Polearm head remains prominent, but board footprint is compact and margins are safe. | Removed chroma-key to alpha. Disciplined idle pose, weapon held close, no attack/skill FX, text, UI, or background. | `battle_idle.v1.png` promoted to final |
| Guan Ping | `assets/heroes/guanping/battle_attack.png` | 98 | Yes | Horizontal attack footprint is wider than idle, but right margin remains safe. | Removed chroma-key to alpha. Grounded normal blade cut, no jump, slash trail, glow, smoke, fire, blood, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| Guan Ping | `assets/heroes/guanping/battle_skill.png` | 98 | Yes | Raised weapon makes the pose tall, but top/bottom margins are safe and no FX are embedded. | Removed chroma-key to alpha. Guan-family oath/heavy blade preparation pose, character-only, no blue dragon spirit, aura, slash, smoke, fire, debris, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Zhang Bao Plan

Zhang Bao action language draft:
- Body type: Shu epic young warrior; compact Q-version, more agile and youthful than Zhang Fei but still visibly Zhang-family fierce.
- Historical identity: Zhang Fei's son; red-black tiger-striped armor, sharp youthful face, wild hair/headband, no huge beard or old face.
- Weapon: `weapon_zhangbao_tigerfang_snake_spear_master.png`; Tiger-Fang Short Snake Spear, a shorter and faster Zhang-family spear, never Zhang Fei's huge Zhangba Snake Spear, guandao, fangtian halberd, axe, or sword.
- FX separation: Zhang Bao may imply roar and ferocity through pose only; sprites must never contain aura, shockwave, fire, smoke, slash trails, lightning, ground cracks, debris, blood, or particles.
- Hero Master: fierce young presentation stance, facing right, short snake spear visible.
- Battle Idle: low ready stance, spear held close for board footprint.
- Battle Attack: compact grounded thrust/short sweep, no jump and no effect.
- Battle Skill: Zhang-family roar / heavy spear preparation pose, character-only and no FX.

## 2026-07-02 Zhang Bao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Zhang Bao Weapon | `assets/weapons/weapon_zhangbao_tigerfang_snake_spear_master.png` | 98 | Yes | Spear head is ornate, but it reads as a compact snake spear and not as guandao, halberd, axe, or Zhang Fei's oversized spear. | Removed chroma-key to alpha. No character, text, UI, FX, smoke, fire, glow, slash trail, blood, or background. | `weapon_zhangbao_tigerfang_snake_spear_master.source.v1.png` promoted to final |
| Zhang Bao | `assets/heroes/zhangbao/hero_master.source.v1.rejected_too_tall.png` | 94 | No | Identity direction was usable, but the figure was too tall and realistic for the Art Bible 2.5-3 heads Q-version rule. | Re-generated with stricter compact Q-version proportions. | Rejected v1 |
| Zhang Bao | `assets/heroes/zhangbao/hero_master.png` | 98 | Yes | Spear is wide in the card pose, but margins are safe and the young Zhang-family identity is distinct from Zhang Fei. | Removed chroma-key to alpha. Compact Q-version proportion passes, no huge beard, no FX/text/UI/background. | `hero_master.v2.png` promoted to final |
| Zhang Bao | `assets/heroes/zhangbao/battle_idle.png` | 98 | Yes | Horizontal spear stance is broad, but bbox margins are safe and it reads as idle rather than attack. | Removed chroma-key to alpha. Low ready stance, weapon held close enough for board scaling, no FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| Zhang Bao | `assets/heroes/zhangbao/battle_attack.rejected_v1_tight_right_margin.png` | 94 | No | Attack direction was good, but spear tip left only 42px right margin and risked crop/board-footprint issues. | Re-generated with diagonal compact thrust and wider side padding. | Rejected v1 |
| Zhang Bao | `assets/heroes/zhangbao/battle_attack.png` | 98 | Yes | Pose is aggressive but compact, and side margins are safe. | Removed chroma-key to alpha. Grounded normal thrust, no jump, slash trail, glow, smoke, fire, blood, text, UI, or background. | `battle_attack.v2.png` promoted to final |
| Zhang Bao | `assets/heroes/zhangbao/battle_skill.png` | 98 | Yes | Spear tip top margin is tight, but not cropped and acceptable for Godot scaling. | Removed chroma-key to alpha. Roar/heavy spear preparation pose, character-only, no aura, shockwave, fire, smoke, lightning, debris, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Mi Furen Plan

Mi Furen action language draft:
- Body type: Shu epic support mage; compact adult Q-version, dignified and resilient, never modern idol or childlike.
- Historical identity: protective noble lady adapted into Wanguxingtu; ivory-green and Shu teal robes, jade hairpin, calm brave expression.
- Weapon/prop: `weapon_mifuren_jade_sachet_master.png`; jade pendant and silk sachet support focus, never sword, spear, fan, staff, bow, or dagger.
- FX separation: Mi Furen may imply protection through pose only; sprites must never contain healing light, petals, particles, aura, magic circles, floating symbols, smoke, fire, or glow.
- Hero Master: graceful but compact support presentation pose, facing right, jade sachet visible.
- Battle Idle: calm ready stance, prop close to body.
- Battle Attack: restrained sleeve/focus command strike, no projectile or effect.
- Battle Skill: guardian/protective oath preparation pose, character-only and no FX.

## 2026-07-02 Mi Furen Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Mi Furen Weapon | `assets/weapons/weapon_mifuren_jade_sachet_master.png` | 98 | Yes | Tall tassel footprint, but margins are safe and it reads as a support focus rather than a weapon. | Removed chroma-key to alpha. Jade pendant and silk sachet, no readable text, UI, FX, glow, petals, smoke, fire, or background. | `weapon_mifuren_jade_sachet_master.source.v1.png` promoted to final |
| Mi Furen | `assets/heroes/mifuren/hero_master.source.v1.rejected_too_tall.png` | 94 | No | Direction and dignity were good, but body proportion was too tall and realistic for the Art Bible Q-version rule. | Re-generated with stricter compact Q-version proportions. | Rejected v1 |
| Mi Furen | `assets/heroes/mifuren/hero_master.rejected_v2_too_tall.png` | 96 | No | Visual quality was high, but the figure remained closer to promotional illustration proportion and the robe silhouette was too long. | Re-generated with stricter game-card compactness. | Rejected v2 |
| Mi Furen | `assets/heroes/mifuren/hero_master.source.v3.rejected_too_childlike.png` | 95 | No | Proportion improved, but the face and skirt read too cute/childlike for Mi Furen's dignified adult identity. | Re-generated with adult expression and modest robe constraints. | Rejected v3 |
| Mi Furen | `assets/heroes/mifuren/hero_master.source.v4.rejected_too_tall.png` | 96 | No | Adult dignity improved, but body proportion drifted back toward long-form illustration. | Re-generated with explicit head-to-body ratio constraints. | Rejected v4 |
| Mi Furen | `assets/heroes/mifuren/hero_master.png` | 98 | Yes | Eyes remain soft, but the final reads as adult dignified Q-version support and not modern/sexualized. | Removed chroma-key to alpha. Compact support silhouette, jade sachet visible, no FX/text/UI/background. | `hero_master.v5.png` promoted to final |
| Mi Furen | `assets/heroes/mifuren/battle_idle.png` | 98 | Yes | Source background had green variation, but alpha cleanup removed it with no green residue. | Removed chroma-key to alpha. Calm ready stance, prop close, no spell/healing FX/text/UI/background. | `battle_idle.v1.png` promoted to final |
| Mi Furen | `assets/heroes/mifuren/battle_attack.png` | 98 | Yes | Sleeve footprint is wider than idle, but bbox margins are safe. | Removed chroma-key to alpha. Restrained command strike, no projectile, glow, healing light, magic circle, petals, text, UI, or background. | `battle_attack.v1.png` promoted to final |
| Mi Furen | `assets/heroes/mifuren/battle_skill.png` | 98 | Yes | Sleeve and robe volume are broad, but board margins remain safe and no FX are embedded. | Removed chroma-key to alpha. Guardian/protective oath preparation pose, character-only, no aura, healing light, petals, particles, symbols, text, UI, or background. | `battle_skill.v1.png` promoted to final |

## 2026-07-02 Ma Dai Plan

Ma Dai action language draft:
- Body type: Shu epic Xiliang frontier warrior; compact Q-version, calmer and darker than Ma Chao, not a white-fur cavalry prince.
- Historical identity: Ma Chao's kinsman and ambush-minded frontier deputy; dark teal/blackened iron armor, muted bronze, short asymmetrical cloak, teal horsehair plume.
- Weapon: `weapon_madai_frontier_hook_spear_master.png`; frontier hook-spear / hooked lance, never Ma Chao's golden tiger-head spear, guandao, fangtian halberd, axe, sword, or bow.
- FX separation: Ma Dai may imply ambush and control through pose only; sprites must never contain dust, horse, smoke, slash trails, spear trails, aura, lightning, ground cracks, debris, or particles.
- Hero Master: tactical frontier presentation stance, facing right, hook-spear visible.
- Battle Idle: calm ready stance, spear held close for board footprint.
- Battle Attack: compact grounded hook-spear thrust / short sweep, no charge trail.
- Battle Skill: ambush command / hook control preparation pose, character-only and no FX.

## 2026-07-02 Ma Dai Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Ma Dai Weapon | `assets/weapons/weapon_madai_frontier_hook_spear_master.png` | 98 | Yes | Small hanging charm has abstract geometry, but no readable writing and the hooked spear identity is clear. | Removed chroma-key to alpha. Distinct from Ma Chao's golden tiger spear; no text, UI, FX, smoke, fire, trail, blood, or background. | `weapon_madai_frontier_hook_spear_master.source.v1.png` promoted to final |
| Ma Dai | `assets/heroes/madai/hero_master.png` | 98 | Yes | Weapon tassel broadens the card silhouette, but margins are safe and Ma Dai reads distinct from Ma Chao. | Removed chroma-key to alpha. Frontier teal/black armor and hook-spear pass identity checks, no FX/text/UI/background. | `hero_master.v1.png` promoted to final |
| Ma Dai | `assets/heroes/madai/battle_idle.png` | 98 | Yes | Cloak footprint is broad, but spear is held close and margins are safe. | Removed chroma-key to alpha. Calm idle stance, no attack/skill FX, no horse, dust, text, UI, or background. | `battle_idle.v1.png` promoted to final |
| Ma Dai | `assets/heroes/madai/battle_attack.rejected_v1_tight_right_margin.png` | 94 | No | Normal attack action was good, but spear tip left only 26px right margin and risked crop/board-footprint issues. | Re-generated with compact diagonal thrust and wider side padding. | Rejected v1 |
| Ma Dai | `assets/heroes/madai/battle_attack.png` | 98 | Yes | Pose is low and wide, but bbox margins are safe and it reads as normal attack rather than skill. | Removed chroma-key to alpha. Compact grounded thrust, no charge trail, smoke, dust, glow, text, UI, or background. | `battle_attack.v2.png` promoted to final |
| Ma Dai | `assets/heroes/madai/battle_skill.rejected_v1_tight_right_margin.png` | 94 | No | Skill pose direction was usable, but hook-spear extended too close to the right canvas edge. | Re-generated with a steeper, body-close weapon angle. | Rejected v1 |
| Ma Dai | `assets/heroes/madai/battle_skill.png` | 98 | Yes | Vertical weapon makes the pose tall, but margins remain safe. | Removed chroma-key to alpha. Ambush command/hook-control preparation pose, character-only, no smoke, dust, horse, aura, spear trail, text, UI, or background. | `battle_skill.v2.png` promoted to final |

## 2026-07-02 Xu Chu Plan

Xu Chu action language draft:
- Body type: Wei legendary tank; broad, round, low-center-of-gravity Q-version brute, distinct from Dian Wei's wilder bodyguard silhouette and Dong Zhuo's tyrant bulk.
- Historical identity: Cao Cao's Tiger Guard / "Tiger Fool"; dark Wei navy armor, blackened iron, muted bronze, tiger-mask shoulders, short beard/stubble, fierce loyal expression.
- Weapon: `weapon_xuchu_tiger_iron_hammer_master.png`; massive short-handled tiger-head iron hammer / heavy mace, never Dong Zhuo's golden mace, axe, spear, halberd, sword, guandao, or bow.
- FX separation: Xu Chu may imply force through posture only; sprites must never contain shockwaves, dust, ground cracks, smoke, glow, sparks, fire, lightning, debris, blood, or aura.
- Hero Master: heavy presentation stance, facing right, tiger-head hammer visible.
- Battle Idle: planted guardian ready pose, hammer held close for board footprint.
- Battle Attack: compact grounded hammer smash, no jump and no effect.
- Battle Skill: Tiger Guard intimidation / heavy hammer preparation pose, character-only and no FX.

## 2026-07-02 Xu Chu Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Xu Chu Weapon | `assets/weapons/weapon_xuchu_tiger_iron_hammer_master.png` | 98 | Yes | Small hanging ornament adds detail, but there is no readable text and the tiger-head hammer identity is clear. | Removed chroma-key to alpha. Distinct from Dong Zhuo's golden mace; no character, text, UI, FX, smoke, fire, glow, slash trail, blood, or background. | `weapon_xuchu_tiger_iron_hammer_master.source.v1.png` promoted to final |
| Xu Chu | `assets/heroes/xuchu/hero_master.rejected_v1_checker_background.png` | 90 | No | Character direction was promising, but the source was RGB with a baked checker-style background instead of transparent or removable chroma-key. | Re-generated with explicit solid #00ff00 chroma-key canvas requirement. | Rejected v1 |
| Xu Chu | `assets/heroes/xuchu/hero_master.png` | 98 | Yes | The pose is broad, but it supports Xu Chu's tank identity and margins are safe after alpha cleanup. | Removed chroma-key to alpha. Low-center Wei Tiger Guard silhouette, tiger-head hammer visible, no FX/text/UI/background. | `hero_master.source.v2.png` promoted to final |
| Xu Chu | `assets/heroes/xuchu/battle_idle.png` | 98 | Yes | Wide weapon/cape silhouette, but it reads as a planted idle and Godot scales battle sprites to board cells. | Removed chroma-key to alpha. Guardian ready stance, hammer held close enough, no attack/skill FX, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Xu Chu | `assets/heroes/xuchu/battle_attack.rejected_v1_tight_right_margin.png` | 94 | No | Normal attack action was usable, but the hammer left only 9px right margin and risked crop/board-footprint issues. | Re-generated with a compact close-range downward smash and wider side padding. | Rejected v1 |
| Xu Chu | `assets/heroes/xuchu/battle_attack.png` | 98 | Yes | Pose is compressed and heavy, with safe margins and clear normal-attack language. | Removed chroma-key to alpha. Grounded hammer smash, no jump, impact burst, dust, ground crack, glow, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Xu Chu | `assets/heroes/xuchu/battle_skill.png` | 98 | Yes | Raised hammer makes the pose tall, but top/side margins remain safe and it is distinct from the normal attack. | Removed chroma-key to alpha. Tiger Guard intimidation / heavy hammer preparation pose, character-only, no aura, shockwave, smoke, dust, debris, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-02 Zhen Ji Plan

Zhen Ji action language draft:
- Body type: Wei legendary mage; compact adult Q-version noblewoman, calm and cool, never modern idol, seductive beauty, childlike girl, or Diao Chan/Xiao Qiao recolor.
- Historical identity: Luoshen-inspired Wei noble mage; moon-white and soft Wei-blue robes, dark navy sash, pale jade/silver ornaments, high hair bun, melancholic intelligent expression.
- Weapon/prop: `weapon_zhenji_luoshen_jade_ribbon_master.png`; Luoshen jade ring and blue-white silk ribbon focus, never sword, spear, fan, staff, bow, pipa, or real water effect.
- FX separation: Zhen Ji may imply water/poetry through motif and posture only; sprites must never contain water streams, petals, glow, aura, magic circles, smoke, lightning, particles, or projectiles.
- Hero Master: elegant compact presentation stance, facing right, jade ribbon focus visible, modest closed-collar robe.
- Battle Idle: calm poised ready stance, sleeves/ribbons close to body.
- Battle Attack: short precise mage command gesture, no projectile or effect.
- Battle Skill: Luoshen command / elegant hand-seal preparation pose, character-only and no FX.

## 2026-07-02 Zhen Ji Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Zhen Ji Weapon | `assets/weapons/weapon_zhenji_luoshen_jade_ribbon_master.png` | 98 | Yes | Silk ribbons create many soft alpha edges, but green residue is clean and the Luoshen focus identity is clear. | Removed chroma-key to alpha. Jade ring and ribbon focus, no character, text, UI, water stream, petals, glow, aura, or background. | `weapon_zhenji_luoshen_jade_ribbon_master.source.v1.png` promoted to final |
| Zhen Ji | `assets/heroes/zhenji/hero_master.rejected_v1_too_tall_promotional.png` | 94 | No | Beautiful direction, but proportion and robe silhouette read too much like a tall promotional illustration rather than compact Art Bible Q-version. | Re-generated with stricter 2.5-3 heads compact body and HeroCard-readability constraints. | Rejected v1 |
| Zhen Ji | `assets/heroes/zhenji/hero_master.rejected_v2_exposed_neckline.png` | 96 | No | Q proportion improved, but the neckline still drifted toward generic beauty-card styling instead of the requested modest closed-collar robe. | Re-generated with explicit closed high crossed collar and pibo covering chest. | Rejected v2 |
| Zhen Ji | `assets/heroes/zhenji/hero_master.png` | 98 | Yes | Ornament/ribbon detail is rich, but it supports Zhen Ji's identity and remains clean for HeroCard use. | Removed chroma-key to alpha. Compact adult Luoshen mage, closed-collar robe, no FX/text/UI/background. | `hero_master.source.v3.png` promoted to final |
| Zhen Ji | `assets/heroes/zhenji/battle_idle.rejected_v1_exposed_neckline.png` | 96 | No | Pose and silhouette were usable, but the neckline repeated the v2 identity issue and failed the modest robe direction. | Re-generated after final Hero Master v3 direction was locked. | Rejected v1 |
| Zhen Ji | `assets/heroes/zhenji/battle_idle.png` | 98 | Yes | Tall hair ornament and ribbon add height, but bbox margins are safe and board scaling keeps footprint controlled. | Removed chroma-key to alpha. Calm ready stance, ribbons close to body, no attack/skill FX, water, petals, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Zhen Ji | `assets/heroes/zhenji/battle_attack.png` | 98 | Yes | Left ribbon extends the silhouette, but side margins are safe and it reads as a basic command gesture. | Removed chroma-key to alpha. Short mage attack command, no projectile, water stream, glow, petals, text, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Zhen Ji | `assets/heroes/zhenji/battle_skill.png` | 98 | Yes | Skill pose is visually close to idle in elegance, but the hand seal and ring placement distinguish it from normal attack. | Removed chroma-key to alpha. Luoshen command preparation pose, character-only, no water, aura, glow, magic circle, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-02 Cao Ren Plan

Cao Ren action language draft:
- Body type: Wei epic/legendary-style tank; disciplined, upright, stocky fortress general, distinct from Xu Chu's brute mass, Dian Wei's wild bodyguard shape, Cao Cao's ruler silhouette, and Zhang Liao's cavalry officer silhouette.
- Historical identity: Wei defensive commander / fortress guardian; dark navy lamellar armor, blackened iron plates, muted bronze trim, short blue plume, trimmed beard, stern calm expression.
- Weapon/prop: `weapon_caoren_fortress_tower_shield_master.png`; heavy Wei fortress tower shield, never huge hammer, spear, guandao, bow, European knight shield, or sci-fi barrier.
- FX separation: Cao Ren may imply defense through posture and shield motif only; sprites must never contain shield barriers, glow, dust, sparks, ground cracks, smoke, aura, or floating symbols.
- Hero Master: grounded defensive presentation stance, facing right, tower shield visible.
- Battle Idle: planted guard, shield forward but close.
- Battle Attack: compact grounded shield bash, no impact FX.
- Battle Skill: fortress defense command / bracing stance, character-only and no barrier FX.

## 2026-07-02 Cao Ren Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Cao Ren Weapon | `assets/weapons/weapon_caoren_fortress_tower_shield_master.png` | 98 | Yes | Tiger/fortress ornament is strong, but the tower-shield identity is clear and not confused with Xu Chu's hammer or a European shield. | Removed chroma-key to alpha. Fortress gate motif, no character, text, UI, shield barrier, glow, smoke, fire, sparks, or background. | `weapon_caoren_fortress_tower_shield_master.source.v1.png` promoted to final |
| Cao Ren | `assets/heroes/caoren/hero_master.png` | 98 | Yes | Shield is large, but it is the intended core silhouette and margins are safe for HeroCard use. | Removed chroma-key to alpha. Disciplined Wei fortress general, distinct from Xu Chu/Dian Wei/Cao Cao, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Cao Ren | `assets/heroes/caoren/battle_idle.png` | 98 | Yes | Horizontal footprint is broad due to shield and cape, but bbox margins are safe and stance reads as defensive idle. | Removed chroma-key to alpha. Planted guard pose, shield close, no barrier, smoke, sparks, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Cao Ren | `assets/heroes/caoren/battle_attack.png` | 98 | Yes | Shield takes much of the silhouette, but side margins are safe and the pose reads as basic shield bash. | Removed chroma-key to alpha. Grounded normal attack, no impact burst, shield barrier, dust, glow, text, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Cao Ren | `assets/heroes/caoren/battle_skill.png` | 98 | Yes | Skill pose is large and commanding, but remains within safe margins and contains no barrier FX. | Removed chroma-key to alpha. Fortress defense command stance, character-only, no aura, shield barrier, ground crack, smoke, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Cao Pi Plan

Cao Pi action language draft:
- Body type: Wei epic/legendary-style duelist-mage; compact young adult male ruler, refined and cold, distinct from Cao Cao's older emperor silhouette, Sima Yi's sorcerer shape, Xun Yu's pure scholar identity, and Zhang Liao's cavalry officer posture.
- Historical identity: Wei Wen Emperor / literary strategist; dark navy and moon-white imperial scholar armor-robes, pale jade ornaments, small young emperor crown, sharp eyebrows, calm cold expression.
- Weapon: `weapon_caopi_jade_command_sword_master.png`; refined jade command sword / imperial command blade, never Cao Cao's Yitian sword, huge broadsword, spear, guandao, fan, staff, bow, or readable edict text.
- FX separation: Cao Pi may imply judgment and imperial command through posture only; sprites must never contain sword glow, slash trails, floating papers, aura, magic circles, lightning, smoke, or particles.
- Hero Master: elegant grounded presentation stance, facing right, jade command sword visible.
- Battle Idle: calm imperial ready stance, sword close to body.
- Battle Attack: compact grounded draw-cut / command sword slash, no sword trail.
- Battle Skill: imperial judgment command pose, sword upright and command hand extended, character-only and no FX.

## 2026-07-03 Cao Pi Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Cao Pi Weapon | `assets/weapons/weapon_caopi_jade_command_sword_master.rejected_v1_black_background.png` | 90 | No | Weapon direction was usable, but the source had a black background instead of transparent/removable green-screen background. | Re-generated with explicit full-canvas #00ff00 chroma-key requirement. | Rejected v1 |
| Cao Pi Weapon | `assets/weapons/weapon_caopi_jade_command_sword_master.rejected_v2_too_long.png` | 95 | No | Green-screen requirement passed, but the blade length drifted toward a normal long sword and too close to Cao Cao's command-sword space. | Re-generated as a more compact jade command sword /佩剑. | Rejected v2 |
| Cao Pi Weapon | `assets/weapons/weapon_caopi_jade_command_sword_master.png` | 98 | Yes | Slightly longer than an ideal short sword, but it reads as a refined imperial command blade and is distinct from Cao Cao's Yitian sword. | Removed chroma-key to alpha. No character, text, UI, sword glow, slash trail, smoke, fire, sparks, or background. | `weapon_caopi_jade_command_sword_master.source.v3.png` promoted to final |
| Cao Pi | `assets/heroes/caopi/hero_master.png` | 98 | Yes | Cloak and crown make the silhouette tall, but the body remains Q-version and the young emperor identity is clear. | Removed chroma-key to alpha. Distinct from Cao Cao/Sima Yi/Xun Yu, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Cao Pi | `assets/heroes/caopi/battle_idle.png` | 98 | Yes | Tall crown adds height, but width is compact and suitable for board scaling. | Removed chroma-key to alpha. Calm imperial ready stance, sword held close, no attack/skill FX, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Cao Pi | `assets/heroes/caopi/battle_attack.rejected_v1_too_feminine.png` | 94 | No | Attack action was usable, but the face and hair drifted too feminine and risked confusion with female mage silhouettes. | Re-generated with explicit male young-emperor facial structure and short swept hair. | Rejected v1 |
| Cao Pi | `assets/heroes/caopi/battle_attack.png` | 98 | Yes | Sword projects forward, but side margins are safe and no trail/FX is embedded. | Removed chroma-key to alpha. Grounded basic draw-cut, masculine Cao Pi identity restored, no sword glow, slash trail, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Cao Pi | `assets/heroes/caopi/battle_skill.png` | 98 | Yes | Sword is vertical and raises the silhouette, but top margin is safe and pose reads as command skill prep. | Removed chroma-key to alpha. Imperial judgment stance, character-only, no floating papers, aura, magic circle, sword glow, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Le Jin Plan

Le Jin action language draft:
- Body type: Wei epic compact vanguard; short, lean, wiry, fast infantry assault fighter, distinct from Zhang Liao's cavalry officer posture, Dian Wei/Xu Chu brute silhouettes, and Ma Chao's cavalry-prince shape.
- Historical identity: first-to-scale / breakthrough warrior; Wei dark navy lightweight lamellar armor, blackened iron, muted bronze trim, red-blue scarf, headband/compact helmet, focused fierce expression.
- Weapon: `weapon_lejin_vanguard_short_ji_master.png`; compact short ji / assault halberd, never long spear, Fangtian huaji, Dian Wei twin ji, guandao, axe, bow, or sword-only identity.
- FX separation: Le Jin may imply speed through low posture and tension only; sprites must never contain dash trails, motion trails, smoke, dust, slash trails, sparks, aura, or impact effects.
- Hero Master: compact card presentation stance, facing right, short ji visible and close.
- Battle Idle: crouched alert ready stance, weapon diagonal and close.
- Battle Attack: close-range short-ji stab / tight side cut, no trail.
- Battle Skill: first-to-scale breakthrough preparation pose, character-only and no dash FX.

## 2026-07-03 Le Jin Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Le Jin Weapon | `assets/weapons/weapon_lejin_vanguard_short_ji_master.png` | 98 | Yes | Crescent blade is readable and compact, with no confusion against Lu Bu's fangtian halberd or Dian Wei's twin ji. | Removed chroma-key to alpha. Short assault ji, no character, text, UI, glow, smoke, fire, slash trail, or background. | `weapon_lejin_vanguard_short_ji_master.source.v1.png` promoted to final |
| Le Jin | `assets/heroes/lejin/hero_master.rejected_v1_attack_pose_long_weapon.png` | 94 | No | Character direction was usable, but pose read like an attack frame and weapon stretched toward a long spear identity. | Re-generated as a card-presentation stance with weapon closer to body. | Rejected v1 |
| Le Jin | `assets/heroes/lejin/hero_master.png` | 98 | Yes | Weapon adds horizontal energy, but margins are safe and the vanguard identity is clear. | Removed chroma-key to alpha. Compact adult Wei assault warrior, distinct from Zhang Liao/Ma Chao/Dian Wei, no FX/text/UI/background. | `hero_master.source.v2.png` promoted to final |
| Le Jin | `assets/heroes/lejin/battle_idle.png` | 98 | Yes | Low stance is horizontally broad, but it suits the alert vanguard role and margins are safe. | Removed chroma-key to alpha. Crouched ready pose, no attack/skill FX, trail, smoke, dust, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Le Jin | `assets/heroes/lejin/battle_attack.rejected_v1_weapon_too_long.png` | 94 | No | Pose looked strong, but the weapon spanned too much of the canvas and drifted toward long-spear identity. | Re-generated with a closer short-ji attack. | Rejected v1 |
| Le Jin | `assets/heroes/lejin/battle_attack.rejected_v2_still_too_long.png` | 96 | No | Improved, but the weapon still read too long for Le Jin's compact short-ji language. | Re-generated with explicit short-handled ji length constraint. | Rejected v2 |
| Le Jin | `assets/heroes/lejin/battle_attack.png` | 98 | Yes | Short ji still projects forward, but bbox width and side margins are safe and it no longer reads as a long spear. | Removed chroma-key to alpha. Close-range basic attack, no trail, glow, smoke, dust, text, UI, or background. | `battle_attack.source.v3.png` promoted to final |
| Le Jin | `assets/heroes/lejin/battle_skill.png` | 98 | Yes | Skill pose is low and tense, but distinct from attack and contains no dash FX. | Removed chroma-key to alpha. First-to-scale breakthrough preparation pose, character-only, no dash trail, dust, slash trail, aura, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Xiahou Dun Plan

Xiahou Dun action language draft:
- Body type: Wei epic veteran warrior; compact, broad, mature, one-eyed commander, distinct from Zhao Yun's agile spear hero, Zhang Liao's cavalry officer, Cao Ren's shield tank, Dian Wei/Xu Chu brute silhouettes, and Le Jin's lean vanguard.
- Historical identity: fierce Wei old guard; black eyepatch or scarred closed eye without gore, thick eyebrows, short beard/stubble, dark navy and black Wei armor, bronze-gold trim, red-blue cloth accents.
- Weapon: `weapon_xiahoudun_crescent_war_saber_master.png`; heavy one-handed crescent war saber / thick-backed dao, never guandao, spear, halberd, axe, Green Dragon Crescent Blade, or European fantasy sword.
- FX separation: Xiahou Dun may imply iron will and rage through posture and expression only; sprites must never contain slash trails, aura, flame, smoke, lightning, particles, blood, dust, ground cracks, or skill circles.
- Hero Master: rugged presentation stance, facing right, one-eyed identity and saber visible.
- Battle Idle: grounded ready stance, saber low-forward, board footprint controlled by Godot scaling.
- Battle Attack: grounded heavy saber chop, no jump and no attack FX.
- Battle Skill: iron-willed commander oath / war-cry pose, character-only and no FX.

## 2026-07-03 Xiahou Dun Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Xiahou Dun Weapon | `assets/weapons/weapon_xiahoudun_crescent_war_saber_master.png` | 99 | Yes | Blade is large and ornate, but the short handle and thick-backed dao silhouette clearly distinguish it from Guan Yu's guandao and polearms. | Removed chroma-key to alpha. Heavy Wei crescent saber, no character, text, UI, slash trail, glow, smoke, fire, lightning, blood, or background. | `weapon_xiahoudun_crescent_war_saber_master.source.v1.png` promoted to final |
| Xiahou Dun | `assets/heroes/xiahoudun/hero_master.png` | 99 | Yes | Wide cape and saber create a large HeroCard silhouette, but the one-eyed veteran identity is very clear and margins are safe. | Removed chroma-key to alpha. Mature Wei commander, black eyepatch, heavy dao visible, distinct from Zhao Yun and other Wei warriors, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Xiahou Dun | `assets/heroes/xiahoudun/battle_idle.png` | 98 | Yes | Saber extends horizontally, but this is acceptable because HeroBattleSprite scales board units to grid cells. | Removed chroma-key to alpha. Grounded ready stance, character-only, no attack/skill FX, trail, smoke, dust, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Xiahou Dun | `assets/heroes/xiahoudun/battle_attack.png` | 98 | Yes | Normal attack silhouette is broad, but it reads as a grounded heavy chop and does not include embedded slash FX. | Removed chroma-key to alpha. Basic saber attack, no jump, slash trail, impact burst, smoke, dust, text, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Xiahou Dun | `assets/heroes/xiahoudun/battle_skill.png` | 98 | Yes | Raised saber makes the pose tall, but margins remain safe and the war-cry/command pose is distinct from normal attack. | Removed chroma-key to alpha. Iron-willed commander skill preparation pose, character-only, no aura, glow, skill circle, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Gan Ning Plan

Gan Ning action language draft:
- Body type: Wu epic assassin; lean, athletic, loud, agile river-raider commander, distinct from Zhou Yu/Lu Xun scholar silhouettes, Sun Shangxiang's archer identity, Le Jin's Wei vanguard, and Ma Chao/Ma Dai cavalry shapes.
- Historical identity: Jinfan pirate turned Wu assault general; mischievous fierce grin, red scarf, dark teal/crimson naval light armor, brocade sash, many small bronze bells.
- Weapon: `weapon_ganning_jinfan_twin_ring_sabers_master.png`; matched twin short ring-pommel sabers with bells and red brocade ribbons, never single long sword, spear, bow, guandao, katana, axe, or oversized fantasy weapon.
- FX separation: Gan Ning may imply speed and river-raider energy through posture, ribbons, and bells only; sprites must never contain water splashes, waves, slash trails, aura, smoke, flame, lightning, particles, blood, or dust.
- Hero Master: confident raider presentation pose, facing right, twin sabers and bells visible.
- Battle Idle: low agile ready stance, both sabers close enough for board footprint.
- Battle Attack: grounded close-range twin-saber cross cut, no jump and no slash FX.
- Battle Skill: Jinfan raid command / ambush preparation pose, character-only and no water/skill FX.

## 2026-07-03 Gan Ning Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Gan Ning Weapon | `assets/weapons/weapon_ganning_jinfan_twin_ring_sabers_master.png` | 99 | Yes | Pair silhouette is broad, but it strongly communicates twin short blades, bells, and brocade ribbons. | Removed chroma-key to alpha. Distinct from long swords, guandao, spear, bow, and existing Wu weapons; no character, text, UI, water, slash trail, glow, smoke, or background. | `weapon_ganning_jinfan_twin_ring_sabers_master.source.v1.png` promoted to final |
| Gan Ning | `assets/heroes/ganning/hero_master.png` | 99 | Yes | Pose is energetic and wide, but it is appropriate for HeroCard use and the Jinfan identity is very clear. | Removed chroma-key to alpha. Adult Wu raider, twin sabers, bells, brocade sash, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Gan Ning | `assets/heroes/ganning/battle_idle.png` | 98 | Yes | Left saber extends outward, but margins are safe and the stance remains readable after board scaling. | Removed chroma-key to alpha. Low ready stance, character-only, no water splash, slash trail, smoke, dust, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Gan Ning | `assets/heroes/ganning/battle_attack.png` | 98 | Yes | Attack pose is compact enough, though the large sabers dominate the silhouette. | Removed chroma-key to alpha. Grounded basic twin-saber cross cut, no jump, slash trail, glow, water, impact burst, text, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Gan Ning | `assets/heroes/ganning/battle_skill.v1.png` | 94 | No | Strong pose, but the raised saber left only 26px top margin and created future crop/board-footprint risk. | Re-generated with compact saber placement and explicit top-padding requirement. | Rejected v1 |
| Gan Ning | `assets/heroes/ganning/battle_skill.png` | 98 | Yes | Second version is more compact; raised saber is safe, though the pose is less dramatic than v1. | Removed chroma-key to alpha. Jinfan raid command preparation pose, character-only, no water splash, wave, aura, glow, slash trail, text, UI, or background. | `battle_skill.source.v2.png` promoted to final |

## 2026-07-03 Sun Jian Plan

Sun Jian action language draft:
- Body type: Wu legendary warrior; mature, sturdy, commander-like Tiger of Jiangdong, distinct from Zhou Yu/Lu Xun scholar silhouettes, Sun Shangxiang's archer identity, Gan Ning's river-raider energy, and Cao Cao's emperor-ruler silhouette.
- Historical identity: Jiangdong founder and Sun clan patriarch; stern brave face, short dark beard, tiger motif armor, red/dark teal/bronze-gold Wu palette, lordly helmet/crown.
- Weapon: `weapon_sunjian_guding_dao_master.png`; Guding Dao / Ancient Anchor Saber, a single short-handled broad dao with tiger-head guard, never guandao, spear, bow, twin sabers, Guan Yu blade, or Xiahou Dun crescent saber.
- FX separation: Sun Jian may imply tiger-like command through armor, posture, and expression only; sprites must never contain slash trails, aura, smoke, flame, lightning, particles, blood, dust, or skill circles.
- Hero Master: mature founder-warrior presentation stance, facing right, Guding Dao visible.
- Battle Idle: compact grounded commander stance, blade close to body for board footprint.
- Battle Attack: grounded close-range Guding Dao chop, no jump and no slash FX.
- Battle Skill: Jiangdong Tiger rally / command preparation pose, character-only and no FX.

## 2026-07-03 Sun Jian Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Sun Jian Weapon | `assets/weapons/weapon_sunjian_guding_dao_master.png` | 99 | Yes | Large ornate blade, but the short handle, tiger-head guard, and red-gold Wu styling make it distinct from guandao and Xiahou Dun's saber. | Removed chroma-key to alpha. Guding Dao master, no character, text, UI, slash trail, glow, smoke, fire, lightning, blood, or background. | `weapon_sunjian_guding_dao_master.source.v1.png` promoted to final |
| Sun Jian | `assets/heroes/sunjian/hero_master.png` | 98 | Yes | HeroCard silhouette is wide because of cloak and blade, but it strongly communicates mature Jiangdong Tiger identity. | Removed chroma-key to alpha. Mature Wu founder warrior, tiger armor, Guding Dao, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Sun Jian | `assets/heroes/sunjian/battle_idle.rejected_v1_wide_cape.png` | 94 | No | Character style was good, but cape and blade created a too-wide board footprint. | Re-generated with tucked cloak and vertical/near-body Guding Dao placement. | Rejected v1 |
| Sun Jian | `assets/heroes/sunjian/battle_idle.png` | 98 | Yes | Vertical blade makes the pose tall, but side margins and board footprint are safe. | Removed chroma-key to alpha. Compact grounded idle, character-only, no attack/skill FX, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Sun Jian | `assets/heroes/sunjian/battle_attack.rejected_v1_too_wide.png` | 94 | No | Strong attack pose, but bbox width was 1100px due to cape and side-stretched blade, risking board overlap. | Re-generated as a compact close-range downward chop. | Rejected v1 |
| Sun Jian | `assets/heroes/sunjian/battle_attack.png` | 98 | Yes | Pose is less dramatic than v1, but it is much safer for board use and still reads as a heavy basic attack. | Removed chroma-key to alpha. Grounded Guding Dao chop, no jump, slash trail, impact burst, glow, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Sun Jian | `assets/heroes/sunjian/battle_skill.png` | 98 | Yes | Skill pose is close to idle in silhouette, but the blade-across-chest command posture distinguishes it from basic attack. | Removed chroma-key to alpha. Jiangdong Tiger rally preparation pose, character-only, no aura, glow, skill circle, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Lu Meng Plan

Lu Meng action language draft:
- Body type: Wu epic warrior-scholar; disciplined, compact, intelligent commander, distinct from Zhou Yu/Lu Xun pure scholar silhouettes, Gan Ning's pirate raider energy, Sun Jian's tiger-founder mass, and Zhang Liao's cavalry-officer aggression.
- Historical identity: 吴下阿蒙 to learned commander; calm intelligent eyes, trimmed goatee, teal/white/crimson armor-robes, light lamellar breastplate over scholar robe, red command sash, naval commander headpiece.
- Weapon: `weapon_lumeng_wu_command_saber_master.png`; compact Wu command saber with jade command-token ornament and red-teal tassel, never fan, scroll-only prop, spear, bow, guandao, twin sabers, Sun Jian's Guding Dao, or Xiahou Dun's heavy crescent saber.
- FX separation: Lu Meng may imply tactics through posture, command hand, and costume only; sprites must never contain text, floating scrolls, water splashes, aura, smoke, flame, lightning, slash trails, particles, blood, dust, or skill circles.
- Hero Master: warrior-scholar presentation stance, facing right, command saber visible.
- Battle Idle: compact disciplined commander stance, blade close and robe tucked.
- Battle Attack: grounded precise short saber cut, no jump and no slash FX.
- Battle Skill: tactical command preparation pose, free hand directing troops, character-only and no FX.

## 2026-07-03 Lu Meng Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Lu Meng Weapon | `assets/weapons/weapon_lumeng_wu_command_saber_master.rejected_v1_too_heavy_saber.png` | 94 | No | Clean alpha and good rendering, but the large curved blade read too much like a brute-force war saber and risked pushing Lu Meng away from warrior-scholar identity. | Re-generated as a shorter, straighter Wu officer command saber. | Rejected v1 |
| Lu Meng Weapon | `assets/weapons/weapon_lumeng_wu_command_saber_master.png` | 98 | Yes | Still a dao silhouette, but compact enough and the jade command token gives a clear strategist identity. | Removed chroma-key to alpha. Compact Wu command saber, no character, text, UI, slash trail, smoke, water splash, fire, glow, or background. | `weapon_lumeng_wu_command_saber_master.source.v2.png` promoted to final |
| Lu Meng | `assets/heroes/lumeng/hero_master.png` | 98 | Yes | HeroCard robe silhouette is broad, but it supports the儒将 identity and remains distinct from Zhou Yu/Lu Xun/Sun Jian/Gan Ning. | Removed chroma-key to alpha. Warrior-scholar commander, command saber visible, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Lu Meng | `assets/heroes/lumeng/battle_idle.png` | 98 | Yes | Headpiece and ribbons add height, but side margins are safe and the pose is idle, not attack. | Removed chroma-key to alpha. Compact disciplined stance, character-only, no attack/skill FX, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Lu Meng | `assets/heroes/lumeng/battle_attack.png` | 98 | Yes | Robe and ribbon add motion, but bbox is safe and action reads as a precise basic cut rather than a heavy Sun Jian-style chop. | Removed chroma-key to alpha. Grounded short saber attack, no jump, slash trail, glow, smoke, water, text, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Lu Meng | `assets/heroes/lumeng/battle_skill.png` | 98 | Yes | Extended command hand widens the pose, but margins remain safe and it reads clearly as tactical command preparation. | Removed chroma-key to alpha. Character-only command pose, no aura, glow, skill circle, floating scrolls, text, water splash, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Xiao Qiao Plan

Xiao Qiao action language draft:
- Body type: Wu epic support mage; elegant adult Q-style noblewoman, visually distinct from Sun Shangxiang's archer, Diaochan's dancer charm, Zhou Yu/Lu Xun scholar silhouettes, and martial Wu warriors.
- Historical identity: Jiangdong flower-moon beauty; coral pink, ivory, jade teal, and soft gold robes, closed collar, floral hair ornaments, refined but battle-readable stance.
- Weapon: `weapon_xiaoqiao_flower_moon_fan_master.png`; flower-moon round fan with compact handle, never sword, spear, bow, guandao, dancer ribbon, or free-floating magical prop.
- FX separation: Xiao Qiao may imply support magic through posture, hand shape, and fan direction only; sprites must never contain petals, aura, magic circle, glow, wind, smoke, lightning, water, particles, or text.
- Hero Master: elegant card/detail presentation stance, facing right, flower-moon fan visible.
- Battle Idle: compact calm ready stance, fan close enough for board footprint.
- Battle Attack: grounded fan-forward basic strike, no wind trail or petals.
- Battle Skill: gentle support command preparation pose, character-only and no FX.

## 2026-07-03 Xiao Qiao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Xiao Qiao Weapon | `assets/weapons/weapon_xiaoqiao_flower_moon_fan_master.png` | 98 | Yes | Fan is ornate and delicate, but the round flower-moon silhouette is clear and distinct from weapons used by martial heroes. | Removed chroma-key to alpha. Weapon-only asset, no character, text, UI, petals, glow, aura, smoke, or background. | `weapon_xiaoqiao_flower_moon_fan_master.source.v1.png` promoted to final |
| Xiao Qiao | `assets/heroes/xiaoqiao/hero_master.rejected_v1_tall_revealing.png` | 90 | No | Too tall/promotional and collar/chest exposure did not fit the conservative battle roster language. | Re-generated with closed collar, compact Q-style proportions, and less promotional fashion posing. | Rejected v1 |
| Xiao Qiao | `assets/heroes/xiaoqiao/hero_master.rejected_v2_too_childlike.png` | 94 | No | Costume improved, but face and proportions drifted too childlike for Xiao Qiao's adult historical identity. | Re-generated with adult noblewoman face and more mature posture while preserving Q-style. | Rejected v2 |
| Xiao Qiao | `assets/heroes/xiaoqiao/hero_master.rejected_v3_tall_promotional.png` | 95 | No | Adult feeling improved, but silhouette remained too tall and promotional for the established HeroCard set. | Re-generated with stronger chibi compression, closed collar, and compact fan presentation. | Rejected v3 |
| Xiao Qiao | `assets/heroes/xiaoqiao/hero_master.rejected_v4_exposed_childlike.png` | 96 | No | Stronger style match, but bare-shoulder/exposed reading and youthful face still fell short of Art Bible fit. | Re-generated with fully closed neckline, adult face, and restrained court-mage costume. | Rejected v4 |
| Xiao Qiao | `assets/heroes/xiaoqiao/hero_master.png` | 98 | Yes | Slightly slender compared with martial heroes, but the closed collar, fan, Wu palette, and adult flower-moon identity are clear. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background, fan visible and weapon-correct. | `hero_master.source.v5.png` promoted to final |
| Xiao Qiao | `assets/heroes/xiaoqiao/battle_idle.png` | 98 | Yes | Cute board proportions are strong, but pose is calm, readable, compact, and distinct from attack/skill. | Removed chroma-key to alpha. Idle fan stance, no petals, glow, magic circle, wind, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Xiao Qiao | `assets/heroes/xiaoqiao/battle_attack.png` | 98 | Yes | Fan projects forward, but bbox margins are safe and the pose reads as a grounded basic fan strike. | Removed chroma-key to alpha. No wind slash, petals, aura, impact burst, smoke, text, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Xiao Qiao | `assets/heroes/xiaoqiao/battle_skill.png` | 98 | Yes | Extended hand widens the pose slightly, but footprint remains safe and the action reads as support skill preparation. | Removed chroma-key to alpha. Character-only command pose, no petals, glow, aura, magic circle, wind, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Taishi Ci Plan

Taishi Ci action language draft:
- Body type: Wu epic archer; mature, stern, compact heroic build, distinct from Zhao Yun/Ma Chao white-armored cavalry heroes, Gan Ning's raider silhouette, and Sun Jian's founder-warrior mass.
- Historical identity: loyal and brave Wu marksman; strong eyebrows, short beard or stubble, red/deep teal Wu archer armor, quiver, practical commander headpiece.
- Weapon: `weapon_taishici_loyal_war_bow_master.png`; ornate Chinese loyalist war bow, never spear, halberd, sword-first pose, crossbow, gun, or glowing fantasy launcher.
- FX separation: Taishi Ci may imply precision through pose and bowstring tension only; sprites must never contain arrow trails, glowing arrows, target reticles, aura, smoke, dust, particles, flame, lightning, or text.
- Hero Master: compact archer presentation stance, facing right, bow and quiver visible.
- Battle Idle: grounded ready stance with bow close to body.
- Battle Attack: grounded physical bow attack with one plain arrow, no trail.
- Battle Skill: target-marking command pose, character-only and no target/VFX.

## 2026-07-03 Taishi Ci Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Taishi Ci Weapon | `assets/weapons/weapon_taishici_loyal_war_bow_master.png` | 99 | Yes | Tall diagonal bow, but margins are safe and it clearly reads as a restrained Wu war bow, not crossbow or sci-fi weapon. | Removed chroma-key to alpha. Weapon-only, no character, text, UI, arrow trail, glow, smoke, flame, lightning, particles, or background. | `weapon_taishici_loyal_war_bow_master.source.v1.png` promoted to final |
| Taishi Ci | `assets/heroes/taishici/hero_master.rejected_v1_too_tall_adult.png` | 95 | No | Good Wu archer identity, but proportions were too close to tall adult promotional art and not compressed enough for the established Q-style set. | Re-generated with explicit 2.5-3-head Q proportions, mature face retained, and bow closer to body. | Rejected v1 |
| Taishi Ci | `assets/heroes/taishici/hero_master.png` | 99 | Yes | Bow and quiver create a large silhouette, but the mature archer identity is excellent and distinct from cavalry/spear heroes. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background, bow and quiver visible. | `hero_master.source.v2.png` promoted to final |
| Taishi Ci | `assets/heroes/taishici/battle_idle.png` | 98 | Yes | Idle pose is close to Hero Master, but it is compact, readable, and safe for board scaling. | Removed chroma-key to alpha. Grounded archer ready stance, no arrow trail, glow, smoke, dust, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Taishi Ci | `assets/heroes/taishici/battle_attack.rejected_v1_wide_arrow_gradient.png` | 94 | No | Action was strong, but the arrow and bow stretched too wide and the chroma background contained visible gradients. | Re-generated as a compact 3/4 firing pose with arrow and bow well inside the canvas. | Rejected v1 |
| Taishi Ci | `assets/heroes/taishici/battle_attack.png` | 98 | Yes | Bow still dominates the pose, but bbox margins are safe and the plain arrow has no trail or glow. | Removed chroma-key to alpha. Grounded normal bow attack, no VFX/text/UI/background. | `battle_attack.source.v2.png` promoted to final |
| Taishi Ci | `assets/heroes/taishici/battle_skill.png` | 98 | Yes | Extended command hand widens the silhouette slightly, but it distinguishes skill prep from normal firing and remains within safe margins. | Removed chroma-key to alpha. Target-marking command pose, no target reticle, arrow glow, aura, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Huang Gai Plan

Huang Gai action language draft:
- Body type: Wu epic tank; old, broad, stocky veteran, grey beard, heavy armor, distinct from Sun Jian's lordly founder, Gan Ning's raider agility, and Lu Meng's warrior-scholar silhouette.
- Historical identity: stern loyal Wu old guard; red/deep teal heavy lamellar armor, bronze-gold trim, veteran headband, weathered face.
- Weapon: `weapon_huanggai_iron_war_whip_master.png`; heavy short-handled iron war whip / armored baton, never sword, spear, bow, axe, guandao, fire prop, or ship prop.
- FX separation: Huang Gai may imply bitter-ruse resolve through posture only; sprites must never contain fire, smoke, burning ships, explosions, sparks, dust, impact bursts, aura, particles, or text.
- Hero Master: old veteran tank presentation stance, facing right, iron war whip visible.
- Battle Idle: grounded defensive stance with weapon close.
- Battle Attack: compact physical blunt smash, no impact FX.
- Battle Skill: guard-oath / bitter-ruse resolve stance, character-only and no fire/smoke.

## 2026-07-03 Huang Gai Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Huang Gai Weapon | `assets/weapons/weapon_huanggai_iron_war_whip_master.png` | 98 | Yes | Chain ornaments widen the silhouette, but the main form clearly reads as a heavy iron war whip, not a flail-only weapon. | Removed chroma-key to alpha. Weapon-only, no fire, smoke, ship, text, UI, sparks, aura, or background. | `weapon_huanggai_iron_war_whip_master.source.v1.png` promoted to final |
| Huang Gai | `assets/heroes/huanggai/hero_master.png` | 99 | Yes | HeroCard silhouette is broad because of weapon and cloak, but this supports the tank identity and margins remain safe. | Removed chroma-key to alpha. Old Wu veteran tank, heavy armor, iron war whip, no fire/smoke/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Huang Gai | `assets/heroes/huanggai/battle_idle.png` | 98 | Yes | Weapon is large, but held close enough for board use and reads as defensive idle rather than attack. | Removed chroma-key to alpha. Grounded tank stance, no fire, smoke, dust, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Huang Gai | `assets/heroes/huanggai/battle_attack.rejected_v1_too_wide.png` | 94 | No | Strong physical attack, but bbox width was 1099px due to the horizontal weapon swing, risking neighbor-cell overlap. | Re-generated as a short-range downward smash with the weapon close to the torso. | Rejected v1 |
| Huang Gai | `assets/heroes/huanggai/battle_attack.png` | 98 | Yes | Still a large tank pose, but width is controlled and the strike reads as physical blunt damage with no embedded FX. | Removed chroma-key to alpha. No fire, smoke, dust, impact burst, motion trail, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Huang Gai | `assets/heroes/huanggai/battle_skill.png` | 98 | Yes | The vertical weapon dominates, but it sells the guard-oath stance and keeps the footprint controlled. | Removed chroma-key to alpha. Bitter-ruse resolve pose, no fire, smoke, burning ship, aura, sparks, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Zhou Tai Plan

Zhou Tai action language draft:
- Body type: Wu epic bodyguard tank; sturdy, scarred, silent protector, distinct from Sun Jian's lordly founder, Huang Gai's elderly veteran tank, Gan Ning's agile raider, and Lu Meng's warrior-scholar.
- Historical identity: loyal shield-for-the-lord bodyguard; cheek and arm scars allowed, but no blood or gore; red/deep teal Wu guard armor, bronze-gold trim, heavy shoulders, tied dark hair.
- Weapon: `weapon_zhoutai_guard_ring_saber_master.png`; heavy ring-pommel guard saber / thick-backed dao, never spear, halberd, bow, axe, guandao, fantasy greatsword, or magic weapon.
- FX separation: Zhou Tai may imply protection through stance and saber placement only; sprites must never contain energy shields, slash trails, glow, blood, smoke, dust, sparks, fire, lightning, particles, or text.
- Hero Master: scarred bodyguard presentation stance, facing right, saber visible and close.
- Battle Idle: grounded protective guard with saber across body.
- Battle Attack: compact guard countercut, no slash FX.
- Battle Skill: oath-bound guardian stance, saber upright, character-only and no shield/VFX.

## 2026-07-03 Zhou Tai Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Zhou Tai Weapon | `assets/weapons/weapon_zhoutai_guard_ring_saber_master.png` | 98 | Yes | Blade is large and ornate, but it remains a one-handed ring-pommel guard saber and does not drift into Guan Yu-style polearm identity. | Removed chroma-key to alpha. Weapon-only, no character, text, UI, slash trail, glow, blood, smoke, fire, or background. | `weapon_zhoutai_guard_ring_saber_master.source.v1.png` promoted to final |
| Zhou Tai | `assets/heroes/zhoutai/hero_master.png` | 99 | Yes | Saber creates a strong HeroCard silhouette, but the scarred bodyguard identity is clear and distinct from Sun Jian/Huang Gai/Gan Ning/Lu Meng. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background, no blood or gore. | `hero_master.source.v1.png` promoted to final |
| Zhou Tai | `assets/heroes/zhoutai/battle_idle.png` | 98 | Yes | Saber is prominent, but held close enough and reads as a defensive guard, not an attack swing. | Removed chroma-key to alpha. Grounded protective idle, no slash trail, blood, smoke, dust, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Zhou Tai | `assets/heroes/zhoutai/battle_attack.rejected_v1_too_wide.png` | 94 | No | Pose had energy, but the saber went too wide and risked neighbor-cell overlap. | Re-generated with a short-range downward/low guard countercut and stricter width limit. | Rejected v1 |
| Zhou Tai | `assets/heroes/zhoutai/battle_attack.png` | 98 | Yes | Blade remains broad, but bbox width is safe and the low countercut reads as physical melee without embedded FX. | Removed chroma-key to alpha. No slash trail, glow, blood, smoke, dust, impact burst, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Zhou Tai | `assets/heroes/zhoutai/battle_skill.rejected_v1_black_background.png` | 90 | No | Pose was usable, but the generated source had a black background instead of chroma-key green, making transparency unreliable. | Re-generated with explicit pure green background requirement. | Rejected v1 |
| Zhou Tai | `assets/heroes/zhoutai/battle_skill.rejected_v2_quiver_wrong_identity.png` | 92 | No | Strong guardian pose, but it added a quiver/archer identity, conflicting with Zhou Tai's melee bodyguard role. | Re-generated with strict ban on quiver, arrows, bows, and extra weapons. | Rejected v2 |
| Zhou Tai | `assets/heroes/zhoutai/battle_skill.png` | 98 | Yes | Top margin is tighter due to upright saber, but still safe; stance clearly differs from attack and contains no shield/VFX. | Removed chroma-key to alpha. Oath-bound guardian pose, no energy shield, aura, slash trail, blood, smoke, text, UI, or background. | `battle_skill.source.v3.png` promoted to final |

## 2026-07-03 Ling Tong Plan

Ling Tong action language draft:
- Body type: Wu epic assault warrior; young, agile, disciplined, distinct from Gan Ning's pirate raider, Zhou Tai's scarred bodyguard, Taishi Ci's archer, and Sun Jian's lordly founder.
- Historical identity: energetic Wu front-line officer; red/deep teal light armor, bronze-gold trim, red headband, no pirate bells, no archer gear, no elderly beard.
- Weapon: `weapon_lingtong_twin_guard_ji_master.png`; paired short Wu guard ji, never twin sabers, long spear, bow, quiver, axe, guandao, or gun.
- FX separation: Ling Tong may imply speed through compact posture only; sprites must never contain slash trails, glow, smoke, dust, sparks, fire, lightning, particles, or text.
- Hero Master: energetic presentation stance, facing right, twin short ji visible.
- Battle Idle: compact cross-guard stance with both ji close.
- Battle Attack: compact close-body twin-ji strike, no slash FX.
- Battle Skill: twin-ji charge preparation stance, weapons upright and close, character-only and no FX.

## 2026-07-03 Ling Tong Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Ling Tong Weapon | `assets/weapons/weapon_lingtong_twin_guard_ji_master.png` | 98 | Yes | Crossed pair is wide as a weapon master display, but the short-ji identity is clear and distinct from Gan Ning's twin sabers. | Removed chroma-key to alpha. Weapon-pair only, no character, text, UI, glow, slash trail, smoke, fire, or background. | `weapon_lingtong_twin_guard_ji_master.source.v1.png` promoted to final |
| Ling Tong | `assets/heroes/lingtong/hero_master.png` | 98 | Yes | HeroCard silhouette is wide due to twin weapons, but it strongly communicates Ling Tong's agile assault identity and remains distinct from Gan Ning/Zhou Tai/Taishi Ci. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Ling Tong | `assets/heroes/lingtong/battle_idle.rejected_v1_too_wide.png` | 94 | No | Character and weapons were correct, but the weapons spread too wide for board use. | Re-generated with both short ji crossed close to the torso. | Rejected v1 |
| Ling Tong | `assets/heroes/lingtong/battle_idle.png` | 99 | Yes | Very compact and readable; the pose is less dramatic, but ideal for board footprint. | Removed chroma-key to alpha. Cross-guard idle, no slash trail, glow, smoke, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Ling Tong | `assets/heroes/lingtong/battle_attack.rejected_v1_too_wide.png` | 94 | No | Strong action, but twin weapons spread too wide and risked neighbor-cell overlap. | Re-generated with stricter close-body weapon placement. | Rejected v1 |
| Ling Tong | `assets/heroes/lingtong/battle_attack.rejected_v2_still_too_wide.png` | 95 | No | Improved, but the forward weapon still extended too far for a safe board footprint. | Re-generated as a compact close-body downward cross strike. | Rejected v2 |
| Ling Tong | `assets/heroes/lingtong/battle_attack.png` | 98 | Yes | The attack is more contained than dramatic, but it reads as a short burst and keeps width safe. | Removed chroma-key to alpha. No slash trail, glow, dust, sparks, text, UI, or background. | `battle_attack.source.v3.png` promoted to final |
| Ling Tong | `assets/heroes/lingtong/battle_skill.png` | 98 | Yes | Upright weapons widen the upper silhouette slightly, but bbox remains safe and it reads as a charge-prep pose rather than attack. | Removed chroma-key to alpha. Twin-ji ready burst stance, no aura, glow, slash trail, smoke, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Lu Su Plan

Lu Su action language draft:
- Body type: Wu epic diplomat-strategist; warm, reliable, compact scholar-official, distinct from Zhou Yu/Lu Xun pure command mages, Zhuge Liang/Sima Yi fan strategists, Guo Jia scroll strategist, Xun Yu court-tablet minister, and Xiao Qiao support mage.
- Historical identity: Eastern Wu alliance and grain-support statesman; gentle mature face, short moustache and goatee, deep teal/crimson robes, bronze-gold official ornaments, river-wave and grain motifs.
- Prop: `weapon_lusu_alliance_jade_tablet_master.png`; blank jade alliance tablet plus bamboo grain-ledger scroll, never feather fan, sword, spear, bow, readable text, or floating magical scroll.
- FX separation: Lu Su may imply support through calm posture, tablet, and ledger only; sprites must never contain glow, aura, magic circle, flying scrolls, particles, smoke, fire, lightning, or text.
- Hero Master: compact diplomat-strategist presentation stance, facing right, tablet and ledger visible.
- Battle Idle: compact supportive ready pose with props close to body.
- Battle Attack: basic tablet-forward command strike, no projectile or glow.
- Battle Skill: alliance/support command preparation pose, character-only and no VFX.

## 2026-07-03 Lu Su Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Lu Su Prop | `assets/weapons/weapon_lusu_alliance_jade_tablet_master.png` | 98 | Yes | Fine tassels and jade edges create many semi-transparent pixels, but there is no visible green fringe and the blank tablet/ledger identity is clear. | Removed chroma-key to alpha. Prop-only, no character, text, fan, glow, smoke, fire, lightning, or background. | `weapon_lusu_alliance_jade_tablet_master.source.v1.png` promoted to final |
| Lu Su | `assets/heroes/lusu/hero_master.rejected_v1_tall_promotional.png` | 94 | No | Character identity and props were good, but proportions were too tall and promotional for the established Q-style Hero Master set. | Re-generated with explicit compact 2.5-3-head Q proportions and props close to body. | Rejected v1 |
| Lu Su | `assets/heroes/lusu/hero_master.png` | 98 | Yes | Source is portrait-format and slightly taller than martial Q heroes, but it matches Xiao Qiao-style Hero Master usage and the diplomat identity is distinct. | Removed chroma-key to alpha. Character-only Hero Master, no fan, readable text, FX, UI, or background. | `hero_master.source.v2.png` promoted to final |
| Lu Su | `assets/heroes/lusu/battle_idle.rejected_v1_too_tall_master_like.png` | 94 | No | The pose and identity were usable, but it was too tall and too close to Hero Master for a board idle sprite. | Re-generated as a compact board unit with short legs, large head, and props held close. | Rejected v1 |
| Lu Su | `assets/heroes/lusu/battle_idle.png` | 99 | Yes | Very compact and readable; props are close and the silhouette is ideal for board scaling. | Removed chroma-key to alpha. Calm support idle, no fan, readable text, glow, smoke, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Lu Su | `assets/heroes/lusu/battle_attack.png` | 98 | Yes | Tablet is extended forward, but bbox remains safe and the action reads as a basic command strike rather than skill casting. | Removed chroma-key to alpha. No projectile, glow, aura, readable text, smoke, UI, or background. | `battle_attack.source.v1.png` promoted to final |
| Lu Su | `assets/heroes/lusu/battle_skill.png` | 98 | Yes | Scroll extends slightly, but width is safe and the support-command pose is distinct from the attack frame. | Removed chroma-key to alpha. No flying scrolls, aura, glow, magic circle, readable text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Cheng Pu Plan

Cheng Pu action language draft:
- Body type: Wu epic elder warrior; lean, disciplined old commander, distinct from Huang Gai's bulky veteran tank, Zhou Tai's scarred bodyguard, Sun Jian's lordly founder, and Zhao Yun/Ma Chao/Jiang Wei spear heroes.
- Historical identity: Eastern Wu old guard general; grey sideburns, short moustache, stern command presence, deep teal/red Wu armor with aged bronze-gold trim.
- Weapon: `weapon_chengpu_wu_command_spear_master.png`; restrained Wu command spear, never guandao, halberd, axe, bow, sword, flag, or horse prop.
- FX separation: Cheng Pu may imply command through posture only; sprites must never contain glow, aura, smoke, dust, fire, lightning, particles, slash trails, banners, or text.
- Hero Master: elder command-spear presentation stance, facing right, spear visible but inside canvas.
- Battle Idle: compact low guard with spear close to the body.
- Battle Attack: short-range normal spear jab, no trail or skill effect.
- Battle Skill: veteran command/order pose with spear upright or close, character-only and no VFX.

## 2026-07-03 Cheng Pu Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Cheng Pu Weapon | `assets/weapons/weapon_chengpu_wu_command_spear_master.png` | 98 | Yes | Spear is ornate but clearly reads as a restrained command spear, not guandao, halberd, or axe. | Removed chroma-key to alpha. Weapon-only, no character, text, UI, FX, flag, or background. | `weapon_chengpu_wu_command_spear_master.source.v1.png` promoted to final |
| Cheng Pu | `assets/heroes/chengpu/hero_master.rejected_v1_tall_tight_spear.png` | 94 | No | Character was too tall/promotional and margins were tight for the established Q-style Hero Master set. | Re-generated with more compact proportions and safer weapon placement. | Rejected v1 |
| Cheng Pu | `assets/heroes/chengpu/hero_master.rejected_v2_top_tight.png` | 95 | No | Identity improved, but top margin and vertical footprint were still too tight. | Re-generated with stronger canvas padding and reduced spear reach. | Rejected v2 |
| Cheng Pu | `assets/heroes/chengpu/hero_master.rejected_v3_huanggai_like_edge_spear.png` | 94 | No | Silhouette drifted too close to Huang Gai's bulky old-veteran identity and spear placement was unsafe. | Re-generated with a leaner elder commander identity. | Rejected v3 |
| Cheng Pu | `assets/heroes/chengpu/hero_master.png` | 98 | Yes | Slightly tall, but identity is distinct: lean Wu elder command-spear general, not Huang Gai or Zhao Yun. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background. | `hero_master.source.v4.png` promoted to final |
| Cheng Pu | `assets/heroes/chengpu/battle_idle.rejected_v1_tall_spear.png` | 94 | No | Pose was too close to Hero Master and the spear/figure read too tall for a board sprite. | Re-generated as a compact low-guard board unit with spear close to body. | Rejected v1 |
| Cheng Pu | `assets/heroes/chengpu/battle_idle.png` | 98 | Yes | Sprite remains detailed, but the compact guard pose has safe margins and reads clearly after scaling. | Removed chroma-key to alpha. No glow, smoke, dust, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Cheng Pu | `assets/heroes/chengpu/battle_attack.rejected_v1_too_wide_spear.png` | 94 | No | Strong normal attack, but bbox width was 900px due to a long horizontal spear thrust, risking neighbor-cell overlap. | Re-generated as a close-range diagonal jab with the spear held near the torso. | Rejected v1 |
| Cheng Pu | `assets/heroes/chengpu/battle_attack.png` | 98 | Yes | Attack is controlled rather than dramatic, which keeps it safe for one-grid board use. | Removed chroma-key to alpha. Normal spear jab, no trail, glow, smoke, particles, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Cheng Pu | `assets/heroes/chengpu/battle_skill.png` | 98 | Yes | Spear makes the upper silhouette taller, but margins remain safe and the command gesture separates it from normal attack. | Removed chroma-key to alpha. Veteran order pose, no banner, aura, glow, smoke, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Sun Quan Plan

Sun Quan action language draft:
- Body type: Wu legendary ruler-warrior; young, composed, intelligent sovereign commander, distinct from Sun Jian's mature tiger-founder mass, Cao Cao's darker emperor-ruler silhouette, Zhou Yu/Lu Xun scholar-commanders, and Lu Su's diplomat support identity.
- Historical identity: Jiangdong successor and Eastern Wu lord; youthful face, tiny moustache, restrained royal headpiece, deep teal/crimson Wu armor-robes, jade authority seal.
- Weapon/prop: `weapon_sunquan_jiangdong_jade_command_sword_master.png`; compact Jiangdong jade command short sword with authority seal ornament, never giant dao, spear, guandao, fan, bow, or magic staff.
- FX separation: Sun Quan may imply sovereign command through hand pose, sword, and seal only; sprites must never contain glow, aura, magic circle, flying seal, banners, smoke, fire, lightning, particles, slash trails, or text.
- Hero Master: young sovereign command stance, facing right, compact short sword and jade seal visible.
- Battle Idle: compact ruler-command ready stance with sword and seal close.
- Battle Attack: close-body short sword draw-cut, no slash FX.
- Battle Skill: Jiangdong sovereign command order pose, character-only and no VFX.

## 2026-07-03 Sun Quan Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Sun Quan Weapon | `assets/weapons/weapon_sunquan_jiangdong_jade_command_sword_master.png` | 98 | Yes | The sheathed command sword is tall, but margins are safe and the jade authority seal clearly separates Sun Quan from generic sword users. | Removed chroma-key to alpha. Weapon/prop-only, no character, text, UI, glow, smoke, fire, lightning, particles, or background. | `weapon_sunquan_jiangdong_jade_command_sword_master.source.v1.png` promoted to final |
| Sun Quan | `assets/heroes/sunquan/hero_master.rejected_v1_tall_adult.png` | 92 | No | Identity direction was usable, but proportions were adult/promotional and failed the Art Bible 2.5-3-head Q-style requirement. | Re-generated with strict compact Q-version proportions and smaller ruler silhouette. | Rejected v1 |
| Sun Quan | `assets/heroes/sunquan/hero_master.rejected_v2_tall_portrait.png` | 95 | No | Transparent output was clean, but the body remained too tall and portrait-like compared with Zhao Yun/Guan Yu/Zhang Fei. | Re-generated on a square canvas with large head, short legs, and compact cloak. | Rejected v2 |
| Sun Quan | `assets/heroes/sunquan/hero_master.png` | 98 | Yes | Hair ribbon and cloak create width, but the square Q-style silhouette and jade seal identity are strong and distinct from Sun Jian. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background. | `hero_master.source.v3.png` promoted to final |
| Sun Quan | `assets/heroes/sunquan/battle_idle.png` | 98 | Yes | Slightly close to Hero Master, but compact enough for board scaling and clearly reads as ruler-command idle. | Removed chroma-key to alpha. No glow, smoke, fire, particles, text, UI, or background. | `battle_idle.source.v1.png` promoted to final |
| Sun Quan | `assets/heroes/sunquan/battle_attack.rejected_v1_too_wide_sword.png` | 94 | No | Sword and authority seal stretched the bbox to 915px width, risking neighbor-cell overlap. | Re-generated as a close-body diagonal draw-cut with sword and seal near the torso. | Rejected v1 |
| Sun Quan | `assets/heroes/sunquan/battle_attack.png` | 98 | Yes | Attack is contained rather than flashy, which supports one-grid board readability. | Removed chroma-key to alpha. Normal short-sword draw-cut, no slash trail, glow, smoke, particles, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Sun Quan | `assets/heroes/sunquan/battle_skill.rejected_v1_black_background.png` | 90 | No | Pose was appropriate, but source generated a black background instead of chroma-key green, making transparent extraction unsafe. | Re-generated with strict flat #00ff00 background constraints. | Rejected v1 |
| Sun Quan | `assets/heroes/sunquan/battle_skill.png` | 98 | Yes | Command hand and cloak widen the silhouette slightly, but bbox remains safe and the pose is distinct from normal attack. | Removed chroma-key to alpha. Sovereign order pose, no flying seal, aura, magic circle, banner, smoke, particles, text, UI, or background. | `battle_skill.source.v2.png` promoted to final |

## 2026-07-03 Da Qiao Plan

Da Qiao action language draft:
- Body type: Wu legendary guardian-support mage; elegant adult Q-style noblewoman, warmer and more protective than Xiao Qiao's youthful flower-moon fan identity, and less theatrical than Diaochan's dancer silhouette.
- Historical identity: Eastern Wu noble guardian; refined mature grace, deep teal/ivory robes, muted crimson sash, lotus and river-jade motifs, graceful high noble bun.
- Prop: `weapon_daqiao_jade_ruyi_lotus_master.png`; pale jade ruyi with lotus pendant and crimson tassel, never round fan, feather fan, sword, spear, bow, staff, or magic wand.
- FX separation: Da Qiao may imply protection through posture and ruyi only; sprites must never contain floating lotus petals, water splashes, glow, aura, magic circle, light beam, smoke, fire, lightning, particles, projectiles, or text.
- Hero Master: serene guardian-support presentation stance, facing right, jade ruyi and lotus pendant visible.
- Battle Idle: compact protective ready stance with ruyi close.
- Battle Attack: short close-body ruyi point-tap, no projectile or glow.
- Battle Skill: guardian blessing preparation pose, character-only and no VFX.

## 2026-07-03 Da Qiao Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Da Qiao Prop | `assets/weapons/weapon_daqiao_jade_ruyi_lotus_master.png` | 98 | Yes | The jade ruyi is tall as a prop master, but its identity is clear and it is distinct from Xiao Qiao's round fan. | Removed chroma-key to alpha. Prop-only, no character, text, UI, fan, glow, water, petals, smoke, fire, or background. | `weapon_daqiao_jade_ruyi_lotus_master.source.v1.png` promoted to final |
| Da Qiao | `assets/heroes/daqiao/hero_master.rejected_v1_tall_adult.png` | 94 | No | Elegant identity was correct, but proportions were too adult/promotional for the Art Bible Q-style set. | Re-generated as a square compact 2.5-3-head Hero Master with ruyi close to body. | Rejected v1 |
| Da Qiao | `assets/heroes/daqiao/hero_master.png` | 98 | Yes | Face remains warm and gentle, but the jade ruyi, teal/ivory palette, and guardian posture separate her from Xiao Qiao. | Removed chroma-key to alpha. Character-only Hero Master, no fan, FX, text, UI, or background. | `hero_master.source.v2.png` promoted to final |
| Da Qiao | `assets/heroes/daqiao/battle_idle.rejected_v1_gradient_wide_master_like.png` | 93 | No | Background was not flat chroma green, and the long hair/ruyi made the pose too wide and too close to Hero Master. | Re-generated with flat background, hair tucked close, and vertical ruyi held near the chest. | Rejected v1 |
| Da Qiao | `assets/heroes/daqiao/battle_idle.png` | 98 | Yes | Face is slightly cute, but the compact 517px bbox width is excellent for board scaling and the support identity is clear. | Removed chroma-key to alpha. No fan, glow, water splash, lotus petals, smoke, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Da Qiao | `assets/heroes/daqiao/battle_attack.rejected_v1_too_wide_ruyi.png` | 94 | No | Ruyi and sleeves extended too wide, risking neighbor-cell overlap and excessive downscaling. | Re-generated as a close-body ruyi point-tap with hair and sleeves tucked inward. | Rejected v1 |
| Da Qiao | `assets/heroes/daqiao/battle_attack.png` | 98 | Yes | Ruyi remains visible but bbox width is safe; action reads as a basic support strike, not a skill. | Removed chroma-key to alpha. No projectile, water, petals, glow, smoke, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Da Qiao | `assets/heroes/daqiao/battle_skill.png` | 98 | Yes | Robe silhouette is a little broad, but the guardian hand pose is distinct from attack and remains within safe margins. | Removed chroma-key to alpha. Guardian blessing prep, no aura, magic circle, water, lotus petals, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Sun Ce Plan

Sun Ce action language draft:
- Body type: Wu legendary assault warrior; young, bold, energetic Little Conqueror, distinct from Sun Jian's mature heavy tiger-founder, Sun Quan's composed sovereign command posture, and Lu Bu's demonic overwhelming silhouette.
- Historical identity: Jiangdong Little Conqueror; sharp eyebrows, confident grin, red headband, deep teal light assault armor, muted crimson short cloak, tiger-wave ornaments.
- Weapon: `weapon_sunce_jiangdong_short_ji_master.png`; compact Jiangdong short assault ji with one spear tip and one small side crescent blade, never Lu Bu-style huge Fangtian halberd, double crescent halberd, guandao, giant dao, sword, bow, or horse.
- FX separation: Sun Ce may imply charge pressure through stance and expression only; sprites must never contain speed lines, slash trails, spear trails, glow, aura, smoke, fire, lightning, particles, banners, flags, or text.
- Hero Master: young Little Conqueror presentation stance, facing right, short ji visible and contained.
- Battle Idle: compact low aggressive ready stance.
- Battle Attack: close-body upward ji strike, no trail.
- Battle Skill: charge-command pressure pose, character-only and no VFX.

## 2026-07-03 Sun Ce Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Sun Ce Weapon | `assets/weapons/weapon_sunce_jiangdong_short_ji_master.rejected_v1_lubu_like.png` | 93 | No | Weapon looked polished but the double-blade silhouette drifted too close to Lu Bu/Fangtian halberd language. | Re-generated with one spear tip and one small side crescent blade only. | Rejected v1 |
| Sun Ce Weapon | `assets/weapons/weapon_sunce_jiangdong_short_ji_master.png` | 98 | Yes | Still ornate, but single-side blade and compact scale separate it from Lu Bu's huge halberd. | Removed chroma-key to alpha. Weapon-only, no character, text, UI, glow, smoke, fire, lightning, particles, or background. | `weapon_sunce_jiangdong_short_ji_master.source.v2.png` promoted to final |
| Sun Ce | `assets/heroes/sunce/hero_master.rejected_v1_too_wide_cape_ji.png` | 94 | No | Strong Little Conqueror identity, but cape and ji stretched bbox to 1034px width, hurting HeroCard readability. | Re-generated with short cloak and ji held closer to the body. | Rejected v1 |
| Sun Ce | `assets/heroes/sunce/hero_master.png` | 98 | Yes | Weapon and hair remain energetic, but bbox is controlled and the identity is clearly distinct from Sun Jian/Sun Quan/Lu Bu. | Removed chroma-key to alpha. Character-only Hero Master, no FX/text/UI/background. | `hero_master.source.v2.png` promoted to final |
| Sun Ce | `assets/heroes/sunce/battle_idle.rejected_v1_tall_master_like.png` | 94 | No | Pose was too close to Hero Master and too large for board use. | Re-generated as a lower, more compact board sprite with the ji close to body. | Rejected v1 |
| Sun Ce | `assets/heroes/sunce/battle_idle.png` | 98 | Yes | The upright ji is visible but bbox remains safe and the low stance reads as aggressive idle. | Removed chroma-key to alpha. No glow, smoke, fire, particles, slash trail, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Sun Ce | `assets/heroes/sunce/battle_attack.rejected_v1_too_wide_horizontal_ji.png` | 92 | No | Strong action, but the horizontal ji was too wide and would risk neighbor-cell overlap. | Re-generated with strict close-body weapon placement. | Rejected v1 |
| Sun Ce | `assets/heroes/sunce/battle_attack.rejected_v2_too_idle_like.png` | 94 | No | Footprint was safe, but the action read too much like idle. | Re-generated with clearer forward pressure while keeping weapon contained. | Rejected v2 |
| Sun Ce | `assets/heroes/sunce/battle_attack.rejected_v3_clear_but_too_wide.png` | 94 | No | Action read clearly, but the forward thrust pushed the ji too far toward the edge. | Re-generated as a close-body upward strike. | Rejected v3 |
| Sun Ce | `assets/heroes/sunce/battle_attack.png` | 98 | Yes | Attack is compact rather than spectacular, which preserves board readability and still differs from idle. | Removed chroma-key to alpha. Normal close-body ji strike, no speed line, slash trail, glow, smoke, particles, text, UI, or background. | `battle_attack.source.v4.png` promoted to final |
| Sun Ce | `assets/heroes/sunce/battle_skill.rejected_v1_too_wide_command.png` | 94 | No | Command pose was good, but the ji and cape made the silhouette too wide. | Re-generated with ji vertical and command hand closer to body. | Rejected v1 |
| Sun Ce | `assets/heroes/sunce/battle_skill.png` | 98 | Yes | Upright ji makes the pose tall, but bbox and margins are safe; it reads as charge-command instead of attack. | Removed chroma-key to alpha. No aura, speed lines, banners, slash trails, smoke, particles, text, UI, or background. | `battle_skill.source.v2.png` promoted to final |

## 2026-07-03 Xu Sheng Plan

Xu Sheng action language draft:
- Body type: Wu epic tank; middle-aged fortress-defense commander, sturdy and disciplined, distinct from Zhou Tai's scarred bodyguard tank, Huang Gai's elderly brute veteran, and Cao Ren's heavier Wei fortress shield identity.
- Historical identity: Eastern Wu defensive officer; calm stern eyes, short dark beard, deep teal Wu lamellar armor, muted crimson short cloak, rattan weave and river-fortress motifs.
- Weapon/prop: `weapon_xusheng_fortress_rattan_shield_dao_master.png`; oval rattan shield plus short guard dao, never tower shield, western shield, huge saber, spear, bow, war whip, city wall, water, or arrow props.
- FX separation: Xu Sheng may imply defense through shield stance only; sprites must never contain shield glow, aura, city walls, water waves, arrows, banners, smoke, fire, lightning, particles, impact bursts, or text.
- Hero Master: shield-forward presentation stance, facing right, short dao secondary and contained.
- Battle Idle: compact shield guard with dao hidden.
- Battle Attack: shield bash/defensive counterattack, no impact FX.
- Battle Skill: fortress guard command preparation pose, character-only and no VFX.

## 2026-07-03 Xu Sheng Review

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Xu Sheng Prop | `assets/weapons/weapon_xusheng_fortress_rattan_shield_dao_master.png` | 98 | Yes | Prop master footprint is broad, but the shield/short-dao identity is clear and distinct from Zhou Tai/Huang Gai/Sun Jian. | Removed chroma-key to alpha. Prop-only, no character, text, UI, city wall, arrows, water, glow, smoke, fire, or background. | `weapon_xusheng_fortress_rattan_shield_dao_master.source.v1.png` promoted to final |
| Xu Sheng | `assets/heroes/xusheng/hero_master.rejected_v1_too_wide_sword_shield.png` | 94 | No | Strong defensive identity, but the short dao and shield stretched the bbox to 927px width, hurting HeroCard readability. | Re-generated with shield close and dao reduced to a secondary detail. | Rejected v1 |
| Xu Sheng | `assets/heroes/xusheng/hero_master.rejected_v2_sword_wide_too_old.png` | 94 | No | Shield improved, but sword still extended too far and the face drifted toward elderly veteran. | Re-generated as middle-aged shield-dominant commander with the dao mostly hidden. | Rejected v2 |
| Xu Sheng | `assets/heroes/xusheng/hero_master.rejected_v3_sword_still_wide_grey.png` | 94 | No | Sword still pulled the silhouette wide and grey hair pushed him toward Huang Gai/Cheng Pu old-guard territory. | Re-generated with shield as main visual and only a dao handle visible. | Rejected v3 |
| Xu Sheng | `assets/heroes/xusheng/hero_master.png` | 98 | Yes | Shield is large, but bbox is controlled and the middle-aged fortress-defense identity is distinct. | Removed chroma-key to alpha. Character-only Hero Master, no city wall, arrows, water, FX, text, UI, or background. | `hero_master.source.v4.png` promoted to final |
| Xu Sheng | `assets/heroes/xusheng/battle_idle.rejected_v1_master_like_sword_out.png` | 94 | No | Too close to Hero Master and the sword remained extended, not ideal for board footprint. | Re-generated as a compact shield-guard idle with dao hidden at belt. | Rejected v1 |
| Xu Sheng | `assets/heroes/xusheng/battle_idle.png` | 98 | Yes | Shield dominates, but bbox width is safe and the hidden dao keeps the board unit compact. | Removed chroma-key to alpha. No shield glow, city wall, arrows, smoke, text, UI, or background. | `battle_idle.source.v2.png` promoted to final |
| Xu Sheng | `assets/heroes/xusheng/battle_attack.rejected_v1_wide_saber.png` | 93 | No | The dao extended too wide and drifted toward Zhou Tai saber language. | Re-generated as a shield-bash attack with dao tucked behind shield. | Rejected v1 |
| Xu Sheng | `assets/heroes/xusheng/battle_attack.png` | 98 | Yes | Bbox width is broad at 850px, but it is safe for a shield-bash frame and all edges have margins. | Removed chroma-key to alpha. Defensive counterattack, no impact burst, shield glow, water, arrows, smoke, text, UI, or background. | `battle_attack.source.v2.png` promoted to final |
| Xu Sheng | `assets/heroes/xusheng/battle_skill.png` | 98 | Yes | Shield-forward command pose is broad but controlled; it reads as fortress guard prep and differs from attack. | Removed chroma-key to alpha. No aura, shield effect, city wall, arrows, banners, smoke, particles, text, UI, or background. | `battle_skill.source.v1.png` promoted to final |

## 2026-07-03 Qun Roster Completion Review

Scope: Yellow Turban Soldier is treated as a summon and is not counted as a completed Qun hero. This pass adds seven Qun heroes so the effective Qun hero roster reaches 13 and then stops: Yuan Shao, Yuan Shu, Jia Xu, Chen Gong, Gao Shun, Yan Liang, Wen Chou.

| Hero | Resource | Score | Final | Problems Found | Fix / Reason | Adopted Version |
|---|---|---:|---|---|---|---|
| Yuan Shao | `assets/heroes/yuanshao/hero_master.rejected_v1_tall_poster.png` | 86 | No | Noble identity was correct, but proportions were tall promotional art instead of 2.5-3-head Q-style. | Re-generated with compact Q proportions and larger head/hands. | Rejected v1 |
| Yuan Shao | `assets/heroes/yuanshao/hero_master.png` | 98 | Yes | Crown is tall, but Q body ratio, sword, decree, and northern aristocrat identity are clear. | Removed chroma-key to alpha. Character-only, no FX/text/UI/background. | `hero_master.source.v2.png` promoted to final |
| Yuan Shao | `assets/heroes/yuanshao/battle_idle.png` | 98 | Yes | Strong board-ready stance and clean right-facing silhouette. | Removed chroma-key to alpha. No FX, shadow, or background. | `battle_idle.source.v1.png` promoted to final |
| Yuan Shao | `assets/heroes/yuanshao/battle_attack.rejected_v1_edge_sword.png` | 96 | No | Sword tip sat too close to the canvas edge and risked crop/readability issues. | Re-generated with weapon fully inside canvas. | Rejected v1 |
| Yuan Shao | `assets/heroes/yuanshao/battle_attack.png` | 98 | Yes | Normal sword attack reads clearly without slash FX. | Removed chroma-key to alpha. | `battle_attack.source.v2.png` promoted to final |
| Yuan Shao | `assets/heroes/yuanshao/battle_skill.png` | 98 | Yes | Commanding skill pose is distinct from attack. | Removed chroma-key to alpha. No aura, soldiers, banners, smoke, or symbols. | `battle_skill.source.v1.png` promoted to final |
| Yuan Shu | `assets/heroes/yuanshu/hero_master.png` | 99 | Yes | Purple-gold seal identity separates him from Yuan Shao. | Removed chroma-key to alpha. Character-only, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Yuan Shu | `assets/heroes/yuanshu/battle_idle.png` | 98 | Yes | Smug guarded ruler stance remains compact for board use. | Removed chroma-key to alpha. | `battle_idle.source.v1.png` promoted to final |
| Yuan Shu | `assets/heroes/yuanshu/battle_attack.png` | 98 | Yes | Short-sword attack keeps jade seal close and avoids skill FX. | Removed chroma-key to alpha. | `battle_attack.source.v1.png` promoted to final |
| Yuan Shu | `assets/heroes/yuanshu/battle_skill.png` | 99 | Yes | Raised-seal command pose is readable without seal glow. | Removed chroma-key to alpha. No seal light, symbols, aura, or text. | `battle_skill.source.v1.png` promoted to final |
| Jia Xu | `assets/heroes/jiaxu/hero_master.png` | 99 | Yes | Black-purple scroll/fan identity is distinct from Sima Yi. | Removed chroma-key to alpha. Character-only, no poison cloud or FX. | `hero_master.source.v1.png` promoted to final |
| Jia Xu | `assets/heroes/jiaxu/battle_idle.png` | 98 | Yes | Calm dangerous idle is compact and readable. | Removed chroma-key to alpha. | `battle_idle.source.v1.png` promoted to final |
| Jia Xu | `assets/heroes/jiaxu/battle_attack.png` | 98 | Yes | Fan/scroll normal attack has no poison FX. | Removed chroma-key to alpha. | `battle_attack.source.v1.png` promoted to final |
| Jia Xu | `assets/heroes/jiaxu/battle_skill.png` | 99 | Yes | Open-scroll scheme pose separates skill from attack. | Removed chroma-key to alpha. No poison, symbols, or glow. | `battle_skill.source.v1.png` promoted to final |
| Chen Gong | `assets/heroes/chengong/hero_master.rejected_v1_tall_poster.png` | 91 | No | Temperament was correct, but body ratio was too tall for Art Bible Q-style. | Re-generated with compact 2.5-3-head proportions. | Rejected v1 |
| Chen Gong | `assets/heroes/chengong/hero_master.png` | 98 | Yes | Blue-gray loyal strategist identity is clear. | Removed chroma-key to alpha. Character-only, no FX/text/UI/background. | `hero_master.source.v2.png` promoted to final |
| Chen Gong | `assets/heroes/chengong/battle_idle.png` | 98 | Yes | Composed tactical idle remains board-safe. | Removed chroma-key to alpha. | `battle_idle.source.v1.png` promoted to final |
| Chen Gong | `assets/heroes/chengong/battle_attack.png` | 98 | Yes | Restrained scholar-sword attack is clear and contained. | Removed chroma-key to alpha. No slash trail. | `battle_attack.source.v1.png` promoted to final |
| Chen Gong | `assets/heroes/chengong/battle_skill.png` | 98 | Yes | Jade-tablet command pose is usable, though sword energy is stronger than ideal. | Removed chroma-key to alpha. No magic FX. | `battle_skill.source.v1.png` promoted to final |
| Gao Shun | `assets/heroes/gaoshun/hero_master.png` | 99 | Yes | Tower shield and black-iron armor strongly express Camp Crushers tank identity. | Removed chroma-key to alpha. Character-only, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Gao Shun | `assets/heroes/gaoshun/battle_idle.png` | 98 | Yes | Shield-wall stance is readable; weapon is slightly long but acceptable. | Removed chroma-key to alpha. | `battle_idle.source.v1.png` promoted to final |
| Gao Shun | `assets/heroes/gaoshun/battle_attack.png` | 98 | Yes | Shield-and-ji attack is grounded and FX-free. | Removed chroma-key to alpha. | `battle_attack.source.v1.png` promoted to final |
| Gao Shun | `assets/heroes/gaoshun/battle_skill.png` | 98 | Yes | Raised-shield defensive order reads distinctly from attack. | Removed chroma-key to alpha. No shockwave or dust. | `battle_skill.source.v1.png` promoted to final |
| Yan Liang | `assets/heroes/yanliang/hero_master.png` | 99 | Yes | Red-bronze armor and straight-backed dao distinguish him from Guan Yu/Hua Xiong. | Removed chroma-key to alpha. Character-only, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Yan Liang | `assets/heroes/yanliang/battle_idle.png` | 98 | Yes | Dao is broad but not guandao; idle is readable. | Removed chroma-key to alpha. | `battle_idle.source.v1.png` promoted to final |
| Yan Liang | `assets/heroes/yanliang/battle_attack.rejected_v1_yuanshao_crown.png` | 95 | No | Attack pose was good, but tall headwear drifted too close to Yuan Shao. | Re-generated with warrior headband/low helm. | Rejected v1 |
| Yan Liang | `assets/heroes/yanliang/battle_attack.png` | 99 | Yes | No tall crown; grounded dao attack reads as vanguard warrior. | Removed chroma-key to alpha. No slash trail. | `battle_attack.source.v2.png` promoted to final |
| Yan Liang | `assets/heroes/yanliang/battle_skill.png` | 99 | Yes | Dao wind-up pose is strong and distinct from attack. | Removed chroma-key to alpha. No wind, dust, or FX. | `battle_skill.source.v1.png` promoted to final |
| Wen Chou | `assets/heroes/wenchou/hero_master.png` | 98 | Yes | Dark teal wolf-shoulder identity differs from Yan Liang; weapon is ornate but acceptable. | Removed chroma-key to alpha. Character-only, no FX/text/UI/background. | `hero_master.source.v1.png` promoted to final |
| Wen Chou | `assets/heroes/wenchou/battle_idle.rejected_v1_lubu_weapon.png` | 94 | No | Weapon read too much like a symmetrical Fangtian Ji, risking Lu Bu overlap. | Re-generated as single-sided hook-sickle spear. | Rejected v1 |
| Wen Chou | `assets/heroes/wenchou/battle_idle.png` | 98 | Yes | Weapon remains decorative but no longer reads as Fangtian Ji. | Removed chroma-key to alpha. | `battle_idle.source.v2.png` promoted to final |
| Wen Chou | `assets/heroes/wenchou/battle_attack.rejected_v1_lubu_plume.png` | 92 | No | Red plume and weapon silhouette drifted too close to Lu Bu. | Re-generated with low helm/headband and no plumes. | Rejected v1 |
| Wen Chou | `assets/heroes/wenchou/battle_attack.png` | 98 | Yes | Agile hook-spear attack is distinct enough after removing Lu Bu-like plumes. | Removed chroma-key to alpha. No slash trail. | `battle_attack.source.v2.png` promoted to final |
| Wen Chou | `assets/heroes/wenchou/battle_skill.png` | 98 | Yes | Side-flank wind-up pose is readable; weapon should later be tightened by a dedicated weapon master. | Removed chroma-key to alpha. No wind blade, afterimage, smoke, or FX. | `battle_skill.source.v1.png` promoted to final |

