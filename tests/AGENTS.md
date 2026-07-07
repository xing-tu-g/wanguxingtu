# tests 目录规则

- `tests/` 负责测试覆盖与 manifest 同步，不得降低现有覆盖。
- `check_test_manifest.ps1` 和 `run_mvp_manifest_tests.ps1` 相关断言是稳定约束，新增或删除测试前先确认 manifest 影响。
- 任何行为变更都要补测试或更新断言，不能只改实现不改测试。
- 测试数量、测试命名和 manifest 状态必须保持一致。
