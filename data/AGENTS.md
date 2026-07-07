# data 目录规则

- `res://data/*.json` 是数值与内容的权威来源。
- 核心数值不要随意改，改动前先对照 `docs/02_values_and_content.md` 和 `docs/04_battle_details_data_tests.md`。
- 数据文件只存配置和内容，不放脚本逻辑。
- 任何数据调整都要考虑对战斗规则、测试断言和 manifest 同步的影响。
