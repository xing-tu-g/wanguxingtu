const fs = require('fs');
process.env.NODE_PATH = 'C:\\Users\\23503\\AppData\\Roaming\\QClaw\\npm-global\\node_modules';
require('module').Module._initPaths();

const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, 
        HeadingLevel, AlignmentType, WidthType, ShadingType } = require('docx');

const DARK_BG = "1A1A2E";
const RED = "FF0000";
const FONT = "微软雅黑";

// Helper: create text runs with proper formatting
function makeTextRuns(text, opts = {}) {
    if (!text) text = '';
    
    // Check for placeholders {{...}}
    if (text.includes('{{') && text.includes('}}')) {
        const regex = /({{[^}]+}})/g;
        const parts = text.split(regex);
        const runs = [];
        for (let i = 0; i < parts.length; i++) {
            const part = parts[i];
            if (part && part.match(/^{{[^}]+}}$/)) {
                runs.push(new TextRun({
                    text: part,
                    font: FONT,
                    color: RED,
                    bold: true,
                    size: opts.size || 20
                }));
            } else if (part) {
                runs.push(new TextRun({
                    text: part,
                    font: FONT,
                    size: opts.size || 20,
                    bold: opts.bold || false,
                    italics: opts.italics || false,
                    color: opts.color || undefined
                }));
            }
        }
        return runs;
    }
    
    return [new TextRun({
        text: text,
        font: FONT,
        size: opts.size || 20,
        bold: opts.bold || false,
        italics: opts.italics || false,
        color: opts.color || undefined
    })];
}

// Helper: create paragraph
function makePara(text, opts = {}) {
    const children = Array.isArray(text) ? text : makeTextRuns(text, opts);
    return new Paragraph({
        children: children,
        heading: opts.h || undefined,
        alignment: opts.align || AlignmentType.LEFT,
        spacing: { before: opts.before || 0, after: opts.after || 100 },
        pageBreakBefore: opts.pb || false
    });
}

// Helper: dark header cell
function darkCell(text) {
    return new TableCell({
        children: [new Paragraph({
            children: [new TextRun({ text: text, font: FONT, bold: true, color: "FFFFFF", size: 20 })],
            alignment: AlignmentType.CENTER
        })],
        shading: { type: ShadingType.CLEAR, fill: DARK_BG },
        width: { size: 100, type: WidthType.PERCENTAGE }
    });
}

// Helper: data cell
function dataCell(text) {
    return new TableCell({
        children: [new Paragraph({ children: makeTextRuns(text) })],
        width: { size: 25, type: WidthType.PERCENTAGE }
    });
}

// Helper: create table
function makeTable(headers, rows) {
    const headerRow = new TableRow({ children: headers.map(h => darkCell(h)) });
    const dataRows = rows.map(row => {
        return new TableRow({ children: row.map(cell => dataCell(cell)) });
    });
    return new Table({
        rows: [headerRow, ...dataRows],
        width: { size: 100, type: WidthType.PERCENTAGE }
    });
}

const children = [];

// ========== CHAPTER 1 ==========
children.push(makePara("第一章：项目概述", { h: HeadingLevel.HEADING_1, pb: true, before: 400, after: 200 }));

