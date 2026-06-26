const fs = require('fs');
const path = require('path');

// Set NODE_PATH for module resolution
process.env.NODE_PATH = 'C:\\Users\\23503\\AppData\\Roaming\\QClaw\\npm-global\\node_modules';
require('module').Module._initPaths();

const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, 
        HeadingLevel, AlignmentType, WidthType, BorderStyle, ShadingType,
        PageBreak, convertInchesToTwip } = require('docx');

// Color constants
const DARK_HEADER_BG = "1A1A2E";
const RED_COLOR = "FF0000";
const GRAY_COLOR = "888888";

// Font name
const FONT_NAME = "微软雅黑";

// Helper: create text run with formatting
function createTextRun(text, options = {}) {
    const isPlaceholder = text.includes('{{') && text.includes('}}');
    
    if (isPlaceholder) {
        // Split text to handle placeholders
        const parts = text.split/({{.*?}})/;
        const runs = [];
        for (const part of parts) {
            if (part.match(/{{.*?}}/)) {
                runs.push(new TextRun({
                    text: part,
                    font: FONT_NAME,
                    color: RED_COLOR,
                    bold: true,
                    size: options.size || 20,
                }));
            } else if (part) {
                runs.push(new TextRun({
                    text: part,
                    font: FONT_NAME,
                    size: options.size || 20,
                    bold: options.bold || false,
                    italics: options.italics || false,
                    color: options.color || undefined,
                }));
            }
        }
        return runs;
    }
    
    return [new TextRun({
        text: text,
        font: FONT_NAME,
        size: options.size || 20,
        bold: options.bold || false,
        italics: options.italics || false,
        color: options.color || undefined,
    })];
}

// Helper: create paragraph
function createParagraph(text, options = {}) {
    const runs = Array.isArray(text) ? text : createTextRun(text, options);
    
    return new Paragraph({
        children: runs,
        heading: options.heading || undefined,
        alignment: options.alignment || AlignmentType.LEFT,
        spacing: {
            before: options.before || 0,
            after: options.after || 100,
        },
        pageBreakBefore: options.pageBreak || false,
    });
}

// Helper: create dark header cell
function createDarkHeaderCell(text) {
    return new TableCell({
        children: [new Paragraph({
            children: [new TextRun({
                text: text,
                font: FONT_NAME,
                bold: true,
                color: "FFFFFF",
                size: 20,
            })],
            alignment: AlignmentType.CENTER,
        })],
        shading: {
            type: ShadingType.CLEAR,
            fill: DARK_HEADER_BG,
        },
        width: { size: 100 / 4, type: WidthType.PERCENTAGE },
    });
}

// Helper: create regular table cell
function createTableCell(text, options = {}) {
    const isPlaceholder = typeof text === 'string' && text.includes('{{') && text.includes('}}');
    
    let children;
    if (isPlaceholder) {
        children = [new Paragraph({
            children: createTextRun(text),
        })];
    } else {
        children = [new Paragraph({
            children: [new TextRun({
                text: text || '',
                font: FONT_NAME,
                size: options.size || 20,
            })],
        })];
    }
    
    return new TableCell({
        children: children,
        width: { size: options.width || 25, type: WidthType.PERCENTAGE },
    });
}

// Helper: create table from data
function createTable(headers, rows, options = {}) {
    const tableRows = [];
    
    // Header row
    const headerCells = headers.map(h => createDarkHeaderCell(h));
    tableRows.push(new TableRow({
        children: headerCells,
    }));
    
    // Data rows
    for (const row of rows) {
        const cells = row.map((cell, idx) => {
            return createTableCell(cell, { width: options.colWidths ? options.colWidths[idx] : 25 });
        });
        tableRows.push(new TableRow({
            children: cells,
        }));
    }
    
    return new Table({
        rows: tableRows,
        width: { size: 100, type: WidthType.PERCENTAGE },
    });
}

// Build document sections
const sections = [];

// ========== CHAPTER 1 ==========
const chapter1 = [];

// Page break before chapter
chapter1.push(createParagraph("第一章：项目概述", { heading: HeadingLevel.HEADING_1, pageBreak: true, before: 400, after: 200 }));

