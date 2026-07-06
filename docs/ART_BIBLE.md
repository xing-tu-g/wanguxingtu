

* * *

星图对弈（Wanguxingtu）Art Bible v1.0

> **项目代号：Wanguxingtu**
> 
> Version：1.0
> 
> Author：ChatGPT & Xuan
> 
> Last Update：2026

* * *

第一章 项目定位
========

游戏定位
----

星图对弈是一款：

* 中国风

* Q版

* 自动战斗

* 战棋

* 收集养成

* PVP

手游。

游戏采用：

> **轻策略 + 高品质美术 + 英雄收集**

作为核心体验。

* * *

美术关键词
-----

整个项目统一遵循：
    商业手游品质

    Q版

    2.5~3头身

    国风

    明亮

    高级

    干净

    层次丰富

    英雄辨识度极高

    绝不写实

    绝不幼稚

    绝不欧美魔幻

* * *

第二章 世界观
=======

第一赛季：
    三国

后续赛季：
    西游

    封神

    楚汉

    隋唐

    水浒

    神话

    其他历史朝代

所以：

整个项目：

**世界观不能写死三国。**

未来所有英雄：

统一来自：

> 星图世界。

* * *

第三章 Hero设计规范
============

每个英雄固定：
    Hero Master

    ↓

    Battle Idle

    ↓

    Battle Attack

    ↓

    Battle Skill

共：

**四张资源。**

禁止增加：

Hero2

Hero3

等等。

* * *

Hero Master
-----------

用途：
    HeroCard

    Hero Detail

    图鉴

    Loading

    宣传

要求：
    透明背景

    PNG

    完整人物

    动态站姿

    面朝右

    无文字

    无背景

    无UI

* * *

Battle Idle
-----------

用途：

棋盘。

要求：
    Ready Pose

    稳稳站立

    保持压迫感

    透明背景

    无特效

    Godot直接显示

* * *

Battle Attack
-------------

用途：

普通攻击。

要求：
    普通攻击动作

    不要技能动作

    不要光效

    不要烟雾

    不要火焰

* * *

Battle Skill
------------

用途：

技能。

要求：
    技能蓄力动作

    不要普通攻击动作

    不要技能特效

    所有技能特效独立

* * *

第四章 HeroCard规范
==============

HeroCard：

统一：
    Hero Master

绝不使用：

Battle图片。

HeroCard：

不是：

详情页。

也不是：

宣传图。

* * *

显示内容：
    头像

    名字

    费用

    生命

    攻击

其它：

长按详情。

* * *

第五章 Battle规范
============

Battle：

全部：

使用：

Battle资源。

Hero：

统一：
    朝右

Enemy：

统一：
    flip_h

禁止：

生成左右两个版本。

* * *

Battle图片：

统一：
    透明背景

    PNG

    无特效

    无背景

    无地面

    无阴影

* * *

第六章 动作语言
========

每个英雄：

必须拥有：

独立动作语言。

绝不能：

模板化。

* * *

赵云：
    关键词：

    快

    灵

    突刺

    冲阵

    龙胆枪

Idle：

身体前倾。

Attack：

高速突刺。

Skill：

腾空冲阵。

* * *

关羽：
    关键词：

    稳

    重

    威

    武圣

Idle：

持刀稳立。

Attack：

重斩。

Skill：

举刀蓄力。

* * *

张飞：
    关键词：

    猛

    狂

    横扫

    怒吼

Idle：

站如山。

Attack：

横扫。

Skill：

高举丈八蛇矛怒吼。

* * *

以后：

所有英雄：

全部：

建立：

自己的动作语言。

* * *

第七章 武器规范
========

所有武器：

建立：

Master。

例如：
    weapon_longdan_master

    weapon_qinglong_master

    weapon_zhangba_master

    weapon_hutou_master

    weapon_longbow_master

禁止：

AI：

自由发挥。

* * *

例如：

张飞：

必须：

使用：

丈八蛇矛。

标准：
    双叉枪头

    左右对称

    蛇形波浪刃

    整体细长

    不是关刀

    不是戟

    不是斧

    不是奇幻武器

* * *

赵云：
    龙胆亮银枪

    直枪

    细长

    银白

* * *

关羽：
    青龙偃月刀

    厚重

    龙纹

    刀身修长

* * *

第八章 人物与特效分离
===========

人物：

永远：

不带：
    刀光

    枪芒

    烟雾

    火焰

    雷电

    碎石

    地裂

    技能圈

这些：

全部：

独立：

FX。

例如：
    fx_slash

    fx_hit

    fx_dash

    fx_fire

    fx_ground

    fx_lightning

Godot：

组合。

* * *

第九章 武将体型规范
==========

统一：
    2.5~3头身

但是：

体型：

不同。

赵云：
    修长

    轻盈

关羽：
    高大

    厚重

张飞：
    最壮

    最宽

    最低重心

以后：

所有英雄：

建立：

Body Type。

* * *

第十章 资源目录
========

    assets/
    
    heroes/
    
    zhaoyun/
    
    hero_master.png
    
    battle_idle.png
    
    battle_attack.png
    
    battle_skill.png
    
    guanyu/
    
    zhangfei/
    
    weapons/
    
    weapon_longdan_master.png
    
    weapon_qinglong_master.png
    
    weapon_zhangba_master.png
    
    fx/
    
    slash/
    
    hit/
    
    dash/
    
    fire/
    
    ground/
    
    ui/
    
    icons/
    
    cards/
    
    battle/
    
    backgrounds/

* * *

第十一章 命名规范
=========

Hero：
    hero_zhaoyun_master.png

Battle：
    battle_zhaoyun_idle.png

    battle_zhaoyun_attack.png

    battle_zhaoyun_skill.png

Weapon：
    weapon_zhangba_master.png

FX：
    fx_slash_red_01.png

    fx_hit_small.png

    fx_fire_arc.png

* * *

第十二章 AI 出图流程（Pipeline）
======================

所有英雄统一执行：
    ① Hero Master

    ↓

    ② 接入Godot

    ↓

    ③ 检查HeroCard

    ↓

    ④ Battle Idle

    ↓

    ⑤ 接入Godot

    ↓

    ⑥ Battle Attack

    ↓

    ⑦ 接入Godot

    ↓

    ⑧ Battle Skill

    ↓

    ⑨ 接入Godot

    ↓

    ⑩ 整体检查

    ↓

    进入下一位英雄

**任何一个环节不通过，不进入下一张。**

* * *

第十三章 美术设计原则（Design Principles）
==============================

整个项目始终坚持以下原则：

1. **先规范，后产量**：先把标准定好，再批量生成资源。

2. **武器先于人物**：先确定武器母版，再制作英雄，确保历史辨识度。

3. **动作体现性格**：英雄的差异主要来自动作语言，而不是配色。

4. **人物与特效解耦**：人物资源保持纯净，特效由 Godot 动态组合。

5. **一个资源，多处复用**：Hero Master 用于 HeroCard、详情、图鉴；Battle 资源专注于战斗。

6. **所有资源最终服务于游戏**：任何图片都必须经过 Godot 实际验证，而不是只看单张效果。

* * *


--------------
