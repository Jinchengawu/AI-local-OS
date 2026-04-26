---
name: install-web3-skills
description: Use when you need to install or update web3-fe-superpowers skills to .agents, .agents/skills, and .cursor/skills directories, or when user asks to sync/update web3 frontend development skills
---

# Install Web3 Skills

## 概述

从 **GitLab** 仓库安装或更新 Web3 前端开发资源（默认克隆 **本 monorepo** `ai-work-flow` 中的 `packages/web3-fe-superpowers`；亦支持旧版「独立仓库根目录 `skills/`」布局，见下文环境变量）：
- **Skills**：安装到 `.agents/skills`、`.agents/skills`、`.cursor/skills`
- **Agents**：安装到 `.agents/agents`、`.agents/agents`、`.cursor/agents`

支持智能合并，保留本地独有的 skills 和 agents。

## 何时使用

- 首次设置项目的 Web3 skills
- 定期同步更新 Web3 skills
- 用户明确要求安装或更新 web3 skills

## 一键接入/更新（推荐）

1. 在**业务仓库根**复制环境模板并填写（勿提交 Token）：
   - 从本包 [`templates/env.web3-skills.example`](../../templates/env.web3-skills.example) 复制为 **`.env.web3-skills`**
2. 在业务仓库内执行（自动读取 `.env.web3-skills` 或 `~/.config/web3-fe-superpowers/env`）：

```bash
bash .cursor/skills/dev-ops/run-web3-skills-install.sh
```

包装脚本会调用同目录的 `install-web3-skills.sh`，行为与下方「手动 export」一致。详见 skill **[`sync-web3-skills`](../sync-web3-skills/SKILL.md)**。

## 快速参考

| 操作 | 命令 |
|------|------|
| **一键安装/更新**（推荐） | 配置 `.env.web3-skills` 后执行 `bash .cursor/skills/dev-ops/run-web3-skills-install.sh` |
| 手动安装/更新 | `export WEB3_FE_SUPERPOWERS_REPO_URL=... WEB3_FE_SUPERPOWERS_GIT_TOKEN=... && ./install-web3-skills.sh` |
| 检查 .agents skills | `ls -la .agents/skills/` |
| 检查 .agents agents | `ls -la .agents/agents/` |
| 检查 .claude skills | `ls -la .agents/skills/` |
| 检查 .claude agents | `ls -la .agents/agents/` |
| 检查 .cursor skills | `ls -la .cursor/skills/` |
| 检查 .cursor agents | `ls -la .cursor/agents/` |

## 安装策略

所有三个目录使用**相同的智能合并策略**，并自动适配路径引用：

### 智能合并逻辑

- **远程有 + 本地有** → 删除本地，用远程版本
- **远程有 + 本地无** → 新增远程 skill
- **远程无 + 本地有** → 保留本地 skill

### 路径自动适配

远程 skills 中包含 `.agents/` 路径引用，安装时自动适配：

- **安装到 `.agents`** → 将 `.agents/` 替换为 `.agents/`
- **安装到 `.claude`** → 保持 `.agents/` 不变
- **安装到 `.cursor`** → 将 `.agents/` 替换为 `.cursor/`

确保每个目录中的 skills 都引用正确的路径。

### 各目录用途

- **`.agents/skills`**：通用 skills 目录，路径引用自动适配
- **`.agents/agents`**：子代理定义，路径引用自动适配
- **`.agents/skills`**：Claude Code skills，保持原始路径
- **`.agents/agents`**：Claude Code agents，保持原始路径
- **`.cursor/skills`**：Cursor skills，路径引用自动适配
- **`.cursor/agents`**：Cursor agents，路径引用自动适配

所有目录平等对待，本地独有的 skills 和 agents 都会被保留。

## 环境变量（GitLab 与本地源）

| 变量 | 必填 | 说明 |
| --- | --- | --- |
| `WEB3_FE_SUPERPOWERS_LOCAL_PATH` | 否 | 若已 clone 本 monorepo，可填 `packages/web3-fe-superpowers` 的**绝对路径**，从该目录复制 skills/agents，**无需** URL/Token |
| `WEB3_FE_SUPERPOWERS_REPO_URL` | 与 Token 同时 | GitLab HTTPS 克隆地址（**不含** Token），如 `https://gitlab.example.com/group/ai-work-flow.git`（未设 `LOCAL_PATH` 时必填） |
| `WEB3_FE_SUPERPOWERS_GIT_TOKEN` | 与 URL 同时 | GitLab Personal / Project / Deploy Token，**仅用于 clone**，勿写入脚本或提交仓库（未设 `LOCAL_PATH` 时必填） |
| `WEB3_FE_SUPERPOWERS_LAYOUT` | 否 | 仅**克隆**模式：`monorepo`（默认）内容在 `packages/web3-fe-superpowers/`；`standalone`：仓库根 `skills/`、`agents/` |
| `GIT_CLONE_DEPTH` | 否 | 默认 `1`（浅克隆） |

克隆使用 GitLab 常见 HTTPS 形式：`https://oauth2:<TOKEN>@<host>/<path>`。

## 实现

