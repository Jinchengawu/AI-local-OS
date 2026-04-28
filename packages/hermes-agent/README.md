# @ai-local-os/hermes-agent

**Hermes Agent**（Nous Research）的**官方主分发**为安装脚本 + Python 运行时，**不是**像 OpenClaw 一样以单一 `npm install hermes-agent` 作为核心交付。本包在 **Node/pnpm 工作区**中的职责是：

- 用 **Node 脚本** 调用官方安装入口（`curl … | bash`），便于与 `@ai-local-os/openclaw` 同一套 `pnpm` 命令管理；
- 提供 `doctor` 检查本机是否已有 `hermes` 命令。

## 使用

```bash
pnpm install
pnpm hermes:bootstrap
pnpm hermes:doctor
```

## 官方参考

- 文档：<https://hermes-agent.nousresearch.com/>
- 安装（官方）：`curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`
- 源码：<https://github.com/NousResearch/hermes-agent>

## 与 AI-local-OS 方案 A 的关系

多实例 Hermes 的端口与注册表仍见仓库根 [docs/ai-local-os/hermes-instances.template.yaml](../../docs/ai-local-os/hermes-instances.template.yaml)；本包不负责替代 Hermes 自带配置目录（通常为 `~/.hermes`）。
