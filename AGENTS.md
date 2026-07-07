# 万古星图 / 星图对弈 全局规则

## 项目定位

- 本项目使用 Godot 4.x + GDScript 开发横屏 2D 自动战棋《万古星图 / 星图对弈》。
- 当前只做 MVP 核心战斗闭环，不做完整商业系统。
- 当前基线以 `docs/CURRENT.md` 为准；续接时先读 `docs/CURRENT.md`，再读 `docs/HANDOFF.md` 末尾 80-140 行。
- 禁止整本读取 `docs/HANDOFF.md`。

## 权威入口

- `docs/README.md`
- `docs/01_rules_spec.md`
- `docs/02_values_and_content.md`
- `docs/03_godot_mvp_plan.md`
- `docs/04_battle_details_data_tests.md`

## 必须遵守

- 不得随意修改 `BattleManager` 的战斗规则、核心数值、首页、战斗 UI。
- 当前 manifest 必须保持 100 项同步。
- `icon_settings_default.png` 和 `icon_settings_hover.png` 继续保持 `needs_art_fix`，不要擅自改成正式可用态。
- 阶段完成前，必须运行 `scripts/check_test_manifest.ps1` 和 `scripts/run_mvp_manifest_tests.ps1`。
- 阶段完成后，必须更新 `docs/HANDOFF.md`。

## 分层规则

- 目录级约束拆分到各自子目录的 `AGENTS.md`。
- 子目录规则只补充本目录相关约束，不替代本文件。