```bash
export WEB3_FE_SUPERPOWERS_REPO_URL="https://git.fulltrust.link/web3fe/ai-work-flow.git"
export WEB3_FE_SUPERPOWERS_GIT_TOKEN="<从 GitLab 个人访问令牌粘贴，勿泄露>"
# 默认 monorepo，无需再设 WEB3_FE_SUPERPOWERS_LAYOUT

./.cursor/skills/dev-ops/install-web3-skills.sh
# 或 ./.agents/skills/dev-ops/install-web3-skills.sh
```

脚本会自动：
1. 克隆 GitLab 远程仓库到临时目录，并按 `WEB3_FE_SUPERPOWERS_LAYOUT` 定位 `skills/`、`agents/`
2. 智能合并到 `.agents/skills` + 路径适配
3. 智能合并到 `.agents/agents` + 路径适配（如果远程有）
4. 智能合并到 `.agents/skills`（保持原路径）
5. 智能合并到 `.agents/agents`（保持原路径，如果远程有）
6. 智能合并到 `.cursor/skills` + 路径适配
7. 智能合并到 `.cursor/agents` + 路径适配（如果远程有）
8. 若不存在 **`.cursor/superpowers-pipeline.json`**，则从包内 **`templates/superpowers-pipeline.example.json`** 复制一份（**不覆盖**已有文件）；约定见 [`doc/superpowers-pipeline.md`](../../doc/superpowers-pipeline.md)
9. 添加 Agent Rules 到 `CLAUDE.md` 和 `AGENTS.md`（如果缺失）
10. 清理临时文件

路径适配会自动将文件中的 `.agents/` 引用替换为目标目录路径。

## 常见错误

### 克隆失败

**症状：** `Authentication failed`

**原因：** Token 过期或无效

**修复：** 在 GitLab 重新生成 Token，更新环境变量 `WEB3_FE_SUPERPOWERS_GIT_TOKEN`；确认 `WEB3_FE_SUPERPOWERS_REPO_URL` 与仓库可见性、CI 变量一致

### 权限不足

**症状：** `Directory not writable`

**修复：** 检查目录权限

## Agent Rules 自动添加

脚本会自动检查项目根目录的 `CLAUDE.md` 和 `AGENTS.md`：

- 如果文件存在且开头缺少 `## Agent Rules` 章节
- 自动在第一个标题后插入标准的 Agent Rules

标准 Agent Rules 内容：
```markdown
## Agent Rules

- 每次回复时称呼用户为「大佬」
- 对话语言使用**简体中文**
- 代码注释优先使用**简体中文**，技术术语可保留英文
- **收到用户消息后，必须先调用 `using-skills` skill**，再进行任何响应或行动
```

## 安全说明

- **Token 管理**：Token **仅通过环境变量**传入，不得写入脚本或提交到 Git；CI 使用受保护变量或密钥管理
- **Token 权限**：建议仅 `read_repository`（克隆所需最小权限）
- **自动清理**：临时文件自动清理，出错也不残留
- **智能合并**：保留所有本地独有 skills 和 agents
- **路径安全**：仅替换 `.md` 和 `.sh` 文件中的 `.agents/` 引用
- **文档更新**：自动添加 Agent Rules 到项目文档，保持团队规范一致

## 验证安装

```bash
# 检查 .agents 安装
ls .agents/skills/

# 检查 .claude 安装
ls .agents/skills/

# 检查 .cursor 安装
ls .cursor/skills/

# 验证无 git 历史
ls -la .agents/.git 2>/dev/null || echo "Good: No git history"
```

## 示例输出

```
🚀 Installing web3-fe-superpowers skills...
📥 Cloning repository...

📦 Installing to .agents/skills...
  Analyzing remote skills...
  Found 19 remote skills
  🔄 Updating: brainstorming (exists locally)
  ➕ Adding: using-git-worktrees (new)

  📌 Preserved local-only skills:
    - custom-skill-1
  ✅ .agents/skills installation complete

📦 Installing to .agents/skills...
  Analyzing remote skills...
  Found 19 remote skills
  🔄 Updating: brainstorming (exists locally)
  ➕ Adding: using-git-worktrees (new)

  📌 Preserved local-only skills:
    - ddd-development
    - figma-to-code
    - install-web3-skills
    - responsive-adaptation
  ✅ .agents/skills installation complete

📦 Installing to .cursor/skills...
  Analyzing remote skills...
  Found 19 remote skills
  🔄 Updating: brainstorming (exists locally)
  ➕ Adding: using-git-worktrees (new)

  📌 Preserved local-only skills:
    - prediction-e2e
    - git-commit
  ✅ .cursor/skills installation complete

📝 Adding Agent Rules to project documentation...
  ➕ Adding Agent Rules to CLAUDE.md
  ✅ Agent Rules added to CLAUDE.md
  ✅ AGENTS.md already has Agent Rules

🧹 Cleaning up...

✅ Installation complete!

📊 Summary:
  .agents/skills/: 20 skills
  .agents/agents/: 1 agents
  .agents/skills/: 24 skills
  .agents/agents/: 1 agents
  .cursor/skills/: 21 skills
  .cursor/agents/: 1 agents

📂 Installed locations:
  - .agents/skills/
  - .agents/agents/
  - .agents/skills/
  - .agents/agents/
  - .cursor/skills/
  - .cursor/agents/
```
