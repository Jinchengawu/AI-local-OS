# Gemini CLI 工具映射

Skill 使用 Claude Code 工具名称。当你在 skill 中遇到这些名称时，使用你平台的等价物：

| Skill 引用                 | Gemini CLI 等价物                 |
| -------------------------- | --------------------------------- |
| `Read`（读取文件）         | `read_file`                       |
| `Write`（创建文件）        | `write_file`                      |
| `Edit`（编辑文件）         | `replace`                         |
| `Bash`（运行命令）         | `run_shell_command`               |
| `Grep`（搜索文件内容）     | `grep_search`                     |
| `Glob`（按名称搜索文件）   | `glob`                            |
| `TodoWrite`（任务追踪）    | `write_todos`                     |
| `Skill` 工具（调用 skill） | `activate_skill`                  |
| `WebSearch`                | `google_web_search`               |
| `WebFetch`                 | `web_fetch`                       |
| `Task` 工具（派遣子代理）  | 无等价物——Gemini CLI 不支持子代理 |

## 无子代理支持

Gemini CLI 没有 Claude Code `Task` 工具的等价物。依赖子代理派遣的 skill（`subagent-driven-development`、`dispatching-parallel-agents`）将回退到通过 `executing-plans` 进行单会话执行。

## 额外的 Gemini CLI 工具

这些工具在 Gemini CLI 中可用但没有 Claude Code 等价物：

| 工具                                 | 用途                                       |
| ------------------------------------ | ------------------------------------------ |
| `list_directory`                     | 列出文件和子目录                           |
| `save_memory`                        | 跨会话持久化事实到 GEMINI.md               |
| `ask_user`                           | 向用户请求结构化输入                       |
| `tracker_create_task`                | 丰富的任务管理（创建、更新、列表、可视化） |
| `enter_plan_mode` / `exit_plan_mode` | 在修改之前切换到只读研究模式               |