children.push(makePara("1.1 核心乐趣假设", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("在华夏文明的星图上，用三国名将的魂棋进行一场自动战棋对决——选将、布阵、看他们在随机地形上自动厮杀，赢了就是你把一颗陨落的将星拉回了文明。", { after: 200 }));

children.push(makePara("1.2 设计支柱", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("1. 星图设定——所有玩法围绕星图魂星天缺展开，不做换皮三国", { after: 100 }));
children.push(makePara("2. 易学不易精——8-15分钟上手，但阵容搭配和地形利用需要长期钻研", { after: 100 }));
children.push(makePara("3. 每局新棋局——随机地形和随机策略卡让每局截然不同，拒绝背板", { after: 100 }));
children.push(makePara("4. 降肝降氪——每日首胜加前十局收益最大，后续递减，不靠在线时长绑架玩家", { after: 100 }));
children.push(makePara("5. 真实概率——抽卡概率透明公示，保底机制清晰", { after: 200 }));

children.push(makePara("1.3 产品定位", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("休闲 + 轻策略 + 爽感", { bold: true, after: 100 }));
children.push(makePara("- 休闲：8-15 分钟一局，异步回合制", { after: 100 }));
children.push(makePara("- 轻策略：武将搭配、地形利用、策略卡选择", { after: 100 }));
children.push(makePara("- 爽感：自动战斗演出、技能爆发、弈天师生命见底的胜利反馈、每个页面的Q版美术", { after: 200 }));

children.push(makePara("1.4 核心循环", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("获得武将 → 编辑卡组 → 对战 → 结算领奖。武将升级 ← 抽卡 ← 资源获取。天梯排位。", { after: 200 }));

children.push(makePara("1.5 反痛点设计", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("- 降肝降氪", { after: 100 }));
children.push(makePara("- 控制武将升级增加的数值与技能提示效果", { after: 100 }));
children.push(makePara("- 每日首胜加前十局收益最大，后续递减", { after: 200 }));

children.push(makePara("1.6 凭什么可能火", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("1. 地形随机刷新——每局地图不同，拒绝背板", { after: 100 }));
children.push(makePara("2. 每个武将设计有特色——技能差异化，无凑数卡", { after: 100 }));
children.push(makePara("3. 抽卡纯随机——真实概率公示", { after: 100 }));
children.push(makePara("4. 收益递减保护——轻肝友好，不劝退休闲玩家", { after: 200 }));

// ========== CHAPTER 2 ==========
children.push(makePara("第二章：世界观", { h: HeadingLevel.HEADING_1, pb: true, before: 400, after: 200 }));

children.push(makePara("2.1 万古星图", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("在时间诞生之前，天地间悬浮着一幅名为「万古星图」的棋盘。它不记年月，不辨朝代。大禹治水的凿痕、韩信暗度陈仓的马蹄、李白醉后的孤篇、哪吒闹海的混天绫——所有曾在华夏文明中绽放过光芒的存在，都在星图上化作一枚魂星。千万年来，四百余颗魂星彼此辉映，织成文明的经纬。", { after: 200 }));

children.push(makePara("2.2 天缺", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("建兴十二年秋，五丈原。诸葛亮禳星那夜，七星灯不是被魏延踢翻的——是裂痕。一道看不见的裂痕撕裂了星图，七星灯应声而碎。不止诸葛亮的星落了。短短数十年间，关羽、张飞、周瑜、典韦、郭嘉——那些本不该早逝的人——他们的魂星没有像往常那样回到星图循环，而是被裂痕吞噬，散落在时空的裂缝中。这便是「天缺」。", { after: 200 }));

children.push(makePara("2.3 弈天师", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("裂痕出现的同一年，世间开始有人觉醒一种能力：感知星图中的魂星，将其凝结为「命魂棋」，在虚空中落子为战。这些人被称作弈天师。继承诸葛亮未竟事业的弈天师，从三国开始觉醒。每获得一枚命魂棋，就是将一位传奇从遗忘的边缘拉回；每在棋盘上赢得一场战斗，星图上的裂痕就愈合一线。", { after: 200 }));

children.push(makePara("2.4 三国是起点", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("裂痕虽然贯穿万古——它吞噬的远远不止三国。春秋的魂星、楚汉的将魂、神话时代的神格，全在裂缝中。但没有人能感知到三国之前和之后的缺失。因为裂痕抹去的不是记忆，而是它们曾经存在的事实本身。只有三国。因为裂痕正是在这一代人眼前撕开的。这一代人亲眼看见关羽之星陨落、看见诸葛亮禳星失败、看见三国归晋时四百将星一夜俱寂。所以弈天师最初只能感知三国时代的魂星——那是裂痕的起点，是星图最脆弱的伤口，也是唯一还能被观测到的地方。", { after: 200 }));

// ========== CHAPTER 3 ==========
children.push(makePara("第三章：对战系统", { h: HeadingLevel.HEADING_1, pb: true, before: 400, after: 200 }));

children.push(makePara("3.1 通用规则", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("- 横屏需适配安卓各类手机屏幕", { after: 100 }));
children.push(makePara("- 棋盘：10 列 × 5 行（玩家部署区 1–3 列，敌方部署区 8–10 列，中场 4–7 列）", { after: 100 }));
children.push(makePara("- 双方各一名弈天师，初始 30 生命值", { after: 100 }));
children.push(makePara("- 弈天师为纯血量目标，所有职业对其伤害一致", { after: 100 }));
children.push(makePara("- 先将对方弈天师生命值打至 0 者胜", { after: 200 }));

children.push(makePara("3.2 回合流程", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("1. 先后手抽取——先手初始 5 星力，后手初始 6 星力", { after: 100 }));
children.push(makePara("2. 先手方回合：放置武将（消耗星力）→ 武将自动移动 → 武将自动攻击 → 回合结束", { after: 100 }));
children.push(makePara("3. 后手方回合：放置武将（消耗星力）→ 武将自动移动 → 武将自动攻击 → 回合结束", { after: 100 }));
children.push(makePara("4. 循环，直到一方弈天师生命值归零", { after: 200 }));
children.push(makePara("- 星力是弈天师召唤武将与发动战术的战场能量", { after: 100 }));
children.push(makePara("- 基础每回合恢复 2 点星力（上限 10）", { after: 100 }));
children.push(makePara("- 每 3 个回合进入一次「星潮」：后续每回合星力恢复量加 1，并额外抽取 1 张策略卡", { after: 100 }));
children.push(makePara("- 星潮会强化压迫：第 8/12/16... 回合起，单位对弈天师伤害分别 +1/+2/+3...，只影响攻击弈天师，不影响武将对打", { after: 100 }));
children.push(makePara("- 无回合上限，打到弈天师生命归零为止", { after: 100 }));
children.push(makePara("- 三阶段推进：己方半场 → 中场 → 敌方弈天师", { after: 100 }));
children.push(makePara("- 弈天师无固有减伤，所有单位攻击力全量作用于弈天师", { after: 200 }));

children.push(makePara("3.3 部署规则", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("- 玩家可在己方半场任意空格部署武将", { after: 100 }));
children.push(makePara("- 星力等于武将召唤消耗值", { after: 200 }));

children.push(makePara("3.4 战斗内查看", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("- 对战中点击棋盘单位可打开详情浮层，不打断战斗流程", { after: 100 }));
children.push(makePara("- 详情展示：武将名、品质、职业、当前生命值、攻击力、射程、移动、物理格挡/法术格挡、伤害类型、技能说明、等级、当前异常状态与增益状态", { after: 100 }));
children.push(makePara("- 展示数据必须来自当前战斗实例，包含等级、光环、地形、策略卡等实时修正后的结果", { after: 100 }));
children.push(makePara("- 召唤物也要能查看，至少展示来源、基础属性、行动逻辑和是否可被技能影响", { after: 200 }));

// ========== CHAPTER 4 ==========
children.push(makePara("第四章：职业体系", { h: HeadingLevel.HEADING_1, pb: true, before: 400, after: 200 }));

children.push(makePara("4.1 职业特性", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("表格（6行，4列：职业 | 攻击距离 | 移动速度 | 特性）：", { color: "888888", size: 18, after: 100 }));
children.push(makeTable(
    ["职业", "攻击距离", "移动速度", "特性"],
    [
        ["射手", "远（圆圈范围）", "中", "破甲、高伤、群伤"],
        ["坦克", "近", "慢", "身板硬、攻击低、保护队友"],
        ["武卫", "略长", "中", "稳步推进、克制战士"],
        ["战士", "近", "快", "攻击略高、冲锋"],
        ["法师", "长", "慢", "法术伤害"],
        ["刺客", "中", "快", "无视敌方阻挡、属性平庸、干扰奇袭"]
    ]
));
children.push(makePara("", { after: 200 }));

children.push(makePara("4.2 属性标准模型", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("以下数值为指导范围，供武将设计时参考。实际属性根据武将稀有度（传说/史诗/精英/普通）、技能特性、上场消耗星力进行动态调整。", { after: 100 }));
children.push(makePara("表格（6行，8列：职业 | 攻击距离 | 攻击力类型 | 血量 | 移动 | 物理格挡 | 法术格挡 | 伤害类型）：", { color: "888888", size: 18, after: 100 }));
children.push(makeTable(
    ["职业", "攻击距离", "攻击力类型", "血量", "移动", "物理格挡", "法术格挡", "伤害类型"],
    [
        ["射手", "3–6（圆形）", "物理攻击力 3–7", "2–5", "1–3", "0", "0", "物理"],
        ["坦克", "1", "物理攻击力 1–3", "4–10", "1–3", "1–3", "0", "物理"],
        ["武卫", "2", "物理攻击力 2–4", "3–7", "2–3", "0", "0", "物理"],
        ["战士", "1", "物理攻击力 3–6", "4–8", "3–5", "0", "0", "物理"],
        ["法师", "3–5", "法术攻击力 3–6", "4–8", "1–3", "0", "0", "法术"],
        ["刺客", "1", "物理攻击力 1–4", "4–8", "3–6", "0", "0", "物理"]
    ]
));
children.push(makePara("", { after: 200 }));

children.push(makePara("设计说明", { bold: true, before: 200, after: 100 }));
children.push(makePara("- 攻击距离——射手和法师为范围攻击（圆形），其余为直线或单体", { after: 100 }));
children.push(makePara("- 攻击力类型——面板必须写清物理攻击力或法术攻击力；法师普通攻击默认为法术攻击力，其余职业默认为物理攻击力", { after: 100 }));
children.push(makePara("- 格挡——分为物理格挡与法术格挡：物理格挡只减免物理伤害，法术格挡只减免法术伤害；真实伤害无视两类格挡。当前坦克主要拥有物理格挡，法师普通攻击默认为法术伤害", { after: 100 }));
children.push(makePara("- 移动——每回合可前进的格子数，受地形影响（泥沼减 1，河流可通行但会削弱攻防）", { after: 100 }));
children.push(makePara("- 血量——坦克显著高于其他职业，射手最脆", { after: 200 }));

children.push(makePara("平衡锚点", { bold: true, before: 200, after: 100 }));
children.push(makePara("- 属性越高 → 星力消耗越高 / 品质越低 → 属性取区间下限", { after: 100 }));
children.push(makePara("- 技能强的武将属性应适度压低", { after: 100 }));
children.push(makePara("- 同一传说武将的属性通常取区间中上", { after: 100 }));
children.push(makePara("所有数值标 {{占位符}}。", { after: 200 }));

// ========== CHAPTER 5 ==========
children.push(makePara("第五章：策略博弈因素", { h: HeadingLevel.HEADING_1, pb: true, before: 400, after: 200 }));

children.push(makePara("5.1 武将技能体系", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("表格（8行，3列：体系 | 代表武将 | 效果）：", { color: "888888", size: 18, after: 100 }));
children.push(makeTable(
    ["体系", "代表武将", "效果"],
    [
        ["召唤人海", "张角", "部署时召唤黄巾兵×3"],
        ["火烧蔓延", "周瑜、陆逊", "灼烧目标，灼烧可传染，对灼烧目标伤害翻倍"],
        ["养大哥", "关羽", "每回合 +1 攻击力 +3 生命值，成长型核心"],
        ["亡灵战术", "董卓", "死亡单位 50% 概率变骷髅兵（低属性自动战斗）"],
        ["光环增益", "姜维", "全军 +1 攻击力"],
        ["控制离间", "貂蝉", "部署时离间敌方一单位为我方战斗"],
        ["抽牌增益", "郭嘉", "部署时额外抽一张策略卡"],
        ["群体治疗", "荀彧、甄姬、糜夫人", "全军/范围恢复生命值"]
    ]
));
children.push(makePara("", { after: 200 }));

children.push(makePara("5.2 地形系统", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("每局随机生成 5 个特殊地形（双方半场各 1 个，中场 3 个，其余为草地）。", { after: 100 }));
children.push(makePara("表格（4行，2列：地形 | 效果）：", { color: "888888", size: 18, after: 100 }));
children.push(makeTable(
    ["地形", "效果"],
    [
        ["草地（默认）", "无效果"],
        ["泥沼", "非刺客/战士多耗 1 移动力"],
        ["河流", "可通行/可部署；站在河流上攻击力减 1，被攻击时受到伤害加 1，攻击弈天师伤害减 1"],
        ["高地", "射手/法师加 1 射程"]
    ]
));
children.push(makePara("", { after: 200 }));

children.push(makePara("5.3 全局策略卡", { h: HeadingLevel.HEADING_2, before: 300, after: 100 }));
children.push(makePara("星潮时额外抽取 1 张，可选择使用。", { after: 100 }));
children.push(makePara("表格（6行，2列：策略卡 | 效果）：", { color: "888888", size: 18, after: 100 }));
children.push(makeTable(
    ["策略卡", "效果"],
    [
        ["火矢", "所有射手 +2 攻击力"],
        ["鼓舞", "所有武将本回合 +2 攻击力"],
        ["落石", "敌方半场随机 3 格各 5 伤害"],
        ["补给", "弈天师回复 25 生命值"],
        ["急行军", "全军本回合移动 +1"],
        ["地震", "双方弈天师减 30 生命值"]
    ]
));

// Continue with more chapters...
console.log("Progress: wrote chapters 1-5");
console.log("Children count:", children.length);

// Save what we have so far to test
const doc1 = new Document({ sections: [{ children: children }] });
Packer.toBuffer(doc1).then(buf => {
    fs.writeFileSync('D:\\wanguxingtu\\test_output.docx', buf);
    console.log('Test document created: D:\\wanguxingtu\\test_output.docx');
}).catch(err => {
    console.error('Error:', err.message);
});
