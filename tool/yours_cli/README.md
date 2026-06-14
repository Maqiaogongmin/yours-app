# yours-cli

`yours-cli` 是给 Agent 使用的本地优先命令行入口。它负责把结构化训练计划、动作库和 Yours Vault 数据安全写入有思本地 SQLite 数据库。

## Examples

```bash
yours-cli --db /path/to/local_training.sqlite --exercise-db /path/to/custom_exercises.sqlite doctor
yours-cli --json exercise list
yours-cli --json exercise import exercise.exercise.json --dry-run
yours-cli --json plan list
yours-cli --json plan validate plan.json
yours-cli --json plan import plan.json --replace
yours-cli --json vault export --out /path/to/YoursVault
yours-cli --json vault inspect /path/to/YoursVault
yours-cli --json vault import-inbox /path/to/YoursVault --dry-run
```

环境变量：`YOURS_LOCAL_DB` / `YOURS_EXERCISE_DB`。
