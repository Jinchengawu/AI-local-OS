# Codex 工具映射

Skill 使用 Claude Code 工具名称。当你在 skill 中遇到这些名称时，使用你平台的等价物：

| Skill 引用                      | Codex 等价物                 |
| ------------------------------- | ---------------------------- |
| `Task` 工具（派遣子代理）       | `spawn_agent`                |
| 多次 `Task` 调用（并行）        | 多次 `spawn_agent` 调用      |
| Task 返回结果                   | `wait`                       |
| Task 自动完成                   | `close_agent` 释放槽位       |
| `TodoWrite`（任务追踪）         | `update_plan`                |
| `Skill` 工具（调用 skill）      | Skill 原生加载——直接遵循指令 |
| `Read`、`Write`、`Edit`（文件） | 使用你的原生文件工具         |
| `Bash`（运行命令）              | 使用你的原生 shell 工具      |

## 子代理派遣需要多代理支持

在你的 Codex 配置（`~/.codex/config.toml`）中添加：

```toml
[features]
multi_agent = true
```

这将启用 `spawn_agent`、`wait` 和 `close_agent`，用于 `dispatching-parallel-agents` 和 `subagent-driven-development` 等 skill。
