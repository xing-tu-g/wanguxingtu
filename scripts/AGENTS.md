# scripts 目录规则

- 这里以 GDScript 为主，数据读取优先走 `res://data/*.json`，不要把数值硬编码进脚本。
- 涉及 `BattleManager` 时只做规则保护和必要接线，不要随意改战斗规则、核心数值或流程。
- 表现层脚本可以调整交互和展示，但不能借机改动战斗逻辑。
- 新增脚本尽量放入 `scripts/battle/`、`scripts/data/`、`scripts/ui/` 等清晰子目录。
- 代码命名要清晰，避免单字母变量名。