chapter1.push(createParagraph("1.1 核心乐趣假设", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter1.push(createParagraph("在华夏文明的星图上，用三国名将的魂棋进行一场自动战棋对决——选将、布阵、看他们在随机地形上自动厮杀，赢了就是你把一颗陨落的将星拉回了文明。", { after: 200 }));

chapter1.push(createParagraph("1.2 设计支柱", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter1.push(createParagraph("1. 星图设定——所有玩法围绕"星图""魂星""天缺"展开，不做换皮三国", { after: 100 }));
chapter1.push(createParagraph("2. 易学不易精——8-15分钟上手，但阵容搭配和地形利用需要长期钻研", { after: 100 }));
chapter1.push(createParagraph("3. 每局新棋局——随机地形和随机策略卡让每局截然不同，拒绝背板", { after: 100 }));
chapter1.push(createParagraph("4. 降肝降氪——每日首胜加前十局收益最大，后续递减，不靠在线时长绑架玩家", { after: 100 }));
chapter1.push(createParagraph("5. 真实概率——抽卡概率透明公示，保底机制清晰", { after: 200 }));

chapter1.push(createParagraph("1.3 产品定位", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter1.push(createParagraph("休闲 + 轻策略 + 爽感", { bold: true, after: 100 }));
chapter1.push(createParagraph("- 休闲：8-15 分钟一局，异步回合制", { after: 100 }));
chapter1.push(createParagraph("- 轻策略：武将搭配、地形利用、策略卡选择", { after: 100 }));
chapter1.push(createParagraph("- 爽感：自动战斗演出、技能爆发、弈天师生命见底的胜利反馈、每个页面的Q版美术", { after: 200 }));

chapter1.push(createParagraph("1.4 核心循环", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter1.push(createParagraph("获得武将 → 编辑卡组 → 对战 → 结算领奖。武将升级 ← 抽卡 ← 资源获取。天梯排位。", { after: 200 }));

chapter1.push(createParagraph("1.5 反痛点设计", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter1.push(createParagraph("- 降肝降氪", { after: 100 }));
chapter1.push(createParagraph("- 控制武将升级增加的数值与技能提示效果", { after: 100 }));
chapter1.push(createParagraph("- 每日首胜加前十局收益最大，后续递减", { after: 200 }));

chapter1.push(createParagraph("1.6 凭什么可能火", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter1.push(createParagraph("1. 地形随机刷新——每局地图不同，拒绝背板", { after: 100 }));
chapter1.push(createParagraph("2. 每个武将设计有特色——技能差异化，无凑数卡", { after: 100 }));
chapter1.push(createParagraph("3. 抽卡纯随机——真实概率公示", { after: 100 }));
chapter1.push(createParagraph("4. 收益递减保护——轻肝友好，不劝退休闲玩家", { after: 200 }));

sections.push(...chapter1);

// ========== CHAPTER 2 ==========
const chapter2 = [];
chapter2.push(createParagraph("第二章：世界观", { heading: HeadingLevel.HEADING_1, pageBreak: true, before: 400, after: 200 }));

chapter2.push(createParagraph("2.1 万古星图", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter2.push(createParagraph("在时间诞生之前，天地间悬浮着一幅名为「万古星图」的棋盘。它不记年月，不辨朝代。大禹治水的凿痕、韩信暗度陈仓的马蹄、李白醉后的孤篇、哪吒闹海的混天绫——所有曾在华夏文明中绽放过光芒的存在，都在星图上化作一枚魂星。千万年来，四百余颗魂星彼此辉映，织成文明的经纬。", { after: 200 }));

chapter2.push(createParagraph("2.2 天缺", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter2.push(createParagraph("建兴十二年秋，五丈原。诸葛亮禳星那夜，七星灯不是被魏延踢翻的——是裂痕。一道看不见的裂痕撕裂了星图，七星灯应声而碎。不止诸葛亮的星落了。短短数十年间，关羽、张飞、周瑜、典韦、郭嘉——那些本不该早逝的人——他们的魂星没有像往常那样回到星图循环，而是被裂痕吞噬，散落在时空的裂缝中。这便是「天缺」。", { after: 200 }));

chapter2.push(createParagraph("2.3 弈天师", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter2.push(createParagraph("裂痕出现的同一年，世间开始有人觉醒一种能力：感知星图中的魂星，将其凝结为「命魂棋」，在虚空中落子为战。这些人被称作弈天师。继承诸葛亮未竟事业的弈天师，从三国开始觉醒。每获得一枚命魂棋，就是将一位传奇从遗忘的边缘拉回；每在棋盘上赢得一场战斗，星图上的裂痕就愈合一线。", { after: 200 }));

chapter2.push(createParagraph("2.4 三国是起点", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter2.push(createParagraph("裂痕虽然贯穿万古——它吞噬的远远不止三国。春秋的魂星、楚汉将魂、神话时代的神格，全在裂缝中。但没有人能感知到三国之前和之后的缺失。因为裂痕抹去的不是记忆，而是"它们曾经存在"的事实本身。只有三国。因为裂痕正是在这一代人眼前撕开的。这一代人亲眼看见关羽之星陨落、看见诸葛亮禳星失败、看见三国归晋时四百将星一夜俱寂。所以弈天师最初只能感知三国时代的魂星——那是裂痕的起点，是星图最脆弱的伤口，也是唯一还能被观测到的地方。", { after: 200 }));

sections.push(...chapter2);

// ========== CHAPTER 3 ==========
const chapter3 = [];
chapter3.push(createParagraph("第三章：对战系统", { heading: HeadingLevel.HEADING_1, pageBreak: true, before: 400, after: 200 }));

chapter3.push(createParagraph("3.1 通用规则", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter3.push(createParagraph("- 横屏需适配安卓各类手机屏幕", { after: 100 }));
chapter3.push(createParagraph("- 棋盘：10 列 × 5 行（玩家部署区 1–3 列，敌方部署区 8–10 列，中场 4–7 列）", { after: 100 }));
chapter3.push(createParagraph("- 双方各一名弈天师，初始 30 生命值", { after: 100 }));
chapter3.push(createParagraph("- 弈天师为纯血量目标，所有职业对其伤害一致", { after: 100 }));
chapter3.push(createParagraph("- 先将对方弈天师生命值打至 0 者胜", { after: 200 }));

chapter3.push(createParagraph("3.2 回合流程", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter3.push(createParagraph("1. 先后手抽取——先手初始 5 星力，后手初始 6 星力", { after: 100 }));
chapter3.push(createParagraph("2. 先手方回合：放置武将（消耗星力）→ 武将自动移动 → 武将自动攻击 → 回合结束", { after: 100 }));
chapter3.push(createParagraph("3. 后手方回合：放置武将（消耗星力）→ 武将自动移动 → 武将自动攻击 → 回合结束", { after: 100 }));
chapter3.push(createParagraph("4. 循环，直到一方弈天师生命值归零", { after: 200 }));

chapter3.push(createParagraph("- 星力是弈天师召唤武将与发动战术的战场能量", { after: 100 }));
chapter3.push(createParagraph("- 基础每回合恢复 2 点星力（上限 10）", { after: 100 }));
chapter3.push(createParagraph("- 每 3 个回合进入一次「星潮」：后续每回合星力恢复量加 1，并额外抽取 1 张策略卡", { after: 100 }));
chapter3.push(createParagraph("- 星潮会强化压迫：第 8/12/16... 回合起，单位对弈天师伤害分别 +1/+2/+3...，只影响攻击弈天师，不影响武将对打", { after: 100 }));
chapter3.push(createParagraph("- 无回合上限，打到弈天师生命归零为止", { after: 100 }));
chapter3.push(createParagraph("- 三阶段推进：己方半场 → 中场 → 敌方弈天师", { after: 100 }));
chapter3.push(createParagraph("- 弈天师无固有减伤，所有单位攻击力全量作用于弈天师", { after: 200 }));

chapter3.push(createParagraph("3.3 部署规则", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter3.push(createParagraph("- 玩家可在己方半场任意空格部署武将", { after: 100 }));
chapter3.push(createParagraph("- 星力等于武将召唤消耗值", { after: 200 }));

chapter3.push(createParagraph("3.4 战斗内查看", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter3.push(createParagraph("- 对战中点击棋盘单位可打开详情浮层，不打断战斗流程", { after: 100 }));
chapter3.push(createParagraph("- 详情展示：武将名、品质、职业、当前生命值、攻击力、射程、移动、物理格挡/法术格挡、伤害类型、技能说明、等级、当前异常状态与增益状态", { after: 100 }));
chapter3.push(createParagraph("- 展示数据必须来自当前战斗实例，包含等级、光环、地形、策略卡等实时修正后的结果", { after: 100 }));
chapter3.push(createParagraph("- 召唤物也要能查看，至少展示来源、基础属性、行动逻辑和是否可被技能影响", { after: 200 }));

sections.push(...chapter3);

// ========== CHAPTER 4 ==========
const chapter4 = [];
chapter4.push(createParagraph("第四章：职业体系", { heading: HeadingLevel.HEADING_1, pageBreak: true, before: 400, after: 200 }));

chapter4.push(createParagraph("4.1 职业特性", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter4.push(createParagraph("表格（6行，4列：职业 | 攻击距离 | 移动速度 | 特性）：", { after: 100, color: GRAY_COLOR, size: 18 }));

const table4_1 = createTable(
    ["职业", "攻击距离", "移动速度", "特性"],
    [
        ["射手", "远（圆圈范围）", "中", "破甲、高伤、群伤"],
        ["坦克", "近", "慢", "身板硬、攻击低、保护队友"],
        ["武卫", "略长", "中", "稳步推进、克制战士"],
        ["战士", "近", "快", "攻击略高、冲锋"],
        ["法师", "长", "慢", "法术伤害"],
        ["刺客", "中", "快", "无视敌方阻挡、属性平庸、干扰奇袭"],
    ]
);
sections.push(...chapter4);
sections.push(table4_1);
sections.push(createParagraph("", { after: 200 }));

// 4.2
const chapter4_2 = [];
chapter4_2.push(createParagraph("4.2 属性标准模型", { heading: HeadingLevel.HEADING_2, before: 300, after: 100 }));
chapter4_2.push(createParagraph("以下数值为指导范围，供武将设计时参考。实际属性根据武将稀有度（传说/史诗/精英/普通）、技能特性、上场消耗星力进行动态调整。", { after: 100 }));
chapter4_2.push(createParagraph("表格（6行，8列：职业 | 攻击距离 | 攻击力类型 | 血量 | 移动 | 物理格挡 | 法术格挡 | 伤害类型）：", { after: 100, color: GRAY_COLOR, size: 18 }));

sections.push(...chapter4_2);

const table4_2 = createTable(
    ["职业", "攻击距离", "攻击力类型", "血量", "移动", "物理格挡", "法术格挡", "伤害类型"],
    [
        ["射手", "3–6（圆形）", "物理攻击力 3–7", "2–5", "1–3", "0", "0", "物理"],
        ["坦克", "1", "物理攻击力 1–3", "4–10", "1–3", "1–3", "0", "物理"],
        ["武卫", "2", "物理攻击力 2–4", "3–7", "2–3", "0", "0", "物理"],
        ["战士", "1", "物理攻击力 3–6", "4–8", "3–5", "0", "0", "物理"],
        ["法师", "3–5", "法术攻击力 3–6", "4–8", "1–3", "0", "0", "法术"],
        ["刺客", "1", "物理攻击力 1–4", "4–8", "3–6", "0", "0", "物理"],
    ]
);
sections.push(table4_2);
sections.push(createParagraph("", { after: 200 }));

// Design notes
const chapter4_3 = [];
chapter4_3.push(createParagraph("### 设计说明", { bold: true, before: 200, after: 100 }));
chapter4_3.push(createParagraph("- 攻击距离——射手和法师为范围攻击（圆形），其余为直线或单体", { after: 100 }));
chapter4_3.push(createParagraph("- 攻击力类型——面板必须写清物理攻击力或法术攻击力；法师普通攻击默认为法术攻击力，其余职业默认为物理攻击力", { after: 100 }));
chapter4_3.push(createParagraph("- 格挡——分为物理格挡与法术格挡：物理格挡只减免物理伤害，法术格挡只减免法术伤害；真实伤害无视两类格挡。当前坦克主要拥有物理格挡，法师普通攻击默认为法术伤害", { after: 100 }));
chapter4_3.push(createParagraph("- 移动——每回合可前进的格子数，受地形影响（泥沼减 1，河流可通行但会削弱攻防）", { after: 100 }));
chapter4_3.push(createParagraph("- 血量——坦克显著高于其他职业，射手最脆", { after: 200 }));

chapter4_3.push(createParagraph("### 平衡锚点", { bold: true, before: 200, after: 100 }));
chapter4_3.push(createParagraph("- 属性越高 → 星力消耗越高 / 品质越低 → 属性取区间下限", { after: 100 }));
chapter4_3.push(createParagraph("- 技能强的武将属性应适度压低", { after: 100 }));
chapter4_3.push(createParagraph("- 同一传说武将的属性通常取区间中上", { after: 100 }));
chapter4_3.push(createParagraph("", { after: 100 }));  // empty line for placeholder
chapter4_3.push(createParagraph("所有数值标 {{占位符}}。", { after: 200 }));

sections.push(...chapter4_3);

// Write script to file (part 1 complete)
fs.writeFileSync('D:\\wanguxingtu\\script_part1.js', '// Part 1 complete\n');
console.log('Part 1 written successfully');
